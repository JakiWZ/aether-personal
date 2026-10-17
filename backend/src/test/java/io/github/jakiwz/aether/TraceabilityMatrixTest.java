package io.github.jakiwz.aether;

import static org.assertj.core.api.Assertions.assertThat;

import java.io.IOException;
import java.io.UncheckedIOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Collectors;
import java.util.stream.Stream;
import org.junit.jupiter.api.Test;

/**
 * Keeps {@code docs/requirements/traceability.md} honest: every requirement of the capitolato has
 * exactly one row, no row names a requirement that does not exist, and every test cited as
 * evidence exists in this module. Maven runs tests from {@code backend/}, so the docs are one up.
 */
class TraceabilityMatrixTest {

    private static final Path REQUIREMENTS = Path.of("..", "docs", "requirements");
    /** A requirement row of the capitolato: {@code | **IAM-001** | **Title** | ...}. */
    private static final Pattern CAPITOLATO_ROW = Pattern.compile("^\\| \\*\\*([A-Z]{2,4}-\\d{3})\\*\\* \\|",
            Pattern.MULTILINE);
    /** A row of the matrix: {@code | IAM-001 | Title | status | issues | evidence |}. */
    private static final Pattern MATRIX_ROW = Pattern.compile("^\\| ([A-Z]{2,4}-\\d{3}) \\|", Pattern.MULTILINE);
    /** A test class cited as evidence, such as {@code AuthenticationIT} or {@code ArchitectureTest}. */
    private static final Pattern TEST_CLASS = Pattern.compile("\\b([A-Z][A-Za-z0-9]+(?:IT|Test))\\b");

    @Test
    void listsEveryRequirementOfTheCapitolatoExactlyOnce() {
        String capitolato = read("capitolato.md");

        assertThat(ids(CAPITOLATO_ROW, capitolato)).as("requirements in the capitolato").hasSizeGreaterThan(90);
        assertThat(mismatches(capitolato, read("traceability.md"))).isEmpty();
    }

    @Test
    void citesOnlyTestsThatExist() throws IOException {
        Set<String> existing;
        try (Stream<Path> files = Files.walk(Path.of("src", "test", "java"))) {
            existing = files.map(file -> file.getFileName().toString())
                    .filter(name -> name.endsWith(".java"))
                    .map(name -> name.substring(0, name.length() - ".java".length()))
                    .collect(Collectors.toSet());
        }

        assertThat(cited(read("traceability.md"))).isNotEmpty().allSatisfy(test -> assertThat(existing)
                .as("test cited in traceability.md").contains(test));
    }

    @Test
    void reportsMissingUnknownAndDuplicatedRows() {
        String capitolato = "| **IAM-001** | **A** | x |\n| **IAM-002** | **B** | y |\n";
        String matrix = "| IAM-001 | A | ✅ | #1 | x |\n| IAM-001 | A | ✅ | #1 | x |\n| IAM-999 | Z | ⬜ | — | |\n";

        assertThat(mismatches(capitolato, matrix))
                .containsExactlyInAnyOrder("missing: IAM-002", "unknown: IAM-999", "duplicated: IAM-001");
    }

    @Test
    void picksUpTestNamesButNotOrdinaryWords() {
        assertThat(cited("Login: AuthenticationIT, EndpointSecurityTest; Test di unità; IT; Testing"))
                .containsExactly("AuthenticationIT", "EndpointSecurityTest");
    }

    /** What is wrong with the matrix against the capitolato; empty when they agree. */
    private static List<String> mismatches(String capitolato, String matrix) {
        Set<String> requirements = new LinkedHashSet<>(ids(CAPITOLATO_ROW, capitolato));
        List<String> rows = ids(MATRIX_ROW, matrix);
        List<String> problems = new ArrayList<>();
        requirements.stream().filter(id -> !rows.contains(id)).forEach(id -> problems.add("missing: " + id));
        new LinkedHashSet<>(rows).stream().filter(id -> !requirements.contains(id))
                .forEach(id -> problems.add("unknown: " + id));
        new LinkedHashSet<>(rows).stream().filter(id -> rows.indexOf(id) != rows.lastIndexOf(id))
                .forEach(id -> problems.add("duplicated: " + id));
        return problems;
    }

    private static List<String> ids(Pattern row, String text) {
        Matcher matcher = row.matcher(text);
        List<String> ids = new ArrayList<>();
        while (matcher.find()) {
            ids.add(matcher.group(1));
        }
        return ids;
    }

    private static Set<String> cited(String text) {
        Matcher matcher = TEST_CLASS.matcher(text);
        Set<String> tests = new LinkedHashSet<>();
        while (matcher.find()) {
            tests.add(matcher.group(1));
        }
        return tests;
    }

    private static String read(String file) {
        try {
            return Files.readString(REQUIREMENTS.resolve(file));
        } catch (IOException e) {
            throw new UncheckedIOException(e);
        }
    }
}
