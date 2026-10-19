package io.github.jakiwz.aether.incidents.persistence;

import org.springframework.data.repository.Repository;

public interface IncidentEventRepository extends Repository<IncidentEventEntity, Long> {

    IncidentEventEntity save(IncidentEventEntity event);
}
