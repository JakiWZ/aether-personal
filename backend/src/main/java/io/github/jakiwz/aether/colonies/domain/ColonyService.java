package io.github.jakiwz.aether.colonies.domain;

import io.github.jakiwz.aether.colonies.persistence.ColonyEntity;
import io.github.jakiwz.aether.colonies.persistence.ColonyRepository;
import java.util.List;
import org.jspecify.annotations.Nullable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Read side of the base registry (ARES-101). Soft-deleted bases are never listed; inactive ones are.
 */
@Service
@Transactional(readOnly = true)
public class ColonyService {

    private final ColonyRepository repository;

    ColonyService(ColonyRepository repository) {
        this.repository = repository;
    }

    /**
     * Lists the bases ordered by code.
     *
     * @param active {@code true} or {@code false} to keep only active or inactive bases, {@code null} for all
     */
    public List<Colony> list(@Nullable Boolean active) {
        List<ColonyEntity> entities = active == null
                ? repository.findByDeletedAtIsNullOrderByCodeAsc()
                : repository.findByDeletedAtIsNullAndActiveOrderByCodeAsc(active);
        return entities.stream().map(ColonyService::toDomain).toList();
    }

    private static Colony toDomain(ColonyEntity entity) {
        return new Colony(entity.getCode(), entity.getName(), entity.getStatus(), entity.isActive(),
                entity.getMaxPopulation(), entity.getEstablishedAt());
    }
}
