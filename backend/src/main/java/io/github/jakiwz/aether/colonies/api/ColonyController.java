package io.github.jakiwz.aether.colonies.api;

import io.github.jakiwz.aether.colonies.domain.ColonyService;
import io.github.jakiwz.aether.shared.web.PageQuery;
import io.github.jakiwz.aether.shared.web.PageResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.util.List;
import org.jspecify.annotations.Nullable;
import org.springdoc.core.annotations.ParameterObject;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/colonies")
@Tag(name = "Colonies", description = "Martian bases (ARES)")
class ColonyController {

    private final ColonyService service;

    ColonyController(ColonyService service) {
        this.service = service;
    }

    @GetMapping
    @PreAuthorize("hasAuthority('COLONY_READ')")
    @Operation(summary = "List bases",
            description = "Bases ordered by code, inactive ones included unless filtered out (ARES-101).")
    @ApiResponse(responseCode = "400", description = "VALIDATION_FAILED: page or size out of range")
    PageResponse<ColonyResponse> list(
            @Parameter(description = "true: only active bases · false: only inactive bases · omitted: all")
            @RequestParam(required = false) @Nullable Boolean active,
            @ParameterObject @Valid PageQuery query) {
        return PageResponse.from(service.list(active, query.pageOrDefault(), query.sizeOrDefault()),
                ColonyResponse::from);
    }
}
