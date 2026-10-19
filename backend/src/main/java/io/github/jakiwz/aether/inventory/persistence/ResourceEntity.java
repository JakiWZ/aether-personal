package io.github.jakiwz.aether.inventory.persistence;

import io.github.jakiwz.aether.inventory.domain.ResourceCategory;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import java.time.OffsetDateTime;
import org.jspecify.annotations.Nullable;

/**
 * Mapping of {@code aether.resource} (V4). {@code created_at} is left to the database default;
 * {@code updated_at} is set on every change of the activity flag.
 */
@Entity
@Table(name = "resource")
public class ResourceEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_resource")
    private Long id;

    @Column(nullable = false, unique = true, length = 50, updatable = false)
    private String code;

    @Column(nullable = false, length = 150)
    private String name;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 60)
    private ResourceCategory category;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "id_unit", nullable = false)
    private UnitOfMeasureEntity unit;

    @Column(nullable = false)
    private boolean critical;

    @Column(nullable = false)
    private boolean active;

    @Column(name = "shelf_life_days")
    private @Nullable Integer shelfLifeDays;

    @Column(name = "updated_at", nullable = false)
    private OffsetDateTime updatedAt;

    protected ResourceEntity() {
        // for JPA
    }

    public ResourceEntity(String code, String name, ResourceCategory category, UnitOfMeasureEntity unit,
            boolean critical, @Nullable Integer shelfLifeDays, OffsetDateTime now) {
        this.code = code;
        this.name = name;
        this.category = category;
        this.unit = unit;
        this.critical = critical;
        this.active = true;
        this.shelfLifeDays = shelfLifeDays;
        this.updatedAt = now;
    }

    /** Activates or deactivates the resource; its stock, movements and history are untouched (BR-010). */
    public void setActive(boolean active, OffsetDateTime now) {
        this.active = active;
        this.updatedAt = now;
    }

    public Long getId() {
        return id;
    }

    public String getCode() {
        return code;
    }

    public String getName() {
        return name;
    }

    public ResourceCategory getCategory() {
        return category;
    }

    public UnitOfMeasureEntity getUnit() {
        return unit;
    }

    public boolean isCritical() {
        return critical;
    }

    public boolean isActive() {
        return active;
    }

    public @Nullable Integer getShelfLifeDays() {
        return shelfLifeDays;
    }

    public OffsetDateTime getUpdatedAt() {
        return updatedAt;
    }
}
