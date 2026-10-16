package io.github.jakiwz.aether.colonies.persistence;

import java.util.Optional;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ColonyRepository extends JpaRepository<ColonyEntity, Long> {

    Page<ColonyEntity> findByDeletedAtIsNull(Pageable pageable);

    Page<ColonyEntity> findByDeletedAtIsNullAndActive(boolean active, Pageable pageable);

    Optional<ColonyEntity> findByCodeAndDeletedAtIsNull(String code);
}
