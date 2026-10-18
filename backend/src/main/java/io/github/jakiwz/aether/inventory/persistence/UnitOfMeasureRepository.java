package io.github.jakiwz.aether.inventory.persistence;

import java.util.Optional;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

public interface UnitOfMeasureRepository extends JpaRepository<UnitOfMeasureEntity, Long> {

    Page<UnitOfMeasureEntity> findAllBy(Pageable pageable);

    Optional<UnitOfMeasureEntity> findByCode(String code);
}
