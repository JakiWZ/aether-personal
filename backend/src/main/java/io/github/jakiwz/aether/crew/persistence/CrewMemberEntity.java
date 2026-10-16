package io.github.jakiwz.aether.crew.persistence;

import io.github.jakiwz.aether.colonies.persistence.ColonyEntity;
import io.github.jakiwz.aether.crew.domain.CrewStatus;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.OneToOne;
import jakarta.persistence.Table;
import org.jspecify.annotations.Nullable;

/**
 * Mapping of {@code aether.crew_member} (V3). Audit timestamps are left to the database defaults.
 */
@Entity
@Table(name = "crew_member")
public class CrewMemberEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id_crew_member")
    private Long id;

    @OneToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "id_person", nullable = false, unique = true)
    private PersonEntity person;

    @Column(name = "employee_code", nullable = false, unique = true, length = 40)
    private String employeeCode;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "id_home_colony")
    private @Nullable ColonyEntity homeColony;

    @Column(name = "operational_role", nullable = false, length = 80)
    private String operationalRole;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 30)
    private CrewStatus status;

    protected CrewMemberEntity() {
        // for JPA
    }

    public CrewMemberEntity(PersonEntity person, String employeeCode, @Nullable ColonyEntity homeColony,
            String operationalRole, CrewStatus status) {
        this.person = person;
        this.employeeCode = employeeCode;
        this.homeColony = homeColony;
        this.operationalRole = operationalRole;
        this.status = status;
    }

    public Long getId() {
        return id;
    }

    public PersonEntity getPerson() {
        return person;
    }

    public String getEmployeeCode() {
        return employeeCode;
    }

    public @Nullable ColonyEntity getHomeColony() {
        return homeColony;
    }

    public String getOperationalRole() {
        return operationalRole;
    }

    public CrewStatus getStatus() {
        return status;
    }
}
