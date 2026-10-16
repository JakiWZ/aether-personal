package io.github.jakiwz.aether.crew.api;

import io.github.jakiwz.aether.crew.domain.CrewMember;
import io.github.jakiwz.aether.crew.domain.CrewMemberService;
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
@RequestMapping("/api/v1/crew-members")
@Tag(name = "Crew members", description = "Crew registry (ARES)")
class CrewMemberController {

    private final CrewMemberService service;

    CrewMemberController(CrewMemberService service) {
        this.service = service;
    }

    @GetMapping
    @Operation(summary = "List crew members", description = "Ordered by employee code.")
    @ApiResponse(responseCode = "400", description = "VALIDATION_FAILED: page or size out of range")
    PageResponse<CrewMemberResponse> list(@ParameterObject @Valid PageQuery query) {
        return PageResponse.from(service.list(query.pageOrDefault(), query.sizeOrDefault()),
                CrewMemberResponse::from);
    }

    @GetMapping("/{employeeCode}")
    @Operation(summary = "Get a crew member by employee code")
    @ApiResponse(responseCode = "404", description = "RESOURCE_NOT_FOUND")
    CrewMemberResponse get(@PathVariable String employeeCode) {
        return CrewMemberResponse.from(service.get(employeeCode));
    }

    @PostMapping
    @Operation(summary = "Register a crew member (ARES-103)")
    @ApiResponse(responseCode = "201", description = "Created; Location points to the new member")
    @ApiResponse(responseCode = "400", description = "VALIDATION_FAILED: missing or invalid fields")
    @ApiResponse(responseCode = "409", description = "CREW_MEMBER_CODE_TAKEN, PERSON_EMAIL_TAKEN, "
            + "HOME_COLONY_NOT_FOUND or HOME_COLONY_INACTIVE")
    ResponseEntity<CrewMemberResponse> register(@Valid @RequestBody CreateCrewMemberRequest request) {
        CrewMember created = service.register(request.toCommand());
        URI location = ServletUriComponentsBuilder.fromCurrentRequest()
                .path("/{employeeCode}").buildAndExpand(created.employeeCode()).toUri();
        return ResponseEntity.created(location).body(CrewMemberResponse.from(created));
    }
}
