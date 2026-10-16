package io.github.jakiwz.aether.shared.error;

import org.springframework.http.HttpStatus;

/**
 * A well-formed request that conflicts with a business rule or with the current state
 * (HTTP 409), e.g. an overlapping crew assignment or closing an already closed incident.
 * The code is domain specific and stable, e.g. {@code CREW_ASSIGNMENT_OVERLAP}.
 */
public class BusinessRuleViolationException extends AetherException {

    public BusinessRuleViolationException(String code, String message) {
        super(HttpStatus.CONFLICT, code, message);
    }
}
