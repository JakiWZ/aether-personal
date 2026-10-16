package io.github.jakiwz.aether.colonies.domain;

import io.github.jakiwz.aether.colonies.persistence.ColonyEntity;
import io.github.jakiwz.aether.colonies.persistence.ColonyRepository;
import org.jspecify.annotations.Nullable;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
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
    public Page<Colony> list(@Nullable Boolean active, int page, int size) {
        Pageable pageable = PageRequest.of(page, size, Sort.by("code"));
        Page<ColonyEntity> entities = active == null
                ? repository.findByDeletedAtIsNull(pageable)
                : repository.findByDeletedAtIsNullAndActive(active, pageable);
        return entities.map(ColonyService::toDomain);
    }

    private static Colony toDomain(ColonyEntity entity) {
        return new Colony(entity.getCode(), entity.getName(), entity.getStatus(), entity.isActive(),
                entity.getMaxPopulation(), entity.getEstablishedAt());
    }
}
