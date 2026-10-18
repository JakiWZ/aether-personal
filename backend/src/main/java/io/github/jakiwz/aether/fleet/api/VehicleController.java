package io.github.jakiwz.aether.fleet.api;

import io.github.jakiwz.aether.fleet.domain.AssetStatus;
import io.github.jakiwz.aether.fleet.domain.VehicleService;
import io.github.jakiwz.aether.shared.web.PageQuery;
import io.github.jakiwz.aether.shared.web.PageResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Size;
import org.jspecify.annotations.Nullable;
import org.springdoc.core.annotations.ParameterObject;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/vehicles")
@Tag(name = "Vehicles", description = "Fleet catalogue (TITAN)")
class VehicleController {

    private final VehicleService service;

    VehicleController(VehicleService service) {
        this.service = service;
    }

    @GetMapping
    @PreAuthorize("hasAuthority('ASSET_READ')")
    @Operation(summary = "List vehicles",
            description = "Vehicles ordered by code; out of service and decommissioned ones included (TIT-301).")
    @ApiResponse(responseCode = "400", description = "VALIDATION_FAILED: page or size out of range · "
            + "MALFORMED_REQUEST: unknown status")
    PageResponse<VehicleResponse> list(
            @Parameter(description = "Only the vehicles in this status; omitted: all")
            @RequestParam(required = false) @Nullable AssetStatus status,
            @ParameterObject @Valid PageQuery query) {
        return PageResponse.from(service.list(status, query.pageOrDefault(), query.sizeOrDefault()),
                VehicleResponse::from);
    }

    @GetMapping("/{code}")
    @PreAuthorize("hasAuthority('ASSET_READ')")
    @Operation(summary = "Get a vehicle by code")
    @ApiResponse(responseCode = "400", description = "VALIDATION_FAILED: code longer than 60 characters")
    @ApiResponse(responseCode = "404", description = "RESOURCE_NOT_FOUND, also for an asset that is not a vehicle")
    VehicleResponse get(@PathVariable @Size(max = 60) String code) {
        return VehicleResponse.from(service.get(code));
    }
}
