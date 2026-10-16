package io.github.jakiwz.aether.colonies.domain;

import java.time.LocalDate;
import org.jspecify.annotations.Nullable;

/**
 * A Martian base as seen by the rest of the application; the persistence model stays internal.
 */
public record Colony(
        String code,
        String name,
        ColonyStatus status,
        boolean active,
        @Nullable Integer maxPopulation,
        @Nullable LocalDate establishedAt) {
}
