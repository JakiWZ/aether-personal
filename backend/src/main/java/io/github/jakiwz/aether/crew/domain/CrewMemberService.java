package io.github.jakiwz.aether.crew.domain;

import io.github.jakiwz.aether.audit.domain.AuditAction;
import io.github.jakiwz.aether.audit.domain.AuditTrail;
import io.github.jakiwz.aether.colonies.persistence.ColonyEntity;
import io.github.jakiwz.aether.colonies.persistence.ColonyRepository;
import io.github.jakiwz.aether.crew.persistence.CrewMemberEntity;
import io.github.jakiwz.aether.crew.persistence.CrewMemberRepository;
import io.github.jakiwz.aether.crew.persistence.PersonEntity;
import io.github.jakiwz.aether.crew.persistence.PersonRepository;
import io.github.jakiwz.aether.shared.error.BusinessRuleViolationException;
import io.github.jakiwz.aether.shared.error.ResourceNotFoundException;
import java.util.LinkedHashMap;
import java.util.Locale;
import java.util.Map;
import org.jspecify.annotations.Nullable;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Crew registry (ARES-103). Business keys are normalised (code upper case, email lower case)
 * before the uniqueness checks; the database unique constraints remain the last line of defence.
 * Registrations go to the audit trail without personal data (ADR-0014).
 */
@Service
@Transactional(readOnly = true)
public class CrewMemberService {

    private final CrewMemberRepository crewMembers;
    private final PersonRepository people;
    private final ColonyRepository colonies;
    private final AuditTrail audit;

    CrewMemberService(CrewMemberRepository crewMembers, PersonRepository people, ColonyRepository colonies,
            AuditTrail audit) {
        this.crewMembers = crewMembers;
        this.people = people;
        this.colonies = colonies;
        this.audit = audit;
    }

    /** Crew members ordered by employee code. */
    public Page<CrewMember> list(int page, int size) {
        return crewMembers.findAllBy(PageRequest.of(page, size, Sort.by("employeeCode")))
                .map(CrewMemberService::toDomain);
    }

    public CrewMember get(String employeeCode) {
        return crewMembers.findByEmployeeCode(normaliseCode(employeeCode))
                .map(CrewMemberService::toDomain)
                .orElseThrow(() -> new ResourceNotFoundException("Crew member", employeeCode));
    }

    /** Registers the person and their crew profile in one transaction. */
    @Transactional
    public CrewMember register(NewCrewMember request) {
        String code = normaliseCode(request.employeeCode());
        String email = normaliseEmail(request.email());

        if (crewMembers.existsByEmployeeCode(code)) {
            throw new BusinessRuleViolationException(CrewErrorCode.CREW_MEMBER_CODE_TAKEN,
                    "Crew member code '%s' is already in use.".formatted(code));
        }
        if (email != null && people.existsByEmail(email)) {
            throw new BusinessRuleViolationException(CrewErrorCode.PERSON_EMAIL_TAKEN,
                    "Email '%s' is already registered.".formatted(email));
        }
        ColonyEntity homeColony = resolveHomeColony(request.homeColonyCode());

        PersonEntity person = people.save(new PersonEntity(
                request.firstName().strip(), request.lastName().strip(), email));
        CrewMemberEntity crewMember = crewMembers.save(new CrewMemberEntity(
                person, code, homeColony, request.operationalRole().strip(), request.status()));
        Map<String, Object> snapshot = new LinkedHashMap<>();
        snapshot.put("status", request.status());
        snapshot.put("homeColonyCode", homeColony == null ? null : homeColony.getCode());
        audit.record(AuditAction.CREW_MEMBER_REGISTERED, "CREW_MEMBER", code, snapshot);
        return toDomain(crewMember);
    }

    private @Nullable ColonyEntity resolveHomeColony(@Nullable String colonyCode) {
        if (colonyCode == null || colonyCode.isBlank()) {
            return null;
        }
        ColonyEntity colony = colonies.findByCodeAndDeletedAtIsNull(colonyCode.strip())
                .orElseThrow(() -> new BusinessRuleViolationException(CrewErrorCode.HOME_COLONY_NOT_FOUND,
                        "Base '%s' does not exist.".formatted(colonyCode.strip())));
        if (!colony.isActive()) {
            throw new BusinessRuleViolationException(CrewErrorCode.HOME_COLONY_INACTIVE,
                    "Base '%s' is not active and cannot receive crew members.".formatted(colony.getCode()));
        }
        return colony;
    }

    private static String normaliseCode(String code) {
        return code.strip().toUpperCase(Locale.ROOT);
    }

    private static @Nullable String normaliseEmail(@Nullable String email) {
        return email == null || email.isBlank() ? null : email.strip().toLowerCase(Locale.ROOT);
    }

    private static CrewMember toDomain(CrewMemberEntity entity) {
        PersonEntity person = entity.getPerson();
        ColonyEntity colony = entity.getHomeColony();
        return new CrewMember(entity.getEmployeeCode(), person.getFirstName(), person.getLastName(),
                person.getEmail(), entity.getOperationalRole(), entity.getStatus(),
                colony == null ? null : colony.getCode());
    }
}
