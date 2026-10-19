package io.github.jakiwz.aether.fleet.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import org.hibernate.annotations.Immutable;

/**
 * Mapping of {@code aether.asset_type} (V5): reference data, read only.
 */
@Entity
@Immutable
@Table(name = "asset_type")
public class AssetTypeEntity {

    /** Category of the types that make up the fleet; the other categories are fixed plant. */
    public static final String VEHICLE_CATEGORY = "VEHICLE";

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_asset_type")
    private Long id;

    @Column(nullable = false, unique = true, length = 50)
    private String code;

    @Column(nullable = false, length = 150)
    private String name;

    @Column(nullable = false, length = 60)
    private String category;

    protected AssetTypeEntity() {
        // for JPA
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

    public String getCategory() {
        return category;
    }
}
