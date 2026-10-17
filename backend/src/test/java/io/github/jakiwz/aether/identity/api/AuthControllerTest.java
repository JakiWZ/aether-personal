package io.github.jakiwz.aether.identity.api;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.BDDMockito.given;
import static org.mockito.BDDMockito.willThrow;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;

import io.github.jakiwz.aether.identity.domain.AuthenticatedUser;
import io.github.jakiwz.aether.identity.domain.LoginRateLimiter;
import io.github.jakiwz.aether.identity.domain.LoginService;
import io.github.jakiwz.aether.shared.error.TooManyLoginAttemptsException;
import io.github.jakiwz.aether.shared.security.SecurityConfig;
import jakarta.servlet.http.HttpSession;
import java.time.Duration;
import java.util.List;
import java.util.Optional;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.security.core.context.SecurityContext;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.security.web.context.HttpSessionSecurityContextRepository;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.assertj.MockMvcTester;
import org.springframework.test.web.servlet.assertj.MvcTestResult;

/**
 * Contract of {@code /api/v1/auth} (IAM-002, IAM-007): one generic failure, the session only after
 * a successful login, the CSRF token handed out before any state change.
 */
@WebMvcTest(AuthController.class)
@Import(SecurityConfig.class)
class AuthControllerTest {

    private static final AuthenticatedUser ROSSI = new AuthenticatedUser("mc.rossi", "Laura Rossi",
            List.of("MISSION_CONTROLLER"), List.of("MISSION_MANAGE", "MISSION_READ"));

    @Autowired
    MockMvcTester mvc;

    @MockitoBean
    LoginService logins;

    @MockitoBean
    LoginRateLimiter rateLimiter;

    @Test
    void tellsAnAnonymousVisitorNobodyIsSignedIn() {
        // the XSRF-TOKEN cookie is checked in AuthenticationIT: csrf() here swaps the token store
        assertThat(mvc.get().uri("/api/v1/auth/session")).hasStatusOk()
                .bodyJson().isLenientlyEqualTo("""
                        {"authenticated":false,"username":null,"roles":[],"permissions":[]}""");
    }

    @Test
    void startsASessionForValidCredentials() {
        given(logins.login("mc.rossi", "Aether-demo-password")).willReturn(Optional.of(ROSSI));

        MvcTestResult result = login("""
                {"username":"mc.rossi","password":"Aether-demo-password"}""");

        assertThat(result).hasStatusOk()
                .bodyJson().isLenientlyEqualTo("""
                        {"authenticated":true,"username":"mc.rossi","displayName":"Laura Rossi",
                         "roles":["MISSION_CONTROLLER"],"permissions":["MISSION_MANAGE","MISSION_READ"]}""");
        HttpSession session = result.getMvcResult().getRequest().getSession(false);
        assertThat(session).isNotNull();
        SecurityContext context = (SecurityContext) session.getAttribute(
                HttpSessionSecurityContextRepository.SPRING_SECURITY_CONTEXT_KEY);
        assertThat(context.getAuthentication().getAuthorities()).extracting(Object::toString)
                .containsExactlyInAnyOrder("MISSION_MANAGE", "MISSION_READ", "ROLE_MISSION_CONTROLLER");
    }

    @Test
    void throttlesAnAddressBeforeCheckingAnyPassword() {
        willThrow(new TooManyLoginAttemptsException(Duration.ofSeconds(42))).given(rateLimiter).acquire(any());

        MvcTestResult result = login("""
                {"username":"mc.rossi","password":"Aether-demo-password"}""");

        assertThat(result).hasStatus(HttpStatus.TOO_MANY_REQUESTS).hasHeader("Retry-After", "42")
                .bodyJson().extractingPath("$.code").isEqualTo("TOO_MANY_LOGIN_ATTEMPTS");
        verify(logins, never()).login(any(), any());
        assertThat(result.getMvcResult().getRequest().getSession(false)).isNull();
    }

    @Test
    void answersEveryFailedLoginTheSameWayAndStartsNoSession() {
        given(logins.login(any(), any())).willReturn(Optional.empty());

        MvcTestResult result = login("""
                {"username":"mc.rossi","password":"wrong-password-123"}""");

        assertThat(result).hasStatus(HttpStatus.UNAUTHORIZED)
                .hasContentTypeCompatibleWith(MediaType.APPLICATION_PROBLEM_JSON)
                .bodyJson().isLenientlyEqualTo("""
                        {"code":"INVALID_CREDENTIALS","detail":"Invalid username or password."}""");
        HttpSession session = result.getMvcResult().getRequest().getSession(false);
        assertThat(session == null ? null
                : session.getAttribute(HttpSessionSecurityContextRepository.SPRING_SECURITY_CONTEXT_KEY)).isNull();
    }

    @Test
    void refusesALoginWithoutTheCsrfToken() {
        MvcTestResult result = mvc.post().uri("/api/v1/auth/login").contentType(MediaType.APPLICATION_JSON)
                .content("""
                        {"username":"mc.rossi","password":"Aether-demo-password"}""")
                .exchange();

        assertThat(result).hasStatus(HttpStatus.FORBIDDEN)
                .bodyJson().extractingPath("$.code").isEqualTo("CSRF_TOKEN_INVALID");
        verify(logins, never()).login(any(), any());
    }

    @Test
    void rejectsAnIncompleteLoginBeforeCheckingIt() {
        MvcTestResult result = login("""
                {"username":" ","password":""}""");

        assertThat(result).hasStatus(HttpStatus.BAD_REQUEST)
                .bodyJson().extractingPath("$.errors[*].field").asArray().contains("username", "password");
        verify(logins, never()).login(any(), any());
    }

    @Test
    void neverEchoesThePasswordInErrors() {
        MvcTestResult result = login("""
                {"username":"mc.rossi","password":"secret\\u0000value"}""");

        assertThat(result).hasStatus(HttpStatus.BAD_REQUEST);
        assertThat(result).bodyText().doesNotContain("secret");
    }

    @Test
    @WithMockUser
    void endsTheSessionOnLogout() {
        assertThat(mvc.post().uri("/api/v1/auth/logout").with(csrf()).exchange())
                .hasStatus(HttpStatus.NO_CONTENT);
    }

    @Test
    void masksThePasswordWhenTheRequestIsLogged() {
        assertThat(new LoginRequest("mc.rossi", "Aether-demo-password").toString())
                .contains("mc.rossi").doesNotContain("Aether-demo-password");
    }

    private MvcTestResult login(String body) {
        return mvc.post().uri("/api/v1/auth/login").with(csrf())
                .contentType(MediaType.APPLICATION_JSON).content(body).exchange();
    }
}
