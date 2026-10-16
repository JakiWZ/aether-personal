package io.github.jakiwz.aether.missions.persistence;

import org.springframework.data.jpa.repository.JpaRepository;

public interface MissionStatusHistoryRepository extends JpaRepository<MissionStatusHistoryEntity, Long> {
}
