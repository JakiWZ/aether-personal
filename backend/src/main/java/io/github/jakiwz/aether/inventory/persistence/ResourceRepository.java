package io.github.jakiwz.aether.inventory.persistence;

import java.util.Optional;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ResourceRepository extends JpaRepository<ResourceEntity, Long> {

    @EntityGraph(attributePaths = "unit")
    Page<ResourceEntity> findAllBy(Pageable pageable);

    @EntityGraph(attributePaths = "unit")
    Page<ResourceEntity> findByActive(boolean active, Pageable pageable);

    @EntityGraph(attributePaths = "unit")
    Optional<ResourceEntity> findByCode(String code);

    boolean existsByCode(String code);
}
