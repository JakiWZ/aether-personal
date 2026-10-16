package io.github.jakiwz.aether.shared.web;

import io.swagger.v3.oas.annotations.media.Schema;
import java.util.List;
import java.util.function.Function;
import org.springframework.data.domain.Page;

/**
 * One page of a list endpoint (ADR-0011). A page past the last one has no items and the same totals.
 */
public record PageResponse<T>(
        @Schema(description = "The items of this page, in the endpoint's documented order") List<T> items,
        @Schema(description = "Zero-based page index", example = "0") int page,
        @Schema(description = "Requested page size", example = "20") int size,
        @Schema(description = "Items across all pages", example = "42") long totalItems,
        @Schema(description = "Number of pages", example = "3") int totalPages) {

    public static <D, T> PageResponse<T> from(Page<D> page, Function<? super D, ? extends T> mapper) {
        return new PageResponse<>(page.getContent().stream().<T>map(mapper).toList(), page.getNumber(),
                page.getSize(), page.getTotalElements(), page.getTotalPages());
    }
}
