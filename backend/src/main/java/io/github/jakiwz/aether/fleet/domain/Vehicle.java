package io.github.jakiwz.aether.fleet.domain;

import java.math.BigDecimal;
import java.time.LocalDate;
import org.jspecify.annotations.Nullable;

/**
 * A rover, drone or shuttle of the fleet (TIT-301). {@code code} is the business key; the base is
 * where the vehicle is currently stationed.
 */
public record Vehicle(
        String code,
        String typeCode,
        String typeName,
        @Nullable String manufacturer,
        @Nullable String model,
        @Nullable String serialNumber,
        AssetStatus status,
        AssetCriticality criticality,
        String colonyCode,
        boolean active,
        @Nullable LocalDate commissionedAt,
        BigDecimal operatingHours) {
}
