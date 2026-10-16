package io.github.jakiwz.aether.crew.domain;

/**
 * Stable error codes of the crew domain (ADR-0005); part of the public API.
 */
public final class CrewErrorCode {

    public static final String CREW_MEMBER_CODE_TAKEN = "CREW_MEMBER_CODE_TAKEN";
    public static final String PERSON_EMAIL_TAKEN = "PERSON_EMAIL_TAKEN";
    public static final String HOME_COLONY_NOT_FOUND = "HOME_COLONY_NOT_FOUND";
    public static final String HOME_COLONY_INACTIVE = "HOME_COLONY_INACTIVE";

    private CrewErrorCode() {
    }
}
