package io.github.jakiwz.aether.inventory.domain;

import io.github.jakiwz.aether.audit.domain.AuditAction;
import io.github.jakiwz.aether.audit.domain.AuditTrail;
import io.github.jakiwz.aether.inventory.persistence.ResourceEntity;
import io.github.jakiwz.aether.inventory.persistence.ResourceRepository;
import io.github.jakiwz.aether.inventory.persistence.UnitOfMeasureEntity;
import io.github.jakiwz.aether.inventory.persistence.UnitOfMeasureRepository;
import io.github.jakiwz.aether.shared.error.BusinessRuleViolationException;
import io.github.jakiwz.aether.shared.error.ResourceNotFoundException;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.LinkedHashMap;
import java.util.Locale;
import java.util.Map;
import org.jspecify.annotations.Nullable;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Resource catalogue (ORI-401). Codes are stored upper case and checked for uniqueness before the
 * database unique constraint; a resource is never deleted, only deactivated (BR-010). Creations
 * and activity changes go to the audit trail (ADR-0014).
 */
@Service
@Transactional(readOnly = true)
public class ResourceService {

    private static final String AUDIT_ENTITY = "RESOURCE";

    private final ResourceRepository resources;
    private final UnitOfMeasureRepository units;
    private final AuditTrail audit;

    ResourceService(ResourceRepository resources, UnitOfMeasureRepository units, AuditTrail audit) {
        this.resources = resources;
        this.units = units;
        this.audit = audit;
    }

    /**
     * Lists the resources ordered by code.
     *
     * @param active {@code true} or {@code false} to keep only active or inactive resources, {@code null} for all
     */
    public Page<Resource> list(@Nullable Boolean active, int page, int size) {
        Pageable pageable = PageRequest.of(page, size, Sort.by("code"));
        Page<ResourceEntity> entities = active == null
                ? resources.findAllBy(pageable)
                : resources.findByActive(active, pageable);
        return entities.map(ResourceService::toDomain);
    }

    public Resource get(String code) {
        return toDomain(find(code));
    }

    /** Units of measure ordered by code, for the catalogue form. */
    public Page<UnitOfMeasure> units(int page, int size) {
        return units.findAllBy(PageRequest.of(page, size, Sort.by("code")))
                .map(u -> new UnitOfMeasure(u.getCode(), u.getName(), u.getSymbol(), u.getQuantityType()));
    }

    /** Adds an active resource to the catalogue. */
    @Transactional
    public Resource create(NewResource request) {
        String code = normaliseCode(request.code());
        if (resources.existsByCode(code)) {
            throw new BusinessRuleViolationException(InventoryErrorCode.RESOURCE_CODE_TAKEN,
                    "Resource code '%s' is already in use.".formatted(code));
        }
        String unitCode = normaliseCode(request.unitCode());
        UnitOfMeasureEntity unit = units.findByCode(unitCode)
                .orElseThrow(() -> new BusinessRuleViolationException(InventoryErrorCode.UNIT_OF_MEASURE_NOT_FOUND,
                        "Unit of measure '%s' does not exist.".formatted(unitCode)));

        ResourceEntity resource = resources.save(new ResourceEntity(code, request.name().strip(),
                request.category(), unit, request.critical(), request.shelfLifeDays(), now()));
        Map<String, Object> snapshot = new LinkedHashMap<>();
        snapshot.put("category", resource.getCategory());
        snapshot.put("unitCode", unit.getCode());
        snapshot.put("critical", resource.isCritical());
        snapshot.put("active", true);
        audit.record(AuditAction.RESOURCE_CREATED, AUDIT_ENTITY, code, snapshot);
        return toDomain(resource);
    }

    /**
     * Activates or deactivates a resource. Asking for the state it already has changes nothing and
     * records nothing.
     */
    @Transactional
    public Resource setActive(String code, boolean active) {
        ResourceEntity resource = find(code);
        if (resource.isActive() != active) {
            resource.setActive(active, now());
            audit.record(active ? AuditAction.RESOURCE_ACTIVATED : AuditAction.RESOURCE_DEACTIVATED,
                    AUDIT_ENTITY, resource.getCode(), Map.of("active", active));
        }
        return toDomain(resource);
    }

    private ResourceEntity find(String code) {
        return resources.findByCode(normaliseCode(code))
                .orElseThrow(() -> new ResourceNotFoundException("Resource", code));
    }

    private static OffsetDateTime now() {
        return OffsetDateTime.now(ZoneOffset.UTC);
    }

    private static String normaliseCode(String code) {
        return code.strip().toUpperCase(Locale.ROOT);
    }

    private static Resource toDomain(ResourceEntity entity) {
        UnitOfMeasureEntity unit = entity.getUnit();
        return new Resource(entity.getCode(), entity.getName(), entity.getCategory(), unit.getCode(),
                unit.getSymbol(), entity.isCritical(), entity.isActive(), entity.getShelfLifeDays());
    }
}
