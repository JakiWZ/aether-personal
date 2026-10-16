package io.github.jakiwz.aether.identity.api;

import io.github.jakiwz.aether.shared.validation.PlainText;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.Size;

/**
 * Credentials of a login. The password accepts any printable Unicode text up to 128 characters
 * (NIST SP 800-63B-4 asks for at least 64) and is never logged or echoed.
 */
@Schema(name = "Login")
public record LoginRequest(
        @Schema(example = "mc.rossi") @NotBlank @Size(max = 100) @PlainText String username,
        @Schema(format = "password") @NotEmpty @Size(max = 128) @PlainText String password) {

    @Override
    public String toString() {
        return "LoginRequest[username=" + username + ", password=***]";
    }
}
