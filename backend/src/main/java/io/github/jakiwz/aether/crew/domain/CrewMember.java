package io.github.jakiwz.aether.crew.domain;

import org.jspecify.annotations.Nullable;

/**
 * Operational profile of a crew member (ARES-103). {@code employeeCode} is the business key.
 */
public record CrewMember(
        String employeeCode,
        String firstName,
        String lastName,
        @Nullable String email,
        String operationalRole,
        CrewStatus status,
        @Nullable String homeColonyCode) {
}
