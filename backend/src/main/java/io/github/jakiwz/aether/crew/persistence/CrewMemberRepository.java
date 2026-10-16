package io.github.jakiwz.aether.crew.persistence;

import java.util.Optional;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

public interface CrewMemberRepository extends JpaRepository<CrewMemberEntity, Long> {

    @EntityGraph(attributePaths = {"person", "homeColony"})
    Page<CrewMemberEntity> findAllBy(Pageable pageable);

    @EntityGraph(attributePaths = {"person", "homeColony"})
    Optional<CrewMemberEntity> findByEmployeeCode(String employeeCode);

    boolean existsByEmployeeCode(String employeeCode);
}
