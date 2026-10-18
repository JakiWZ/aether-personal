package io.github.jakiwz.aether.inventory.api;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyBoolean;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;

import io.github.jakiwz.aether.inventory.domain.InventoryErrorCode;
import io.github.jakiwz.aether.inventory.domain.NewResource;
import io.github.jakiwz.aether.inventory.domain.Resource;
import io.github.jakiwz.aether.inventory.domain.ResourceCategory;
import io.github.jakiwz.aether.inventory.domain.ResourceService;
import io.github.jakiwz.aether.inventory.domain.UnitOfMeasure;
import io.github.jakiwz.aether.shared.error.BusinessRuleViolationException;
import io.github.jakiwz.aether.shared.error.ResourceNotFoundException;
import io.github.jakiwz.aether.shared.security.SecurityConfig;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.assertj.MockMvcTester;
import org.springframework.test.web.servlet.assertj.MvcTestResult;

/**
 * Contract of {@code /api/v1/resources} and {@code /api/v1/units-of-measure} (ORI-401).
 */
@WebMvcTest({ResourceController.class, UnitOfMeasureController.class})
@Import(SecurityConfig.class)
@WithMockUser(authorities = {"INVENTORY_READ", "INVENTORY_MANAGE"})
class ResourceControllerTest {

    private static final String VALID_BODY = """
            {"code":"co2_scrubber","name":"CO2 scrubber cartridge","category":"LIFE_SUPPORT","unitCode":"pcs",
             "critical":true,"shelfLifeDays":365}""";

    private static final Resource SCRUBBER = new Resource("CO2_SCRUBBER", "CO2 scrubber cartridge",
            ResourceCategory.LIFE_SUPPORT, "PCS", "pcs", true, true, 365);

    @Autowired
    MockMvcTester mvc;

    @MockitoBean
    ResourceService service;

    @Test
    void listsResourcesWithCategoryUnitAndActivity() {
        Resource oldFilter = new Resource("AIR_FILTER", "HEPA air filter cartridge", ResourceCategory.SPARE_PART,
                "PCS", "pcs", false, false, null);
        given(service.list(null, 0, 20))
                .willReturn(new PageImpl<>(List.of(oldFilter, SCRUBBER), PageRequest.of(0, 20), 2));

        MvcTestResult result = mvc.get().uri("/api/v1/resources").exchange();

        assertThat(result).hasStatusOk().hasContentTypeCompatibleWith(MediaType.APPLICATION_JSON);
        assertThat(result).bodyJson().isEqualTo("""
                {"items":[
                  {"code":"AIR_FILTER","name":"HEPA air filter cartridge","category":"SPARE_PART",
                   "unitCode":"PCS","unitSymbol":"pcs","critical":false,"active":false,"shelfLifeDays":null},
                  {"code":"CO2_SCRUBBER","name":"CO2 scrubber cartridge","category":"LIFE_SUPPORT",
                   "unitCode":"PCS","unitSymbol":"pcs","critical":true,"active":true,"shelfLifeDays":365}
                 ],
                 "page":0,"size":20,"totalItems":2,"totalPages":1}""");
    }

    @Test
    void passesTheActiveFilterToTheService() {
        given(service.list(true, 0, 20)).willReturn(new PageImpl<>(List.of(), PageRequest.of(0, 20), 0));

        assertThat(mvc.get().uri("/api/v1/resources?active=true")).hasStatusOk();
        verify(service).list(true, 0, 20);
    }

    @Test
    void createsAResourceAndPointsToIt() {
        given(service.create(any())).willReturn(SCRUBBER);

        MvcTestResult result = post(VALID_BODY);

        assertThat(result).hasStatus(HttpStatus.CREATED)
                .hasHeader("Location", "http://localhost/api/v1/resources/CO2_SCRUBBER");
        assertThat(result).bodyJson().extractingPath("$.active").isEqualTo(true);
        verify(service).create(new NewResource("co2_scrubber", "CO2 scrubber cartridge",
                ResourceCategory.LIFE_SUPPORT, "pcs", true, 365));
    }

