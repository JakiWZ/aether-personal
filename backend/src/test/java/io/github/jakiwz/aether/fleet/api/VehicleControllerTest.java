package io.github.jakiwz.aether.fleet.api;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;

import io.github.jakiwz.aether.fleet.domain.AssetCriticality;
import io.github.jakiwz.aether.fleet.domain.AssetStatus;
import io.github.jakiwz.aether.fleet.domain.Vehicle;
import io.github.jakiwz.aether.fleet.domain.VehicleService;
import io.github.jakiwz.aether.shared.error.ResourceNotFoundException;
import io.github.jakiwz.aether.shared.security.SecurityConfig;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import org.junit.jupiter.api.Test;
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
 * Contract of {@code GET /api/v1/vehicles} (TIT-301).
 */
@WebMvcTest(VehicleController.class)
@Import(SecurityConfig.class)
@WithMockUser(authorities = "ASSET_READ")
class VehicleControllerTest {

    private static final Vehicle ROVER = new Vehicle("ROV-ARS-01", "ROVER", "Pressurised rover",
            "RedRock Mobility", "Pathfinder X2", "SN-RV-1001", AssetStatus.IN_USE, AssetCriticality.HIGH,
            "ARS-01", true, LocalDate.of(2031, 5, 1), new BigDecimal("4120.50"));

    private static final Vehicle DRONE = new Vehicle("DRN-ELY-01", "DRONE", "Survey drone",
            null, null, null, AssetStatus.OUT_OF_SERVICE, AssetCriticality.MEDIUM,
            "ELY-01", true, null, new BigDecimal("0.00"));

    @Autowired
    MockMvcTester mvc;

    @MockitoBean
    VehicleService service;

    @Test
    void listsVehiclesWithTypeStatusAndBase() {
        given(service.list(null, 0, 20))
                .willReturn(new PageImpl<>(List.of(DRONE, ROVER), PageRequest.of(0, 20), 2));

        MvcTestResult result = mvc.get().uri("/api/v1/vehicles").exchange();

        assertThat(result).hasStatusOk().hasContentTypeCompatibleWith(MediaType.APPLICATION_JSON);
        assertThat(result).bodyJson().isEqualTo("""
                {"items":[
                  {"code":"DRN-ELY-01","typeCode":"DRONE","typeName":"Survey drone","manufacturer":null,
                   "model":null,"serialNumber":null,"status":"OUT_OF_SERVICE","criticality":"MEDIUM",
                   "colonyCode":"ELY-01","active":true,"commissionedAt":null,"operatingHours":0.00},
                  {"code":"ROV-ARS-01","typeCode":"ROVER","typeName":"Pressurised rover",
                   "manufacturer":"RedRock Mobility","model":"Pathfinder X2","serialNumber":"SN-RV-1001",
                   "status":"IN_USE","criticality":"HIGH","colonyCode":"ARS-01","active":true,
                   "commissionedAt":"2031-05-01","operatingHours":4120.50}
                 ],
                 "page":0,"size":20,"totalItems":2,"totalPages":1}""");
    }

    @Test
    void passesTheStatusFilterToTheService() {
        given(service.list(AssetStatus.MAINTENANCE, 1, 5))
                .willReturn(new PageImpl<>(List.of(), PageRequest.of(1, 5), 0));

        assertThat(mvc.get().uri("/api/v1/vehicles?status=MAINTENANCE&page=1&size=5"))
                .hasStatusOk()
                .bodyJson().isEqualTo("""
                        {"items":[],"page":1,"size":5,"totalItems":0,"totalPages":0}""");
        verify(service).list(AssetStatus.MAINTENANCE, 1, 5);
    }

    @Test
    void rejectsAnUnknownStatus() {
        MvcTestResult result = mvc.get().uri("/api/v1/vehicles?status=BROKEN").exchange();

        assertThat(result).hasStatus(HttpStatus.BAD_REQUEST)
                .hasContentTypeCompatibleWith(MediaType.APPLICATION_PROBLEM_JSON);
        assertThat(result).bodyJson().extractingPath("$.code").isEqualTo("MALFORMED_REQUEST");
        verify(service, never()).list(any(), anyInt(), anyInt());
    }

    @Test
    void rejectsPagingOutsideTheLimits() {
        assertThat(mvc.get().uri("/api/v1/vehicles?size=101"))
                .hasStatus(HttpStatus.BAD_REQUEST)
                .bodyJson().extractingPath("$.code").isEqualTo("VALIDATION_FAILED");
        verify(service, never()).list(any(), anyInt(), anyInt());
    }

    @Test
    void returnsOneVehicleByCode() {
        given(service.get("ROV-ARS-01")).willReturn(ROVER);

        assertThat(mvc.get().uri("/api/v1/vehicles/ROV-ARS-01"))
                .hasStatusOk()
                .bodyJson().isLenientlyEqualTo("""
                        {"code":"ROV-ARS-01","status":"IN_USE","colonyCode":"ARS-01"}""");
    }

    @Test
    void answersNotFoundForAnUnknownVehicle() {
        given(service.get("GEN-ARS-01")).willThrow(new ResourceNotFoundException("Vehicle", "GEN-ARS-01"));

        MvcTestResult result = mvc.get().uri("/api/v1/vehicles/GEN-ARS-01").exchange();

        assertThat(result).hasStatus(HttpStatus.NOT_FOUND)
                .hasContentTypeCompatibleWith(MediaType.APPLICATION_PROBLEM_JSON);
        assertThat(result).bodyJson().extractingPath("$.code").isEqualTo("RESOURCE_NOT_FOUND");
    }
}
