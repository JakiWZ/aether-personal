package io.github.jakiwz.aether.shared.error;

import java.time.Duration;
import org.springframework.http.HttpStatus;

/**
 * Too many logins from one client address (HTTP 429). Says when to try again but nothing about the
 * accounts involved (ADR-0012).
 */
public class TooManyLoginAttemptsException extends AetherException {

    private final Duration retryAfter;

    public TooManyLoginAttemptsException(Duration retryAfter) {
        super(HttpStatus.TOO_MANY_REQUESTS, ErrorCode.TOO_MANY_LOGIN_ATTEMPTS,
                "Too many sign-in attempts. Wait a moment and try again.");
        this.retryAfter = retryAfter;
    }

    /** Whole seconds, at least 1, as the {@code Retry-After} header expects (RFC 9110). */
    public long retryAfterSeconds() {
        return Math.max(1, (retryAfter.toMillis() + 999) / 1000);
    }
}
