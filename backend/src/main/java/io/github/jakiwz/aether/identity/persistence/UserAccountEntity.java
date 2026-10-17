package io.github.jakiwz.aether.identity.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.OffsetDateTime;
import org.jspecify.annotations.Nullable;

/**
 * Mapping of {@code aether.user_account} (V3): identity of the author of a write (BR-012) and the
 * login state the authentication flow keeps up to date (IAM-002, IAM-008). Accounts are created
 * and disabled elsewhere (IAM-001, IAM-003), never deleted.
 */
@Entity
@Table(name = "user_account")
public class UserAccountEntity {

    @Id
    @Column(name = "id_account")
    private Long id;

    @Column(name = "id_person", nullable = false, insertable = false, updatable = false)
    private Long personId;

    @Column(nullable = false, unique = true, length = 100, insertable = false, updatable = false)
    private String username;

    @Column(name = "password_hash", nullable = false, length = 255)
    private String passwordHash;

    @Column(name = "account_status", nullable = false, length = 30, insertable = false, updatable = false)
    private String accountStatus;

    @Column(name = "failed_login_count", nullable = false)
    private int failedLoginCount;

    @Column(name = "locked_until")
    private @Nullable OffsetDateTime lockedUntil;

    @Column(name = "last_login_at")
    private @Nullable OffsetDateTime lastLoginAt;

    @Column(name = "updated_at", nullable = false)
    private OffsetDateTime updatedAt;

    protected UserAccountEntity() {
        // for JPA
    }

    public Long getId() {
        return id;
    }

    public Long getPersonId() {
        return personId;
    }

    public String getUsername() {
        return username;
    }

    public String getPasswordHash() {
        return passwordHash;
    }

    /** {@code ACTIVE}, {@code LOCKED}, {@code DISABLED} or {@code PENDING} ({@code ck_account_status}). */
    public String getAccountStatus() {
        return accountStatus;
    }

    public int getFailedLoginCount() {
        return failedLoginCount;
    }

    public @Nullable OffsetDateTime getLockedUntil() {
        return lockedUntil;
    }

    public @Nullable OffsetDateTime getLastLoginAt() {
        return lastLoginAt;
    }

    /** A failed attempt; after {@code maxAttempts} in a row the account is locked until {@code lockUntil}. */
    public void recordFailedLogin(OffsetDateTime now, int maxAttempts, OffsetDateTime lockUntil) {
        failedLoginCount++;
        if (failedLoginCount >= maxAttempts) {
            lockedUntil = lockUntil;
            failedLoginCount = 0;
        }
        updatedAt = now;
    }

    public void recordSuccessfulLogin(OffsetDateTime now) {
        failedLoginCount = 0;
        lockedUntil = null;
        lastLoginAt = now;
        updatedAt = now;
    }

    /** Replaces a hash made with weaker parameters, on a successful login (OWASP password storage). */
    public void upgradePasswordHash(String newHash, OffsetDateTime now) {
        passwordHash = newHash;
        updatedAt = now;
    }
}
