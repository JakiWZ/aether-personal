package io.github.jakiwz.aether.missions.api;

import jakarta.validation.Constraint;
import jakarta.validation.ConstraintValidator;
import jakarta.validation.ConstraintValidatorContext;
import jakarta.validation.Payload;
import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

/**
 * The planned end must follow the planned start. Reported on {@code plannedEndAt} so clients can
 * highlight that field; skipped while either date is missing ({@code @NotNull} reports it).
 */
@Target(ElementType.TYPE)
@Retention(RetentionPolicy.RUNTIME)
@Constraint(validatedBy = PlannedWindow.Validator.class)
@interface PlannedWindow {

    String message() default "must be after plannedStartAt";

    Class<?>[] groups() default {};

    Class<? extends Payload>[] payload() default {};

    class Validator implements ConstraintValidator<PlannedWindow, CreateMissionRequest> {

        @Override
        public boolean isValid(CreateMissionRequest request, ConstraintValidatorContext context) {
            if (request.plannedStartAt() == null || request.plannedEndAt() == null
                    || request.plannedEndAt().isAfter(request.plannedStartAt())) {
                return true;
            }
            context.disableDefaultConstraintViolation();
            context.buildConstraintViolationWithTemplate(context.getDefaultConstraintMessageTemplate())
                    .addPropertyNode("plannedEndAt").addConstraintViolation();
            return false;
        }
    }
}
