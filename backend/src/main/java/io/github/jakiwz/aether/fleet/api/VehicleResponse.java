package io.github.jakiwz.aether.fleet.api;

import io.github.jakiwz.aether.fleet.domain.AssetCriticality;
import io.github.jakiwz.aether.fleet.domain.AssetStatus;
import io.github.jakiwz.aether.fleet.domain.Vehicle;
import io.swagger.v3.oas.annotations.media.Schema;
import java.math.BigDecimal;
import java.time.LocalDate;
import org.jspecify.annotations.Nullable;

@Schema(name = "Vehicle", description = "A rover, drone or shuttle of the fleet.")
public record VehicleResponse(
        @Schema(description = "Unique business code", example = "ROV-ARS-01") String code,
        @Schema(description = "Code of the vehicle type", example = "ROVER") String typeCode,
        @Schema(example = "Pressurised rover") String typeName,
        @Schema(nullable = true, example = "RedRock Mobility") @Nullable String manufacturer,
        @Schema(nullable = true, example = "Pathfinder X2") @Nullable String model,
        @Schema(nullable = true, example = "SN-RV-1001") @Nullable String serialNumber,
        @Schema(description = "Operational status") AssetStatus status,
        @Schema(description = "How much operations depend on the vehicle") AssetCriticality criticality,
        @Schema(description = "Code of the base where the vehicle is stationed", example = "ARS-01")
        String colonyCode,
        @Schema(description = "False for vehicles taken out of the fleet; their history is kept") boolean active,
        @Schema(description = "Date the vehicle entered service", nullable = true) @Nullable LocalDate commissionedAt,
        @Schema(description = "Total operating hours", example = "4120.50") BigDecimal operatingHours) {

    static VehicleResponse from(Vehicle vehicle) {
        return new VehicleResponse(vehicle.code(), vehicle.typeCode(), vehicle.typeName(), vehicle.manufacturer(),
                vehicle.model(), vehicle.serialNumber(), vehicle.status(), vehicle.criticality(),
                vehicle.colonyCode(), vehicle.active(), vehicle.commissionedAt(), vehicle.operatingHours());
    }
}
