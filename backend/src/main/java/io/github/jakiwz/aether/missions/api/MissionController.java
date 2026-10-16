package io.github.jakiwz.aether.missions.api;

import io.github.jakiwz.aether.missions.domain.Mission;
import io.github.jakiwz.aether.missions.domain.MissionService;
import io.github.jakiwz.aether.shared.web.PageQuery;
import io.github.jakiwz.aether.shared.web.PageResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.net.URI;
import java.util.List;
import org.springdoc.core.annotations.ParameterObject;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.servlet.support.ServletUriComponentsBuilder;

@RestController
@RequestMapping("/api/v1/missions")
@Tag(name = "Missions", description = "Mission planning (PHOENIX)")
class MissionController {

    private final MissionService service;

    MissionController(MissionService service) {
        this.service = service;
    }

    @GetMapping
    @Operation(summary = "List missions", description = "Ordered by planned start, then code.")
    @ApiResponse(responseCode = "400", description = "VALIDATION_FAILED: page or size out of range")
    PageResponse<MissionResponse> list(@ParameterObject @Valid PageQuery query) {
        return PageResponse.from(service.list(query.pageOrDefault(), query.sizeOrDefault()), MissionResponse::from);
    }

    @GetMapping("/{code}")
    @Operation(summary = "Get a mission by code")
    @ApiResponse(responseCode = "404", description = "RESOURCE_NOT_FOUND")
    MissionResponse get(@PathVariable String code) {
        return MissionResponse.from(service.get(code));
    }

    @PostMapping
    @Operation(summary = "Draft a mission (PHX-201)", description = "The mission is created in status DRAFT.")
    @ApiResponse(responseCode = "201", description = "Created; Location points to the new mission")
    @ApiResponse(responseCode = "400", description = "VALIDATION_FAILED: missing or invalid fields, "
            + "start in the past or end not after start")
    @ApiResponse(responseCode = "409", description = "MISSION_CODE_TAKEN, ORIGIN_COLONY_NOT_FOUND or "
            + "ORIGIN_COLONY_INACTIVE")
    ResponseEntity<MissionResponse> create(@Valid @RequestBody CreateMissionRequest request) {
        Mission created = service.create(request.toCommand());
        URI location = ServletUriComponentsBuilder.fromCurrentRequest()
                .path("/{code}").buildAndExpand(created.code()).toUri();
        return ResponseEntity.created(location).body(MissionResponse.from(created));
    }
}
