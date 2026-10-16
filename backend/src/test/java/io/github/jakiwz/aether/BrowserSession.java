package io.github.jakiwz.aether;

import java.io.IOException;
import java.net.CookieManager;
import java.net.HttpCookie;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest.BodyPublisher;
import java.net.http.HttpRequest.BodyPublishers;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse.BodyHandlers;
import java.net.http.HttpResponse;
import java.util.Optional;

/**
 * What the SPA does over real HTTP (ADR-0012): keeps cookies, fetches the CSRF cookie from
 * {@code GET /auth/session} and echoes it as {@code X-XSRF-TOKEN} on every state change.
 */
public final class BrowserSession {

    /** Password of every demo account (docs/database/demo-dataset.md). */
    public static final String DEMO_PASSWORD = "Aether-demo-password";

    private final String baseUrl;
    private final CookieManager cookies = new CookieManager();
    private final HttpClient http;

    public BrowserSession(int port) {
        this.baseUrl = "http://localhost:" + port;
        this.http = HttpClient.newBuilder().cookieHandler(cookies).build();
    }

    /** Signs in with the demo password; fails the test if the login is refused. */
    public static BrowserSession signedIn(int port, String username) {
        BrowserSession session = new BrowserSession(port);
        HttpResponse<String> response = session.login(username, DEMO_PASSWORD);
        if (response.statusCode() != 200) {
            throw new IllegalStateException("Login of " + username + " failed: " + response.body());
        }
        return session;
    }

    public HttpResponse<String> login(String username, String password) {
        get("/api/v1/auth/session");
        return send("POST", "/api/v1/auth/login", BodyPublishers.ofString(
                "{\"username\":\"" + username + "\",\"password\":\"" + password + "\"}"));
    }

    public HttpResponse<String> get(String path) {
        return send("GET", path, BodyPublishers.noBody());
    }

    public HttpResponse<String> post(String path, String json) {
        return send("POST", path, BodyPublishers.ofString(json));
    }

    /** Sends the request with the current CSRF token, as the SPA's HTTP client does. */
    public HttpResponse<String> send(String method, String path, BodyPublisher body) {
        HttpRequest.Builder request = HttpRequest.newBuilder(URI.create(baseUrl + path))
                .header("Content-Type", "application/json")
                .method(method, body);
        cookie("XSRF-TOKEN").ifPresent(token -> request.header("X-XSRF-TOKEN", token.getValue()));
        return sendRaw(request.build());
    }

    /** Sends the request exactly as given, cookies aside. */
    public HttpResponse<String> sendRaw(HttpRequest request) {
        try {
            return http.send(request, BodyHandlers.ofString());
        } catch (IOException e) {
            throw new IllegalStateException(e);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new IllegalStateException(e);
        }
    }

    public URI uri(String path) {
        return URI.create(baseUrl + path);
    }

    public Optional<HttpCookie> cookie(String name) {
        return cookies.getCookieStore().getCookies().stream().filter(c -> c.getName().equals(name)).findFirst();
    }
}
