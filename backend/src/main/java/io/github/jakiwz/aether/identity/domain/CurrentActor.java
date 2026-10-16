package io.github.jakiwz.aether.identity.domain;

/**
 * The user account a write is attributed to (BR-012). Until authentication exists (IAM-002) the
 * only implementation is {@link SystemActor}; then it will read the authenticated principal.
 */
public interface CurrentActor {

    /** Username of an existing {@code user_account}. */
    String username();
}
