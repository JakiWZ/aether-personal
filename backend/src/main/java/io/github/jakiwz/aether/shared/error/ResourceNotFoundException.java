package io.github.jakiwz.aether.shared.error;

import org.springframework.http.HttpStatus;

/**
 * The requested entity does not exist (HTTP 404).
 */
public class ResourceNotFoundException extends AetherException {

    public ResourceNotFoundException(String resource, Object identifier) {
        super(HttpStatus.NOT_FOUND, ErrorCode.RESOURCE_NOT_FOUND,
                "%s '%s' was not found".formatted(resource, identifier));
    }
}
