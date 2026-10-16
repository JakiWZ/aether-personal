package io.github.jakiwz.aether.shared.error;

import org.springframework.http.HttpStatus;

/**
 * Base class for expected, client-facing failures. The message is safe to show to API clients.
 */
public abstract class AetherException extends RuntimeException {

    private final String code;
    private final HttpStatus status;

    protected AetherException(HttpStatus status, String code, String message) {
        super(message);
        this.status = status;
        this.code = code;
    }

    public String code() {
        return code;
    }

    public HttpStatus status() {
        return status;
    }
}
