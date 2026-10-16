package io.github.jakiwz.aether.identity.persistence;

import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.Repository;
import org.springframework.data.repository.query.Param;

public interface UserAccountRepository extends Repository<UserAccountEntity, Long> {

    Optional<UserAccountEntity> findByUsername(String username);

    /** Codes of the active roles currently assigned to the account (IAM-004). */
    @Query(value = """
            SELECT r.code
            FROM user_role ur
            JOIN app_role r ON r.id_role = ur.id_role
            WHERE ur.id_account = :accountId AND ur.revoked_at IS NULL AND r.active
            ORDER BY r.code""", nativeQuery = true)
    List<String> findRoleCodes(@Param("accountId") long accountId);

    /** Codes of the permissions granted by those roles (IAM-005). */
    @Query(value = """
            SELECT DISTINCT p.code
            FROM user_role ur
            JOIN app_role r ON r.id_role = ur.id_role
            JOIN role_permission rp ON rp.id_role = r.id_role
            JOIN permission p ON p.id_permission = rp.id_permission
            WHERE ur.id_account = :accountId AND ur.revoked_at IS NULL AND r.active
            ORDER BY p.code""", nativeQuery = true)
    List<String> findPermissionCodes(@Param("accountId") long accountId);

    @Query(value = "SELECT first_name || ' ' || last_name FROM person WHERE id_person = :personId",
            nativeQuery = true)
    Optional<String> findPersonName(@Param("personId") long personId);
}
