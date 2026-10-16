package io.github.jakiwz.aether.shared.web;

import io.swagger.v3.oas.annotations.Parameter;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import org.jspecify.annotations.Nullable;

/**
 * The {@code page} and {@code size} query parameters every list endpoint accepts (ADR-0011).
 * The server caps the size, so no request can pull a whole table (OWASP API4:2023).
 */
public record PageQuery(
        @Parameter(description = "Zero-based page index", example = "0")
        @Min(0) @Max(MAX_PAGE) @Nullable Integer page,
        @Parameter(description = "Items per page, at most " + MAX_SIZE, example = "20")
        @Min(1) @Max(MAX_SIZE) @Nullable Integer size) {

    public static final int DEFAULT_SIZE = 20;
    public static final int MAX_SIZE = 100;
    /** Keeps the database offset bounded; filters, not deep paging, narrow large result sets. */
    public static final int MAX_PAGE = 10_000;

    public int pageOrDefault() {
        return page != null ? page : 0;
    }

    public int sizeOrDefault() {
        return size != null ? size : DEFAULT_SIZE;
    }
}
