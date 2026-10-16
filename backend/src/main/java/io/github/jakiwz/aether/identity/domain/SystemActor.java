package io.github.jakiwz.aether.identity.domain;

import org.springframework.stereotype.Component;

/** Attributes every write to the technical {@code system} account created by V15 (ADR-0008). */
@Component
class SystemActor implements CurrentActor {

    static final String USERNAME = "system";

    @Override
    public String username() {
        return USERNAME;
    }
}
