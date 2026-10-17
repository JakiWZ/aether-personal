package io.github.jakiwz.aether.audit.persistence;

import java.util.Optional;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.Repository;

/**
 * Append-only access to the audit trail: there is no update or delete (BR-010, BR-012).
 * The account lookup is native so that this feature does not depend on {@code identity};
 * {@code {h-schema}} because Hibernate's default schema does not apply to native SQL.
 */
public interface AuditEventRepository extends Repository<AuditEventEntity, Long> {

    AuditEventEntity save(AuditEventEntity event);

    @Query(value = "SELECT id_account FROM {h-schema}user_account WHERE username = :username", nativeQuery = true)
    Optional<Long> findAccountId(String username);
}
