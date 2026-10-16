package io.github.jakiwz.aether.identity.domain;

import org.springframework.security.authentication.AnonymousAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;

/** Attributes a write to the user authenticated for the current request (BR-012, ADR-0012). */
@Component
class SecurityContextActor implements CurrentActor {

    @Override
    public String username() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !authentication.isAuthenticated()
                || authentication instanceof AnonymousAuthenticationToken) {
            throw new IllegalStateException("A write was attempted without an authenticated user");
        }
        return authentication.getName();
    }
}
