package io.github.jakiwz.aether.fleet.domain;

import io.github.jakiwz.aether.fleet.persistence.AssetEntity;
import io.github.jakiwz.aether.fleet.persistence.AssetRepository;
import io.github.jakiwz.aether.fleet.persistence.AssetTypeEntity;
import io.github.jakiwz.aether.shared.error.ResourceNotFoundException;
import java.util.Locale;
import org.jspecify.annotations.Nullable;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Read side of the fleet catalogue (TIT-301). Vehicles are the assets whose type has category
 * {@code VEHICLE}; out of service and decommissioned vehicles stay in the catalogue (BR-010).
 */
@Service
@Transactional(readOnly = true)
public class VehicleService {

    private final AssetRepository assets;

    VehicleService(AssetRepository assets) {
        this.assets = assets;
    }

    /**
     * Lists the vehicles ordered by code.
     *
     * @param status only the vehicles in this status, or {@code null} for all
     */
    public Page<Vehicle> list(@Nullable AssetStatus status, int page, int size) {
        Pageable pageable = PageRequest.of(page, size, Sort.by("code"));
        Page<AssetEntity> entities = status == null
                ? assets.findByTypeCategory(AssetTypeEntity.VEHICLE_CATEGORY, pageable)
                : assets.findByTypeCategoryAndStatus(AssetTypeEntity.VEHICLE_CATEGORY, status, pageable);
        return entities.map(VehicleService::toDomain);
    }

    public Vehicle get(String code) {
        String normalised = code.strip().toUpperCase(Locale.ROOT);
        return assets.findByCodeAndTypeCategory(normalised, AssetTypeEntity.VEHICLE_CATEGORY)
                .map(VehicleService::toDomain)
                .orElseThrow(() -> new ResourceNotFoundException("Vehicle", code));
    }

    private static Vehicle toDomain(AssetEntity entity) {
        return new Vehicle(entity.getCode(), entity.getType().getCode(), entity.getType().getName(),
                entity.getManufacturer(), entity.getModel(), entity.getSerialNumber(), entity.getStatus(),
                entity.getCriticality(), entity.getColony().getCode(), entity.isActive(),
                entity.getCommissionedAt(), entity.getOperatingHours());
    }
}
