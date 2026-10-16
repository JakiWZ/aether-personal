package io.github.jakiwz.aether.shared.validation;

import jakarta.validation.Constraint;
import jakarta.validation.ConstraintValidator;
import jakarta.validation.ConstraintValidatorContext;
import jakarta.validation.Payload;
import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;
import java.time.Instant;
import java.time.OffsetDateTime;

/**
 * An instant inside the four-digit years of ISO 8601 (BR-011), so it fits a PostgreSQL
 * {@code TIMESTAMPTZ} and any client. Without it, {@code +999999999-01-01T00:00Z} parses in Java and
 * only fails in the database. {@code null} is valid; combine with {@code @NotNull} when required.
 */
@Target({ElementType.FIELD, ElementType.PARAMETER, ElementType.RECORD_COMPONENT, ElementType.TYPE_USE})
@Retention(RetentionPolicy.RUNTIME)
@Constraint(validatedBy = SupportedInstant.Validator.class)
public @interface SupportedInstant {

    String message() default "must be between years 0001 and 9999 (UTC)";

    Class<?>[] groups() default {};

    Class<? extends Payload>[] payload() default {};

    class Validator implements ConstraintValidator<SupportedInstant, OffsetDateTime> {

        private static final Instant FIRST = Instant.parse("0001-01-01T00:00:00Z");
        private static final Instant AFTER_LAST = Instant.parse("+10000-01-01T00:00:00Z");

        @Override
        public boolean isValid(OffsetDateTime value, ConstraintValidatorContext context) {
            if (value == null) {
                return true;
            }
            Instant instant = value.toInstant();
            return !instant.isBefore(FIRST) && instant.isBefore(AFTER_LAST);
        }
    }
}
