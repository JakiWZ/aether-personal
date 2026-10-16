package io.github.jakiwz.aether.colonies.persistence;

import io.github.jakiwz.aether.colonies.domain.ColonyStatus;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.LocalDate;
import java.time.OffsetDateTime;
import org.jspecify.annotations.Nullable;

/**
 * Mapping of {@code aether.colony} (V2). Only the columns the application reads are mapped;
 * the schema is owned by Flyway and validated by Hibernate at startup.
 */
@Entity
@Table(name = "colony")
public class ColonyEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_colony")
    private Long id;

    @Column(nullable = false, unique = true, length = 30)
    private String code;

    @Column(nullable = false, length = 150)
    private String name;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 30)
    private ColonyStatus status;

    @Column(nullable = false)
    private boolean active;

    @Column(name = "max_population")
    private @Nullable Integer maxPopulation;

    @Column(name = "established_at")
    private @Nullable LocalDate establishedAt;

    @Column(name = "deleted_at")
    private @Nullable OffsetDateTime deletedAt;

    protected ColonyEntity() {
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

    public ColonyStatus getStatus() {
        return status;
    }

    public boolean isActive() {
        return active;
    }

    public @Nullable Integer getMaxPopulation() {
        return maxPopulation;
    }

    public @Nullable LocalDate getEstablishedAt() {
        return establishedAt;
    }

    public @Nullable OffsetDateTime getDeletedAt() {
        return deletedAt;
    }
}
