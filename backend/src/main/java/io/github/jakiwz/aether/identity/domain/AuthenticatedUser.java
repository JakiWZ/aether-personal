package io.github.jakiwz.aether.identity.domain;

import java.io.Serializable;
import java.util.List;
import org.springframework.security.core.AuthenticatedPrincipal;

/**
 * The principal kept in the HTTP session after login. Roles and permissions are read once at
 * login: a change takes effect at the user's next login (ADR-0012).
 */
public record AuthenticatedUser(String username, String displayName, List<String> roles, List<String> permissions)
        implements AuthenticatedPrincipal, Serializable {

    public AuthenticatedUser {
        roles = List.copyOf(roles);
        permissions = List.copyOf(permissions);
    }

    @Override
    public String getName() {
        return username;
    }
}
