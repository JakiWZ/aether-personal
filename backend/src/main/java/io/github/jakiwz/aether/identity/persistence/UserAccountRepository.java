package io.github.jakiwz.aether.identity.persistence;

import java.util.Optional;
import org.springframework.data.repository.Repository;

public interface UserAccountRepository extends Repository<UserAccountEntity, Long> {

    Optional<UserAccountEntity> findByUsername(String username);
}
