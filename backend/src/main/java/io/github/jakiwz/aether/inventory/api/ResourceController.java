package io.github.jakiwz.aether.inventory.api;

import io.github.jakiwz.aether.inventory.domain.Resource;
import io.github.jakiwz.aether.inventory.domain.ResourceService;
import io.github.jakiwz.aether.shared.web.PageQuery;
import io.github.jakiwz.aether.shared.web.PageResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Size;
import java.net.URI;
import org.jspecify.annotations.Nullable;
import org.springdoc.core.annotations.ParameterObject;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.servlet.support.ServletUriComponentsBuilder;

@RestController
@RequestMapping("/api/v1/resources")
@Tag(name = "Resources", description = "Resource catalogue (ORION)")
class ResourceController {

    private final ResourceService service;

    ResourceController(ResourceService service) {
        this.service = service;
    }

    @GetMapping
    @PreAuthorize("hasAuthority('INVENTORY_READ')")
    @Operation(summary = "List resources",
            description = "Resources ordered by code, inactive ones included unless filtered out (ORI-401).")
    @ApiResponse(responseCode = "400", description = "VALIDATION_FAILED: page or size out of range")
    PageResponse<ResourceResponse> list(
            @Parameter(description = "true: only active resources · false: only inactive ones · omitted: all")
            @RequestParam(required = false) @Nullable Boolean active,
            @ParameterObject @Valid PageQuery query) {
        return PageResponse.from(service.list(active, query.pageOrDefault(), query.sizeOrDefault()),
                ResourceResponse::from);
    }

    @GetMapping("/{code}")
    @PreAuthorize("hasAuthority('INVENTORY_READ')")
    @Operation(summary = "Get a resource by code")
    @ApiResponse(responseCode = "400", description = "VALIDATION_FAILED: code longer than 50 characters")
    @ApiResponse(responseCode = "404", description = "RESOURCE_NOT_FOUND")
    ResourceResponse get(@PathVariable @Size(max = 50) String code) {
        return ResourceResponse.from(service.get(code));
    }

    @PostMapping
    @PreAuthorize("hasAuthority('INVENTORY_MANAGE')")
    @Operation(summary = "Add a resource to the catalogue (ORI-401)", description = "The resource is created active.")
    @ApiResponse(responseCode = "201", description = "Created; Location points to the new resource")
    @ApiResponse(responseCode = "400", description = "VALIDATION_FAILED: missing or invalid fields")
    @ApiResponse(responseCode = "409", description = "RESOURCE_CODE_TAKEN or UNIT_OF_MEASURE_NOT_FOUND")
    ResponseEntity<ResourceResponse> create(@Valid @RequestBody CreateResourceRequest request) {
        Resource created = service.create(request.toCommand());
        URI location = ServletUriComponentsBuilder.fromCurrentRequest()
                .path("/{code}").buildAndExpand(created.code()).toUri();
        return ResponseEntity.created(location).body(ResourceResponse.from(created));
    }

    @PatchMapping("/{code}")
    @PreAuthorize("hasAuthority('INVENTORY_MANAGE')")
    @Operation(summary = "Activate or deactivate a resource (ORI-401)",
            description = "The resource is never deleted; its stock and history stay (BR-010).")
    @ApiResponse(responseCode = "400", description = "VALIDATION_FAILED: active missing or code too long")
    @ApiResponse(responseCode = "404", description = "RESOURCE_NOT_FOUND")
    ResourceResponse update(@PathVariable @Size(max = 50) String code,
            @Valid @RequestBody UpdateResourceRequest request) {
        return ResourceResponse.from(service.setActive(code, request.active()));
    }
}
