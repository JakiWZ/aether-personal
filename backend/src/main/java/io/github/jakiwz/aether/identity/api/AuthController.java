package io.github.jakiwz.aether.identity.api;

import io.github.jakiwz.aether.identity.domain.AuthenticatedUser;
import io.github.jakiwz.aether.identity.domain.LoginService;
import io.github.jakiwz.aether.shared.error.InvalidCredentialsException;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.validation.Valid;
import java.util.List;
import java.util.stream.Stream;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContext;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.web.authentication.session.ChangeSessionIdAuthenticationStrategy;
import org.springframework.security.web.context.SecurityContextRepository;
import org.springframework.security.web.csrf.CsrfAuthenticationStrategy;
import org.springframework.security.web.csrf.CsrfToken;
import org.springframework.security.web.csrf.CsrfTokenRepository;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Login and current session (IAM-002, IAM-007). Logout is {@code POST /api/v1/auth/logout},
 * handled by Spring Security. Every call needs the CSRF token the session endpoint hands out.
 */
@RestController
@RequestMapping("/api/v1/auth")
@Tag(name = "Authentication", description = "Session login for the web application (ADR-0012)")
class AuthController {

    private final LoginService logins;
    private final SecurityContextRepository securityContexts;
    private final ChangeSessionIdAuthenticationStrategy sessionFixation = new ChangeSessionIdAuthenticationStrategy();
    private final CsrfAuthenticationStrategy csrfRotation;

    AuthController(LoginService logins, SecurityContextRepository securityContexts, CsrfTokenRepository csrfTokens) {
        this.logins = logins;
        this.securityContexts = securityContexts;
        this.csrfRotation = new CsrfAuthenticationStrategy(csrfTokens);
    }

    @GetMapping("/session")
    @PreAuthorize("permitAll()")
    @Operation(summary = "Current session",
            description = "Who is signed in, if anyone. Also sets the XSRF-TOKEN cookie the other calls echo.")
    SessionResponse session(Authentication authentication, CsrfToken csrfToken) {
        csrfToken.getToken(); // load the deferred token so that its cookie is written
        return authentication != null && authentication.getPrincipal() instanceof AuthenticatedUser user
                ? SessionResponse.from(user)
                : SessionResponse.ANONYMOUS;
    }

    @PostMapping("/login")
    @PreAuthorize("permitAll()")
    @Operation(summary = "Sign in", description = "Starts a session cookie. The same error for every failure.")
    @ApiResponse(responseCode = "401", description = "INVALID_CREDENTIALS")
    @ApiResponse(responseCode = "403", description = "CSRF_TOKEN_INVALID: call GET /auth/session first")
    SessionResponse login(@Valid @RequestBody LoginRequest login, HttpServletRequest request,
            HttpServletResponse response) {
        AuthenticatedUser user = logins.login(login.username(), login.password())
                .orElseThrow(InvalidCredentialsException::new);
        Authentication authentication = UsernamePasswordAuthenticationToken.authenticated(user, null,
                authorities(user));
        sessionFixation.onAuthentication(authentication, request, response);
        csrfRotation.onAuthentication(authentication, request, response);
        loadCsrfToken(request); // hand the rotated token to the SPA with this response
        SecurityContext context = SecurityContextHolder.createEmptyContext();
        context.setAuthentication(authentication);
        SecurityContextHolder.setContext(context);
        securityContexts.saveContext(context, request, response);
        return SessionResponse.from(user);
    }

    private static void loadCsrfToken(HttpServletRequest request) {
        if (request.getAttribute(CsrfToken.class.getName()) instanceof CsrfToken token) {
            token.getToken();
        }
    }

    /** Permissions as authorities, plus {@code ROLE_<code>} for each role. */
    private static List<SimpleGrantedAuthority> authorities(AuthenticatedUser user) {
        return Stream.concat(user.permissions().stream(), user.roles().stream().map(role -> "ROLE_" + role))
                .map(SimpleGrantedAuthority::new)
                .toList();
    }
}
