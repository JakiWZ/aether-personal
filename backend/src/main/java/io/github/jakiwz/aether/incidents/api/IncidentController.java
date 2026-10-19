package io.github.jakiwz.aether.incidents.api;

import io.github.jakiwz.aether.incidents.domain.Incident;
import io.github.jakiwz.aether.incidents.domain.IncidentService;
import io.github.jakiwz.aether.shared.web.PageQuery;
import io.github.jakiwz.aether.shared.web.PageResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Size;
import java.net.URI;
import org.springdoc.core.annotations.ParameterObject;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.servlet.support.ServletUriComponentsBuilder;

@RestController
@RequestMapping("/api/v1/incidents")
@Tag(name = "Incidents", description = "Incidents and safety (HELIOS)")
class IncidentController {

    private final IncidentService service;

    IncidentController(IncidentService service) {
        this.service = service;
    }

    @GetMapping
    @PreAuthorize("hasAuthority('INCIDENT_READ')")
    @Operation(summary = "List incidents", description = "Newest first, then by code.")
    @ApiResponse(responseCode = "400", description = "VALIDATION_FAILED: page or size out of range")
    PageResponse<IncidentResponse> list(@ParameterObject @Valid PageQuery query) {
        return PageResponse.from(service.list(query.pageOrDefault(), query.sizeOrDefault()), IncidentResponse::from);
    }

    @GetMapping("/{code}")
    @PreAuthorize("hasAuthority('INCIDENT_READ')")
    @Operation(summary = "Get an incident by code")
    @ApiResponse(responseCode = "400", description = "VALIDATION_FAILED: code longer than 60 characters")
    @ApiResponse(responseCode = "404", description = "RESOURCE_NOT_FOUND")
    IncidentResponse get(@PathVariable @Size(max = 60) String code) {
        return IncidentResponse.from(service.get(code));
    }

    @PostMapping
    @PreAuthorize("hasAuthority('INCIDENT_REPORT')")
    @Operation(summary = "Open an incident (HEL-501)",
            description = "The incident is created OPEN with a server-assigned code and opening time.")
    @ApiResponse(responseCode = "201", description = "Created; Location points to the new incident")
    @ApiResponse(responseCode = "400", description = "VALIDATION_FAILED: missing or invalid fields or severity")
    @ApiResponse(responseCode = "409", description = "INCIDENT_COLONY_NOT_FOUND")
    ResponseEntity<IncidentResponse> open(@Valid @RequestBody OpenIncidentRequest request) {
        Incident opened = service.open(request.toCommand());
        URI location = ServletUriComponentsBuilder.fromCurrentRequest()
                .path("/{code}").buildAndExpand(opened.code()).toUri();
        return ResponseEntity.created(location).body(IncidentResponse.from(opened));
    }
}
