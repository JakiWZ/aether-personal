package io.github.jakiwz.aether.identity.api;

import io.github.jakiwz.aether.identity.domain.AuthenticatedUser;
import io.swagger.v3.oas.annotations.media.Schema;
import java.util.List;
import org.jspecify.annotations.Nullable;

/**
 * Who is signed in. The permissions let the SPA hide what the user cannot do; the server still
 * checks every request (IAM-005).
 */
@Schema(name = "Session")
public record SessionResponse(
        boolean authenticated,
        @Schema(nullable = true, example = "mc.rossi") @Nullable String username,
        @Schema(nullable = true, example = "Laura Rossi") @Nullable String displayName,
        @Schema(example = "[\"MISSION_CONTROLLER\"]") List<String> roles,
        @Schema(example = "[\"MISSION_READ\", \"MISSION_MANAGE\"]") List<String> permissions) {

    static final SessionResponse ANONYMOUS = new SessionResponse(false, null, null, List.of(), List.of());

    static SessionResponse from(AuthenticatedUser user) {
        return new SessionResponse(true, user.username(), user.displayName(), user.roles(), user.permissions());
    }
}
