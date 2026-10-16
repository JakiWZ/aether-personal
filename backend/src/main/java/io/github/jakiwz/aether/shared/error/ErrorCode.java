package io.github.jakiwz.aether.shared.error;

/**
 * Generic, stable error codes exposed in the {@code code} property of every Problem Details response.
 * Clients switch on these codes, never on the human-readable {@code detail}.
 * Domain-specific rule violations use their own codes (e.g. {@code CREW_ASSIGNMENT_OVERLAP}).
 */
public final class ErrorCode {

    public static final String VALIDATION_FAILED = "VALIDATION_FAILED";
    public static final String MALFORMED_REQUEST = "MALFORMED_REQUEST";
    public static final String RESOURCE_NOT_FOUND = "RESOURCE_NOT_FOUND";
    public static final String METHOD_NOT_ALLOWED = "METHOD_NOT_ALLOWED";
    public static final String UNSUPPORTED_MEDIA_TYPE = "UNSUPPORTED_MEDIA_TYPE";
    public static final String DATA_INTEGRITY_VIOLATION = "DATA_INTEGRITY_VIOLATION";
    public static final String INTERNAL_ERROR = "INTERNAL_ERROR";

    private ErrorCode() {
    }
}
