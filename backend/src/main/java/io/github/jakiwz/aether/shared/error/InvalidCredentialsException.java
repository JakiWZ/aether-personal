package io.github.jakiwz.aether.shared.error;

import org.springframework.http.HttpStatus;

/**
 * A login that did not succeed (HTTP 401). One message for every reason, so the response does not
 * tell whether the username exists or the account is locked (OWASP Authentication Cheat Sheet).
 */
public class InvalidCredentialsException extends AetherException {

    public InvalidCredentialsException() {
        super(HttpStatus.UNAUTHORIZED, ErrorCode.INVALID_CREDENTIALS, "Invalid username or password.");
    }
}
