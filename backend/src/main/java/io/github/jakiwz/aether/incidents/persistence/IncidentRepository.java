package io.github.jakiwz.aether.incidents.persistence;

import java.util.Optional;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

public interface IncidentRepository extends JpaRepository<IncidentEntity, Long> {

    @EntityGraph(attributePaths = {"colony", "reportedBy"})
    Page<IncidentEntity> findAllBy(Pageable pageable);

    @EntityGraph(attributePaths = {"colony", "reportedBy"})
    Optional<IncidentEntity> findByCode(String code);

    boolean existsByCode(String code);

    /** Next number for a system-assigned incident code (V17). */
    @Query(value = "SELECT {h-schema}next_incident_number()", nativeQuery = true)
    long nextCodeNumber();
}
