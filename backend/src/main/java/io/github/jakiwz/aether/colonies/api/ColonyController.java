package io.github.jakiwz.aether.colonies.api;

import io.github.jakiwz.aether.colonies.domain.ColonyService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import java.util.List;
import org.jspecify.annotations.Nullable;
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
    @Operation(summary = "List bases",
            description = "Bases ordered by code, inactive ones included unless filtered out (ARES-101).")
    List<ColonyResponse> list(
            @Parameter(description = "true: only active bases · false: only inactive bases · omitted: all")
            @RequestParam(required = false) @Nullable Boolean active) {
        return service.list(active).stream().map(ColonyResponse::from).toList();
    }
}
