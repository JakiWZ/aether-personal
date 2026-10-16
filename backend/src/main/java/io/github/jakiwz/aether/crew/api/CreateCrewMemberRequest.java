package io.github.jakiwz.aether.crew.api;

import io.github.jakiwz.aether.crew.domain.CrewStatus;
import io.github.jakiwz.aether.crew.domain.NewCrewMember;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import org.jspecify.annotations.Nullable;

@Schema(name = "CreateCrewMember", description = "Registers a crew member (ARES-103).")
public record CreateCrewMemberRequest(
        @Schema(description = "Unique operational code; stored upper case", example = "CRW-020")
        @NotBlank @Pattern(regexp = "^[A-Za-z0-9][A-Za-z0-9-]{2,39}$",
                message = "must be 3-40 letters, digits or dashes") String employeeCode,
        @Schema(example = "Anna") @NotBlank @Size(max = 100) String firstName,
        @Schema(example = "Verdi") @NotBlank @Size(max = 100) String lastName,
        @Schema(description = "Unique when given; stored lower case", example = "anna.verdi@aether.demo",
                nullable = true)
        @Email @Size(max = 200) @Nullable String email,
        @Schema(description = "Job / operational role", example = "Geologist")
        @NotBlank @Size(max = 80) String operationalRole,
        @Schema(description = "Operational status") @NotNull CrewStatus status,
        @Schema(description = "Code of an active base, when the member is assigned to one",
                example = "ARS-01", nullable = true)
        @Size(max = 30) @Nullable String homeColonyCode) {

    NewCrewMember toCommand() {
        return new NewCrewMember(employeeCode, firstName, lastName, email, operationalRole, status, homeColonyCode);
    }
}
