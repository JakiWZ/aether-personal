package io.github.jakiwz.aether.identity.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

/** Read-only mapping of {@code aether.user_account} (V3), used to attribute writes. */
@Entity
@Table(name = "user_account")
public class UserAccountEntity {

    @Id
    @Column(name = "id_account")
    private Long id;

    @Column(nullable = false, unique = true, length = 100, insertable = false, updatable = false)
    private String username;

    protected UserAccountEntity() {
        // for JPA
    }

    public Long getId() {
        return id;
    }

    public String getUsername() {
        return username;
    }
}
