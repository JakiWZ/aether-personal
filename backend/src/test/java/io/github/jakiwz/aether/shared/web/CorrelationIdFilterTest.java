package io.github.jakiwz.aether.shared.web;

import static org.assertj.core.api.Assertions.assertThat;

import java.util.UUID;
import java.util.concurrent.atomic.AtomicReference;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
import org.slf4j.MDC;
import org.springframework.mock.web.MockFilterChain;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;

class CorrelationIdFilterTest {

    private final CorrelationIdFilter filter = new CorrelationIdFilter();

    @Test
    void keepsTheCallersUuid() throws Exception {
        String id = "3f2a7c1e-9b4d-4e8a-a6f0-1c2d3e4f5a6b";

        String seen = run(id, new MockHttpServletResponse());

        assertThat(seen).isEqualTo(id);
    }

    @Test
    void generatesAnIdWhenTheCallerSendsNone() throws Exception {
        MockHttpServletResponse response = new MockHttpServletResponse();

        String seen = run(null, response);

        assertThat(UUID.fromString(seen)).isNotNull();
        assertThat(response.getHeader(CorrelationId.HEADER)).isEqualTo(seen);
    }

    @ParameterizedTest
    @ValueSource(strings = {"", "abc", "not-a-uuid\r\nFAKE LOG LINE", "3f2a7c1e-9b4d-4e8a-a6f0-1c2d3e4f5a6b-extra",
            "{\"injected\":true}"})
    void replacesAnythingThatIsNotAUuid(String header) throws Exception {
        MockHttpServletResponse response = new MockHttpServletResponse();

        String seen = run(header, response);

        assertThat(seen).isNotEqualTo(header);
        assertThat(UUID.fromString(seen)).isNotNull();
        assertThat(response.getHeader(CorrelationId.HEADER)).isEqualTo(seen);
    }

    @Test
    void clearsTheMdcAfterTheRequest() throws Exception {
        run(null, new MockHttpServletResponse());

        assertThat(MDC.get(CorrelationId.MDC_KEY)).isNull();
        assertThat(CorrelationId.current()).isEmpty();
    }

    /** Runs the filter and returns the correlation id seen while the request was being served. */
    private String run(String header, MockHttpServletResponse response) throws Exception {
        MockHttpServletRequest request = new MockHttpServletRequest("GET", "/api/v1/colonies");
        if (header != null) {
            request.addHeader(CorrelationId.HEADER, header);
        }
        AtomicReference<String> seen = new AtomicReference<>();
        filter.doFilter(request, response, new MockFilterChain() {
            @Override
            public void doFilter(jakarta.servlet.ServletRequest req, jakarta.servlet.ServletResponse res) {
                seen.set(CorrelationId.current().orElseThrow().toString());
            }
        });
        return seen.get();
    }
}
