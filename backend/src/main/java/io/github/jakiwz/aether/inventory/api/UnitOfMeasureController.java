package io.github.jakiwz.aether.inventory.api;

import io.github.jakiwz.aether.inventory.domain.ResourceService;
import io.github.jakiwz.aether.shared.web.PageQuery;
import io.github.jakiwz.aether.shared.web.PageResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springdoc.core.annotations.ParameterObject;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/units-of-measure")
@Tag(name = "Resources", description = "Resource catalogue (ORION)")
class UnitOfMeasureController {

    private final ResourceService service;

    UnitOfMeasureController(ResourceService service) {
        this.service = service;
    }

    @GetMapping
    @PreAuthorize("hasAuthority('INVENTORY_READ')")
    @Operation(summary = "List units of measure", description = "Ordered by code.")
    @ApiResponse(responseCode = "400", description = "VALIDATION_FAILED: page or size out of range")
    PageResponse<UnitOfMeasureResponse> list(@ParameterObject @Valid PageQuery query) {
        return PageResponse.from(service.units(query.pageOrDefault(), query.sizeOrDefault()),
                UnitOfMeasureResponse::from);
    }
}
