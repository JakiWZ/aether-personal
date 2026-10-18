package io.github.jakiwz.aether;

import static com.tngtech.archunit.base.DescribedPredicate.not;
import static com.tngtech.archunit.core.domain.JavaClass.Predicates.resideInAPackage;
import static com.tngtech.archunit.core.domain.JavaClass.Predicates.resideInAnyPackage;
import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.classes;
import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.fields;
import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.methods;
import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.noClasses;
import static com.tngtech.archunit.library.Architectures.layeredArchitecture;
import static com.tngtech.archunit.library.dependencies.SlicesRuleDefinition.slices;

import com.tngtech.archunit.core.domain.JavaClasses;
import com.tngtech.archunit.core.importer.ClassFileImporter;
import com.tngtech.archunit.core.importer.ImportOption;
import io.github.jakiwz.aether.shared.validation.PlainText;
import jakarta.persistence.Entity;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import java.util.Map;
import java.util.Set;
import java.util.TreeSet;
import org.junit.jupiter.api.Test;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * The structure rules of CLAUDE.md, checked on every build so a review does not have to:
 * package by feature, thin controllers on DTOs, persistence behind the domain, no feature cycles.
 */
class ArchitectureTest {

    private static final String ROOT = "io.github.jakiwz.aether";

    /**
     * Which other features each feature may use. JPA associations need the referenced entity
     * (a mission's origin colony, its author account), so a feature may reach another feature's
     * {@code domain} and {@code persistence}, never its {@code api}. A new edge is a design decision:
     * add it here in the same pull request that needs it.
     */
    private static final Map<String, Set<String>> ALLOWED_FEATURE_DEPENDENCIES = Map.of(
            "audit", Set.of(),
            "colonies", Set.of(),
            "crew", Set.of("audit", "colonies"),
            "fleet", Set.of("colonies"),
            "identity", Set.of("audit"),
            "incidents", Set.of("audit", "colonies", "identity"),
            "inventory", Set.of("audit"),
            "missions", Set.of("audit", "colonies", "identity"));

    private static final JavaClasses PRODUCTION = new ClassFileImporter()
            .withImportOption(ImportOption.Predefined.DO_NOT_INCLUDE_TESTS)
            .importPackages(ROOT);

    @Test
    void layersInsideEveryFeaturePointInwards() {
        layeredArchitecture().consideringOnlyDependenciesInLayers()
                .layer("Api").definedBy(ROOT + ".*.api..")
                .layer("Domain").definedBy(ROOT + ".*.domain..")
                .layer("Persistence").definedBy(ROOT + ".*.persistence..")
                .whereLayer("Api").mayNotBeAccessedByAnyLayer()
                .whereLayer("Domain").mayOnlyBeAccessedByLayers("Api", "Persistence")
                .whereLayer("Persistence").mayOnlyBeAccessedByLayers("Domain")
                .check(PRODUCTION);
    }

    @Test
    void featuresDoNotDependOnEachOtherInCycles() {
        slices().matching(ROOT + ".(*)..").should().beFreeOfCycles().check(PRODUCTION);
    }

    @Test
    void featuresDoNotCallEachOthersApi() {
        slices().matching(ROOT + ".(*).api..").should().notDependOnEachOther().check(PRODUCTION);
    }

    @Test
    void featuresOnlyUseTheFeaturesTheyAreAllowedTo() {
        for (var entry : ALLOWED_FEATURE_DEPENDENCIES.entrySet()) {
            Set<String> forbidden = new TreeSet<>(ALLOWED_FEATURE_DEPENDENCIES.keySet());
            forbidden.remove(entry.getKey());
            forbidden.removeAll(entry.getValue());
            if (forbidden.isEmpty()) {
                continue;
            }
            noClasses().that().resideInAPackage(ROOT + "." + entry.getKey() + "..")
                    .should().dependOnClassesThat(resideInAnyPackage(
                            forbidden.stream().map(f -> ROOT + "." + f + "..").toArray(String[]::new)))
                    .because("feature dependencies are listed in ALLOWED_FEATURE_DEPENDENCIES")
                    .check(PRODUCTION);
        }
    }

    @Test
    void everyFeatureIsListedInTheAllowedDependencies() {
        Set<String> features = new TreeSet<>();
        PRODUCTION.stream()
                .map(c -> c.getPackageName())
                .filter(p -> p.startsWith(ROOT + "."))
                .map(p -> p.substring(ROOT.length() + 1).split("\\.")[0])
                .filter(f -> !f.equals("shared"))
                .forEach(features::add);
        org.assertj.core.api.Assertions.assertThat(ALLOWED_FEATURE_DEPENDENCIES.keySet())
                .containsExactlyInAnyOrderElementsOf(features);
    }

    @Test
    void sharedCodeDoesNotDependOnAnyFeature() {
        noClasses().that().resideInAPackage(ROOT + ".shared..")
                .should().dependOnClassesThat(resideInAPackage(ROOT + "..")
                        .and(not(resideInAPackage(ROOT + ".shared.."))))
                .check(PRODUCTION);
    }

    @Test
    void controllersLiveInAnApiPackage() {
        classes().that().areAnnotatedWith(RestController.class)
                .should().resideInAnyPackage(ROOT + ".*.api..", ROOT + ".shared.error..")
                .check(PRODUCTION);
    }

    @Test
    void theApiNeverExposesJpaEntities() {
        noClasses().that().resideInAPackage(ROOT + ".*.api..")
                .should().dependOnClassesThat().areAnnotatedWith(Entity.class)
                .check(PRODUCTION);
    }

    @Test
    void requestAndResponseBodiesAreRecords() {
        classes().that().resideInAPackage(ROOT + ".*.api..")
                .and().haveSimpleNameEndingWith("Request").or().haveSimpleNameEndingWith("Response")
                .should().beAssignableTo(Record.class)
                .check(PRODUCTION);
    }

    /** OWASP API4:2023: every text a client sends has a maximum length (a pattern bounds it too). */
    @Test
    void requestTextIsBoundedInLength() {
        fields().that().areDeclaredInClassesThat().haveSimpleNameEndingWith("Request")
                .and().haveRawType(String.class)
                .should().beAnnotatedWith(Size.class).orShould().beAnnotatedWith(Pattern.class)
                .check(PRODUCTION);
    }

    /** No control or bidi characters reach the database, logs or other users (a pattern excludes them too). */
    @Test
    void requestTextIsPlain() {
        fields().that().areDeclaredInClassesThat().haveSimpleNameEndingWith("Request")
                .and().haveRawType(String.class)
                .should().beAnnotatedWith(PlainText.class).orShould().beAnnotatedWith(Pattern.class)
                .check(PRODUCTION);
    }

    /**
     * OWASP API5:2023 (broken function level authorization): every endpoint states the permission it
     * needs, so a new one cannot ship open by omission. {@code permitAll()} has to be written out too.
     */
    @Test
    void everyEndpointDeclaresItsPermission() {
        methods().that().areDeclaredInClassesThat().areAnnotatedWith(RestController.class)
                .and().areDeclaredInClassesThat().resideInAPackage(ROOT + ".*.api..")
                .and().areMetaAnnotatedWith(RequestMapping.class)
                .should().beAnnotatedWith(PreAuthorize.class)
                .check(PRODUCTION);
    }
}
