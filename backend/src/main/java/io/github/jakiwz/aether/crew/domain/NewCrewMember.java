package io.github.jakiwz.aether.crew.domain;

import org.jspecify.annotations.Nullable;

/**
 * Data needed to register a crew member; already validated for shape by the API layer.
 */
public record NewCrewMember(
        String employeeCode,
        String firstName,
        String lastName,
        @Nullable String email,
        String operationalRole,
        CrewStatus status,
        @Nullable String homeColonyCode) {
}
