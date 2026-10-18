package io.github.jakiwz.aether.inventory.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import org.hibernate.annotations.Immutable;

/**
 * Mapping of {@code aether.unit_of_measure} (V2): reference data, read only.
 */
@Entity
@Immutable
@Table(name = "unit_of_measure")
public class UnitOfMeasureEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_unit")
    private Long id;

    @Column(nullable = false, unique = true, length = 20)
    private String code;

    @Column(nullable = false, length = 100)
    private String name;

    @Column(nullable = false, length = 20)
    private String symbol;

    @Column(name = "quantity_type", nullable = false, length = 40)
    private String quantityType;

    protected UnitOfMeasureEntity() {
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

    public String getSymbol() {
        return symbol;
    }

    public String getQuantityType() {
        return quantityType;
    }
}
