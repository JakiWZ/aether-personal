package io.github.jakiwz.aether.crew.persistence;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import org.jspecify.annotations.Nullable;

/**
 * Mapping of {@code aether.person} (V3): personal data, kept apart from the crew profile.
 * Audit timestamps are left to the database defaults.
 */
@Entity
@Table(name = "person")
public class PersonEntity {

    private static final String ACTIVE = "ACTIVE";

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_person")
    private Long id;

    @Column(name = "first_name", nullable = false, length = 100)
    private String firstName;

    @Column(name = "last_name", nullable = false, length = 100)
    private String lastName;

    @Column(length = 200)
    private @Nullable String email;

    @Column(nullable = false, length = 30)
    private String status;

    protected PersonEntity() {
        // for JPA
    }

    public PersonEntity(String firstName, String lastName, @Nullable String email) {
        this.firstName = firstName;
        this.lastName = lastName;
        this.email = email;
        this.status = ACTIVE;
    }

    public Long getId() {
        return id;
    }

    public String getFirstName() {
        return firstName;
    }

    public String getLastName() {
        return lastName;
    }

    public @Nullable String getEmail() {
        return email;
    }
}
