package io.github.jakiwz.aether.crew.persistence;

import org.springframework.data.jpa.repository.JpaRepository;

public interface PersonRepository extends JpaRepository<PersonEntity, Long> {

    boolean existsByEmail(String email);
}
