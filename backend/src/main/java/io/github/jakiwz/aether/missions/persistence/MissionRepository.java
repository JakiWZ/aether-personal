package io.github.jakiwz.aether.missions.persistence;

import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

public interface MissionRepository extends JpaRepository<MissionEntity, Long> {

    @EntityGraph(attributePaths = {"originColony", "createdBy", "objectives"})
    List<MissionEntity> findAllByOrderByPlannedStartAtAscCodeAsc();

    @EntityGraph(attributePaths = {"originColony", "createdBy", "objectives"})
    Optional<MissionEntity> findByCode(String code);

    boolean existsByCode(String code);
}
