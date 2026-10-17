# ADR-0015: Static analysis with Error Prone and NullAway

- **Status:** Accepted
- **Date:** 2026-10-17
- **Issue:** #103

## Context and problem statement

The review against the Craft pattern ("never crash") and OWASP A10:2025 (mishandling of exceptional
conditions) found that the backend had no static analysis. The code already marks nullable values
with JSpecify `@Nullable`, but nothing checked them. A `NullPointerException` or a classic bug
(wrong `equals`, ignored result, bad format string) was found only when a test or a user hit it.

## Considered options

1. **Error Prone + NullAway as `javac` plugins.** They run in every compilation, add no separate job,
   and NullAway reads JSpecify annotations, which Spring Framework 7 and Spring Boot 4 use themselves.
2. **SpotBugs / PMD as Maven plugins.** They analyse bytecode or source after compilation in an
   extra step. They are noisier, and their null analysis is weaker than NullAway's.
3. **Sonar in CI.** This needs an external service and a token, and is too heavy for this project.

## Decision

Option 1.
- `maven-compiler-plugin` runs Error Prone 2.50 with its default checks. Error-level patterns fail
  the build and the rest are printed as warnings.
- NullAway 0.14 runs at error level on `io.github.jakiwz.aether` main code:
  - JPA entities (`@Entity`) are initialised by Hibernate, and fields annotated `@Id` are assigned
    on persist, so neither is reported as uninitialised;
  - test code runs Error Prone without NullAway, because mocks and fixtures make it noisy for
    little gain.
- `backend/.mvn/jvm.config` opens the `jdk.compiler` packages that Error Prone needs on JDK 21.
  `-XDaddTypeAnnotationsToSymbol=true` is required on JDK 21.

The first run found real problems, all fixed in the same PR:
- `PlainText` held invisible bidirectional control characters as literals in its source. Error
  Prone's `UnicodeDirectionalityCharacters` check exists against this "Trojan Source" pattern.
  They are now `\u` escapes.
- `GlobalExceptionHandler` passed values that may be null (`getDefaultMessage()`,
  `getParameterName()`) into non-null problem fields.
- `PasswordEncoder` overrides did not declare the nullable parameters of their interface.

## Consequences

- Good: null-safety and common bug patterns are checked on every build, locally and in CI.
  A contributor sees the error in `mvn test` before any review.
- Bad: compilation is a few seconds slower. Upgrading the JDK or Error Prone can bring new checks
  that fail the build. That is the intended trade-off: fix them, never silence them in bulk.
- New code marks nullable values with `@org.jspecify.annotations.Nullable`. A targeted
  `@SuppressWarnings("NullAway")` needs a comment saying why.
