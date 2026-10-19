package io.github.jakiwz.aether.fleet.persistence;

import io.github.jakiwz.aether.fleet.domain.AssetStatus;
import java.util.Optional;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

public interface AssetRepository extends JpaRepository<AssetEntity, Long> {

    @EntityGraph(attributePaths = {"type", "colony"})
    Page<AssetEntity> findByTypeCategory(String category, Pageable pageable);

    @EntityGraph(attributePaths = {"type", "colony"})
    Page<AssetEntity> findByTypeCategoryAndStatus(String category, AssetStatus status, Pageable pageable);

    @EntityGraph(attributePaths = {"type", "colony"})
    Optional<AssetEntity> findByCodeAndTypeCategory(String code, String category);
}
