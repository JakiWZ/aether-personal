package io.github.jakiwz.aether.shared.error;

/**
 * One invalid input value, reported in the {@code errors} property of a validation problem.
 */
public record FieldViolation(String field, String message) {
}
