package io.github.jakiwz.aether.crew.api;

import io.github.jakiwz.aether.crew.domain.CrewMember;
import io.github.jakiwz.aether.crew.domain.CrewStatus;
import io.swagger.v3.oas.annotations.media.Schema;
import org.jspecify.annotations.Nullable;

@Schema(name = "CrewMember", description = "Operational profile of a crew member.")
public record CrewMemberResponse(
        @Schema(example = "CRW-001") String employeeCode,
        String firstName,
        String lastName,
        @Schema(nullable = true) @Nullable String email,
        String operationalRole,
        CrewStatus status,
        @Schema(description = "Code of the home base", nullable = true) @Nullable String homeColonyCode) {

    static CrewMemberResponse from(CrewMember member) {
        return new CrewMemberResponse(member.employeeCode(), member.firstName(), member.lastName(), member.email(),
                member.operationalRole(), member.status(), member.homeColonyCode());
    }
}
