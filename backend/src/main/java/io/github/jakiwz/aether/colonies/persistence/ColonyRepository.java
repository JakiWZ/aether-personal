package io.github.jakiwz.aether.colonies.persistence;

import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ColonyRepository extends JpaRepository<ColonyEntity, Long> {

    List<ColonyEntity> findByDeletedAtIsNullOrderByCodeAsc();

    List<ColonyEntity> findByDeletedAtIsNullAndActiveOrderByCodeAsc(boolean active);
}
