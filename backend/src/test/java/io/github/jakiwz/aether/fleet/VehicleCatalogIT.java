package io.github.jakiwz.aether.fleet;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.assertj.MockMvcTester;
import org.springframework.transaction.annotation.Transactional;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.postgresql.PostgreSQLContainer;

/**
 * TIT-301 end to end on the demo dataset: only vehicles are listed, in every status, retired ones
 * included, and the status filter narrows the list.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("demo")
@WithMockUser(username = "mnt.bianchi", authorities = "ASSET_READ")
@Testcontainers
@Transactional // the extra rows inserted by a test are rolled back
class VehicleCatalogIT {

    @Container
    @ServiceConnection
    static final PostgreSQLContainer POSTGRES = new PostgreSQLContainer("postgres:16-alpine");

    @Autowired
    MockMvcTester mvc;

    @Autowired
    JdbcTemplate jdbc;

    @Test
    void listsOnlyVehiclesOrderedByCodeIncludingRetiredOnes() {
        assertThat(mvc.get().uri("/api/v1/vehicles"))
                .hasStatusOk()
                .bodyJson().extractingPath("$.items[*].code").asArray()
                .containsExactly("DRN-ELY-01", "DRN-VLM-01", "ROV-ARS-01", "ROV-ARS-02", "ROV-ARS-03",
                        "ROV-ELY-01", "ROV-OLD-01", "ROV-VLM-01", "SHT-ARS-01");
    }

    @Test
    void showsTypeStatusCriticalityAndBase() {
        assertThat(mvc.get().uri("/api/v1/vehicles/rov-old-01"))
                .hasStatusOk()
                .bodyJson().isLenientlyEqualTo("""
                        {"code":"ROV-OLD-01","typeCode":"ROVER","typeName":"Pressurised rover",
                         "model":"Pathfinder X0","status":"DECOMMISSIONED","criticality":"LOW",
                         "colonyCode":"ARS-01","active":false}""");
    }

    @Test
    void filtersByStatus() {
        assertThat(mvc.get().uri("/api/v1/vehicles?status=OUT_OF_SERVICE"))
                .hasStatusOk()
                .bodyJson().extractingPath("$.items[*].code").asArray().containsExactly("DRN-ELY-01");
        assertThat(mvc.get().uri("/api/v1/vehicles?status=AVAILABLE"))
                .hasStatusOk()
                .bodyJson().extractingPath("$.items[*].code").asArray()
                .containsExactly("DRN-VLM-01", "ROV-ARS-02", "ROV-ELY-01", "ROV-VLM-01", "SHT-ARS-01");
    }

    @Test
    void answersAnEmptyPageWhenNoVehicleMatches() {
        jdbc.update("UPDATE aether.asset SET status = 'AVAILABLE' WHERE status = 'MAINTENANCE'");

        assertThat(mvc.get().uri("/api/v1/vehicles?status=MAINTENANCE"))
                .hasStatusOk()
                .bodyJson().isLenientlyEqualTo("""
                        {"items":[],"page":0,"totalItems":0,"totalPages":0}""");
    }

    @Test
    void doesNotExposeFixedPlantAsAVehicle() {
        assertThat(mvc.get().uri("/api/v1/vehicles/GEN-ARS-01"))
                .hasStatus(HttpStatus.NOT_FOUND)
                .bodyJson().extractingPath("$.code").isEqualTo("RESOURCE_NOT_FOUND");
    }
}
