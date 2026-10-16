package io.github.jakiwz.aether.missions.persistence;

import java.util.Optional;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

public interface MissionRepository extends JpaRepository<MissionEntity, Long> {

    /** Objectives are batch-loaded per page (see {@link MissionEntity}), never fetched with the limit. */
    @EntityGraph(attributePaths = {"originColony", "createdBy"})
    Page<MissionEntity> findAllBy(Pageable pageable);

    @EntityGraph(attributePaths = {"originColony", "createdBy", "objectives"})
    Optional<MissionEntity> findByCode(String code);

    boolean existsByCode(String code);
}
