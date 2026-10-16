package io.github.jakiwz.aether.shared.validation;

import jakarta.validation.Constraint;
import jakarta.validation.ConstraintValidator;
import jakarta.validation.ConstraintValidatorContext;
import jakarta.validation.Payload;
import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

/**
 * Text a person typed: no control characters, no unpaired surrogates and no bidirectional
 * overrides. Such characters are rejected before they reach the database (PostgreSQL refuses NUL),
 * logs (CWE-117 log forging) or other users' screens (Trojan Source, CVE-2021-42574).
 * {@code null} is valid; combine with {@code @NotBlank} when the value is required.
 */
@Target({ElementType.FIELD, ElementType.PARAMETER, ElementType.RECORD_COMPONENT, ElementType.TYPE_USE})
@Retention(RetentionPolicy.RUNTIME)
@Constraint(validatedBy = PlainText.Validator.class)
public @interface PlainText {

    /** Whether line breaks and tabs are allowed (free-text descriptions). */
    boolean multiline() default false;

    String message() default "must not contain control or invisible formatting characters";

    Class<?>[] groups() default {};

    Class<? extends Payload>[] payload() default {};

    class Validator implements ConstraintValidator<PlainText, CharSequence> {

        private boolean multiline;

        @Override
        public void initialize(PlainText annotation) {
            multiline = annotation.multiline();
        }

        @Override
        public boolean isValid(CharSequence value, ConstraintValidatorContext context) {
            if (value == null) {
                return true;
            }
            for (int i = 0; i < value.length(); i++) {
                char c = value.charAt(i);
                if (Character.isHighSurrogate(c) && i + 1 < value.length()
                        && Character.isLowSurrogate(value.charAt(i + 1))) {
                    i++;
                } else if (!isAllowed(c)) {
                    return false;
                }
            }
            return true;
        }

        private boolean isAllowed(char c) {
            if (c == '\n' || c == '\r' || c == '\t') {
                return multiline;
            }
            return !Character.isISOControl(c) && !Character.isSurrogate(c) && !isBidiControl(c);
        }

        private static boolean isBidiControl(char c) {
            return (c >= '‪' && c <= '‮') || (c >= '⁦' && c <= '⁩')
                    || c == '‎' || c == '‏' || c == '؜';
        }
    }
}