    @ParameterizedTest
    @ValueSource(strings = {"code", "name", "category", "unitCode", "critical"})
    void rejectsAResourceWithoutAMandatoryField(String field) {
        String body = VALID_BODY.replaceFirst("\"" + field + "\":(\"[^\"]*\"|true)", "\"" + field + "\":null");

        MvcTestResult result = post(body);

        assertThat(result).hasStatus(HttpStatus.BAD_REQUEST)
                .hasContentTypeCompatibleWith(MediaType.APPLICATION_PROBLEM_JSON);
        assertThat(result).bodyJson().extractingPath("$.code").isEqualTo("VALIDATION_FAILED");
        assertThat(result).bodyJson().extractingPath("$.errors[0].field").isEqualTo(field);
        verifyNoInteractions(service);
    }

    @ParameterizedTest
    @ValueSource(strings = {"\"code\":\"a b\"", "\"shelfLifeDays\":0", "\"category\":\"WEAPON\""})
    void rejectsMalformedFields(String replacement) {
        String field = replacement.substring(1, replacement.indexOf('"', 1));
        String body = VALID_BODY.replaceFirst("\"" + field + "\":(\"[^\"]*\"|\\d+)", replacement);

        assertThat(post(body)).hasStatus(HttpStatus.BAD_REQUEST);
        verifyNoInteractions(service);
    }

    @Test
    void reportsATakenCodeAsAConflict() {
        given(service.create(any())).willThrow(new BusinessRuleViolationException(
                InventoryErrorCode.RESOURCE_CODE_TAKEN, "Resource code 'CO2_SCRUBBER' is already in use."));

        MvcTestResult result = post(VALID_BODY);

        assertThat(result).hasStatus(HttpStatus.CONFLICT)
                .bodyJson().extractingPath("$.code").isEqualTo("RESOURCE_CODE_TAKEN");
    }

    @Test
    void deactivatesAResource() {
        Resource inactive = new Resource("CO2_SCRUBBER", "CO2 scrubber cartridge", ResourceCategory.LIFE_SUPPORT,
                "PCS", "pcs", true, false, 365);
        given(service.setActive("CO2_SCRUBBER", false)).willReturn(inactive);

        assertThat(patch("CO2_SCRUBBER", "{\"active\":false}"))
                .hasStatusOk()
                .bodyJson().extractingPath("$.active").isEqualTo(false);
    }

    @Test
    void rejectsAnUpdateWithoutTheActiveFlagOrWithOtherFields() {
        assertThat(patch("CO2_SCRUBBER", "{}")).hasStatus(HttpStatus.BAD_REQUEST);
        assertThat(patch("CO2_SCRUBBER", "{\"active\":false,\"name\":\"Renamed\"}")).hasStatus(HttpStatus.BAD_REQUEST);
        verify(service, never()).setActive(anyString(), anyBoolean());
    }

    @Test
    void answersNotFoundWhenDeactivatingAnUnknownResource() {
        given(service.setActive("NOPE", false)).willThrow(new ResourceNotFoundException("Resource", "NOPE"));

        assertThat(patch("NOPE", "{\"active\":false}"))
                .hasStatus(HttpStatus.NOT_FOUND)
                .bodyJson().extractingPath("$.code").isEqualTo("RESOURCE_NOT_FOUND");
    }

    @Test
    void listsTheUnitsOfMeasure() {
        given(service.units(0, 100)).willReturn(new PageImpl<>(
                List.of(new UnitOfMeasure("KG", "Kilogram", "kg", "MASS")), PageRequest.of(0, 100), 1));

        assertThat(mvc.get().uri("/api/v1/units-of-measure?size=100"))
                .hasStatusOk()
                .bodyJson().isLenientlyEqualTo("""
                        {"items":[{"code":"KG","name":"Kilogram","symbol":"kg","quantityType":"MASS"}],
                         "totalItems":1}""");
    }

    private MvcTestResult post(String body) {
        return mvc.post().uri("/api/v1/resources").with(csrf())
                .contentType(MediaType.APPLICATION_JSON).content(body).exchange();
    }

    private MvcTestResult patch(String code, String body) {
        return mvc.patch().uri("/api/v1/resources/{code}", code).with(csrf())
                .contentType(MediaType.APPLICATION_JSON).content(body).exchange();
    }
}
