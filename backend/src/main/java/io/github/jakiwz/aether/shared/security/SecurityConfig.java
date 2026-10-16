package io.github.jakiwz.aether.shared.security;

import jakarta.servlet.DispatcherType;
import java.util.Map;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Import;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.crypto.argon2.Argon2PasswordEncoder;
import org.springframework.security.crypto.password.DelegatingPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.logout.HttpStatusReturningLogoutSuccessHandler;
import org.springframework.security.web.context.HttpSessionSecurityContextRepository;
import org.springframework.security.web.context.SecurityContextRepository;
import org.springframework.security.web.csrf.CookieCsrfTokenRepository;

/**
 * Session-cookie authentication for the SPA, CSRF tokens in a cookie the SPA echoes in a header,
 * deny by default, permissions checked on every controller method (ADR-0012).
 */
@Configuration(proxyBeanMethods = false)
@EnableMethodSecurity
@Import(ProblemSecurityHandler.class)
public class SecurityConfig {

    public static final String LOGIN_PATH = "/api/v1/auth/login";
    public static final String SESSION_PATH = "/api/v1/auth/session";
    public static final String LOGOUT_PATH = "/api/v1/auth/logout";

    /** Id of the current password hashing scheme, stored as the {@code {argon2id}} hash prefix. */
    private static final String PASSWORD_ENCODING = "argon2id";

    @Bean
    SecurityFilterChain securityFilterChain(HttpSecurity http, CookieCsrfTokenRepository csrfTokens,
            SecurityContextRepository securityContexts, ProblemSecurityHandler problems,
            @Value("${server.servlet.session.cookie.name:JSESSIONID}") String sessionCookie) {
        http
                .authorizeHttpRequests(requests -> requests
                        // the container's error page renders the status already decided upstream
                        .dispatcherTypeMatchers(DispatcherType.ERROR).permitAll()
                        .requestMatchers("/actuator/health", "/actuator/health/**", "/actuator/info").permitAll()
                        .requestMatchers("/v3/api-docs", "/v3/api-docs/**", "/swagger-ui.html", "/swagger-ui/**")
                        .permitAll()
                        .requestMatchers(HttpMethod.POST, LOGIN_PATH).permitAll()
                        .requestMatchers(HttpMethod.GET, SESSION_PATH).permitAll()
                        .anyRequest().authenticated())
                .csrf(csrf -> csrf.spa().csrfTokenRepository(csrfTokens))
                .securityContext(context -> context.securityContextRepository(securityContexts))
                .exceptionHandling(errors -> errors.authenticationEntryPoint(problems).accessDeniedHandler(problems))
                .logout(logout -> logout.logoutUrl(LOGOUT_PATH)
                        .logoutSuccessHandler(new HttpStatusReturningLogoutSuccessHandler(HttpStatus.NO_CONTENT))
                        .deleteCookies(sessionCookie))
                .requestCache(AbstractHttpConfigurer::disable)
                .httpBasic(AbstractHttpConfigurer::disable)
                .formLogin(AbstractHttpConfigurer::disable);
        return http.build();
    }

    /**
     * The {@code XSRF-TOKEN} cookie Angular reads and echoes as {@code X-XSRF-TOKEN}. It is not
     * {@code HttpOnly} by design: it only proves the request comes from our own pages.
     */
    @Bean
    CookieCsrfTokenRepository csrfTokenRepository(
            @Value("${server.servlet.session.cookie.secure:false}") boolean secure) {
        CookieCsrfTokenRepository repository = CookieCsrfTokenRepository.withHttpOnlyFalse();
        repository.setCookieCustomizer(cookie -> cookie.sameSite("Strict").secure(secure).path("/"));
        return repository;
    }

    @Bean
    SecurityContextRepository securityContextRepository() {
        return new HttpSessionSecurityContextRepository();
    }

    /**
     * Argon2id with the OWASP Password Storage minimum (19 MiB, 2 iterations, parallelism 1), behind
     * a delegating encoder so the parameters can be raised later and old hashes upgraded at login.
     * A stored value without a known prefix (the demo placeholders) never matches.
     */
    @Bean
    PasswordEncoder passwordEncoder() {
        Argon2PasswordEncoder argon2id = new Argon2PasswordEncoder(16, 32, 1, 19 * 1024, 2);
        DelegatingPasswordEncoder encoder = new DelegatingPasswordEncoder(PASSWORD_ENCODING,
                Map.of(PASSWORD_ENCODING, argon2id));
        encoder.setDefaultPasswordEncoderForMatches(new NeverMatchingPasswordEncoder());
        return encoder;
    }

    private static final class NeverMatchingPasswordEncoder implements PasswordEncoder {

        @Override
        public String encode(CharSequence rawPassword) {
            throw new UnsupportedOperationException("Only used to reject unknown hash formats");
        }

        @Override
        public boolean matches(CharSequence rawPassword, String encodedPassword) {
            return false;
        }
    }
}
