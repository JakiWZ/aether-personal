package io.github.jakiwz.aether.inventory;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.assertj.MockMvcTester;
import org.springframework.test.web.servlet.assertj.MvcTestResult;
import org.springframework.transaction.annotation.Transactional;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.postgresql.PostgreSQLContainer;

/**
 * ORI-401 end to end on the demo dataset: a valid resource is persisted and audited, duplicate codes
 * and unknown units are rejected, a deactivated resource keeps its stock and stays listed.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("demo")
@WithMockUser(username = "log.marino", authorities = {"INVENTORY_READ", "INVENTORY_MANAGE"})
@Testcontainers
@Transactional // every write is rolled back
class ResourceCatalogIT {

    @Container
    @ServiceConnection
    static final PostgreSQLContainer POSTGRES = new PostgreSQLContainer("postgres:16-alpine");

    private static final String SCRUBBER = """
            {"code":"co2_scrubber","name":" CO2 scrubber cartridge ","category":"LIFE_SUPPORT","unitCode":"pcs",
             "critical":true,"shelfLifeDays":null}""";

    @Autowired
    MockMvcTester mvc;

    @Autowired
    JdbcTemplate jdbc;

    @Test
    void listsTheDemoCatalogueOrderedByCode() {
        assertThat(mvc.get().uri("/api/v1/resources"))
                .hasStatusOk()
                .bodyJson().extractingPath("$.items[*].code").asArray()
                .containsExactly("AIR_FILTER", "CH4_FUEL", "FOOD_RATION", "MED_KIT", "OXYGEN", "SOLAR_PANEL",
                        "WATER");
    }

    @Test
    void createsAResourceThatIsThenRetrievableAndAudited() {
        long before = lastAuditId();

        assertThat(create(SCRUBBER)).hasStatus(HttpStatus.CREATED);

        assertThat(mvc.get().uri("/api/v1/resources/CO2_SCRUBBER"))
                .hasStatusOk()
                .bodyJson().isLenientlyEqualTo("""
                        {"code":"CO2_SCRUBBER","name":"CO2 scrubber cartridge","category":"LIFE_SUPPORT",
                         "unitCode":"PCS","unitSymbol":"pcs","critical":true,"active":true,"shelfLifeDays":null}""");
        assertThat(jdbc.queryForObject("""
                SELECT a.username || ' ' || e.action || ' ' || (e.new_value_json->>'unitCode')
                FROM aether.audit_event e JOIN aether.user_account a ON a.id_account = e.id_account
                WHERE e.id_audit > ? AND e.entity_type = 'RESOURCE' AND e.entity_id = 'CO2_SCRUBBER'""",
                String.class, before)).isEqualTo("log.marino RESOURCE_CREATED PCS");
    }

    @Test
    void rejectsAnExistingCodeWhateverItsCase() {
        assertConflict(create(SCRUBBER.replace("co2_scrubber", "water")), "RESOURCE_CODE_TAKEN");
    }

    @Test
    void rejectsAnUnknownUnitAndPersistsNothing() {
        assertConflict(create(SCRUBBER.replace("\"pcs\"", "\"barrels\"")), "UNIT_OF_MEASURE_NOT_FOUND");

        assertThat(jdbc.queryForObject("SELECT count(*) FROM aether.resource WHERE code = 'CO2_SCRUBBER'",
                Long.class)).isZero();
    }

    @Test
    void rejectsAMissingUnit() {
        assertThat(create(SCRUBBER.replace("\"pcs\"", "null")))
                .hasStatus(HttpStatus.BAD_REQUEST)
                .bodyJson().extractingPath("$.errors[0].field").isEqualTo("unitCode");
    }

    @Test
    void deactivatesAResourceWithoutTouchingItsStockAndKeepsItListed() {
        long before = lastAuditId();
        Long stockBefore = waterStock();

        assertThat(setActive("water", false))
                .hasStatusOk()
                .bodyJson().extractingPath("$.active").isEqualTo(false);
        assertThat(setActive("WATER", false)).hasStatusOk();

        assertThat(waterStock()).isEqualTo(stockBefore);
        assertThat(mvc.get().uri("/api/v1/resources?active=false"))
                .hasStatusOk()
                .bodyJson().extractingPath("$.items[*].code").asArray().containsExactly("WATER");
        assertThat(jdbc.queryForObject("""
                SELECT count(*) FROM aether.audit_event
                WHERE id_audit > ? AND entity_id = 'WATER' AND action = 'RESOURCE_DEACTIVATED'""",
                Long.class, before)).isEqualTo(1L);

        assertThat(setActive("WATER", true))
                .hasStatusOk()
                .bodyJson().extractingPath("$.active").isEqualTo(true);
    }

    @Test
    void enforcesTheCategoryListInTheDatabaseToo() {
        Long unit = jdbc.queryForObject("SELECT id_unit FROM aether.unit_of_measure WHERE code = 'KG'", Long.class);

        assertThatThrownBy(() -> jdbc.update("""
                INSERT INTO aether.resource(code, name, category, id_unit) VALUES ('BAD', 'Bad', 'WEAPON', ?)""",
                unit))
                .hasMessageContaining("ck_resource_category");
    }

    private Long waterStock() {
        return jdbc.queryForObject("""
                SELECT count(*) FROM aether.inventory_stock s JOIN aether.resource r ON r.id_resource = s.id_resource
                WHERE r.code = 'WATER'""", Long.class);
    }

    private long lastAuditId() {
        return jdbc.queryForObject("SELECT coalesce(max(id_audit), 0) FROM aether.audit_event", Long.class);
    }

    private MvcTestResult create(String body) {
        return mvc.post().uri("/api/v1/resources").with(csrf())
                .contentType(MediaType.APPLICATION_JSON).content(body).exchange();
    }

    private MvcTestResult setActive(String code, boolean active) {
        return mvc.patch().uri("/api/v1/resources/{code}", code).with(csrf())
                .contentType(MediaType.APPLICATION_JSON).content("{\"active\":" + active + "}").exchange();
    }

    private static void assertConflict(MvcTestResult result, String code) {
        assertThat(result).hasStatus(HttpStatus.CONFLICT)
                .bodyJson().extractingPath("$.code").isEqualTo(code);
    }
}
