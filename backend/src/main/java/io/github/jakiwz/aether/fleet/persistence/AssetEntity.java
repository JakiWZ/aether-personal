package io.github.jakiwz.aether.fleet.persistence;

import io.github.jakiwz.aether.colonies.persistence.ColonyEntity;
import io.github.jakiwz.aether.fleet.domain.AssetCriticality;
import io.github.jakiwz.aether.fleet.domain.AssetStatus;
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
import java.math.BigDecimal;
import java.time.LocalDate;
import org.jspecify.annotations.Nullable;

/**
 * Mapping of {@code aether.asset} (V5). Only the columns the application reads are mapped;
 * the schema is owned by Flyway and validated by Hibernate at startup.
 */
@Entity
@Table(name = "asset")
public class AssetEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_asset")
    private Long id;

    @Column(nullable = false, unique = true, length = 60)
    private String code;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "id_asset_type", nullable = false)
    private AssetTypeEntity type;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "id_colony", nullable = false)
    private ColonyEntity colony;

    @Column(name = "serial_number", unique = true, length = 120)
    private @Nullable String serialNumber;

    @Column(length = 120)
    private @Nullable String manufacturer;

    @Column(length = 120)
    private @Nullable String model;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private AssetCriticality criticality;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 30)
    private AssetStatus status;

    @Column(name = "commissioned_at")
    private @Nullable LocalDate commissionedAt;

    @Column(name = "operating_hours", nullable = false, precision = 14, scale = 2)
    private BigDecimal operatingHours;

    @Column(nullable = false)
    private boolean active;

    protected AssetEntity() {
        // for JPA
    }

    public Long getId() {
        return id;
    }

    public String getCode() {
        return code;
    }

    public AssetTypeEntity getType() {
        return type;
    }

    public ColonyEntity getColony() {
        return colony;
    }

    public @Nullable String getSerialNumber() {
        return serialNumber;
    }

    public @Nullable String getManufacturer() {
        return manufacturer;
    }

    public @Nullable String getModel() {
        return model;
    }

    public AssetCriticality getCriticality() {
        return criticality;
    }

    public AssetStatus getStatus() {
        return status;
    }

    public @Nullable LocalDate getCommissionedAt() {
        return commissionedAt;
    }

    public BigDecimal getOperatingHours() {
        return operatingHours;
    }

    public boolean isActive() {
        return active;
    }
}
