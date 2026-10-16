package io.github.jakiwz.aether.shared.error;

import jakarta.validation.Valid;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Positive;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * Test-only endpoints that raise each kind of failure the error contract must cover.
 */
@RestController
@RequestMapping("/probe")
class ProbeController {

    record ProbeRequest(@NotBlank String code, @Positive int quantity) {
    }

    @GetMapping("/missing")
    void missing() {
        throw new ResourceNotFoundException("Mission", "MSN-404");
    }

    @PostMapping("/rule")
    void rule() {
        throw new BusinessRuleViolationException("CREW_ASSIGNMENT_OVERLAP",
                "Crew member CRW-001 is already assigned to an overlapping mission.");
    }

    @PostMapping("/validate")
    ProbeRequest validate(@Valid @RequestBody ProbeRequest request) {
        return request;
    }

    @GetMapping("/param")
    int param(@RequestParam @Min(1) int page) {
        return page;
    }

    @GetMapping("/integrity")
    void integrity() {
        throw new DataIntegrityViolationException(
                "ERROR: duplicate key value violates unique constraint \"crew_member_employee_code_key\"");
    }

    @GetMapping("/boom")
    void boom() {
        throw new IllegalStateException("database password is hunter2");
    }
}
