package io.github.jakiwz.aether.colonies;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;

import io.github.jakiwz.aether.colonies.domain.Colony;
import io.github.jakiwz.aether.colonies.domain.ColonyService;
import io.github.jakiwz.aether.colonies.domain.ColonyStatus;
import java.time.LocalDate;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.assertj.MockMvcTester;
import org.springframework.test.web.servlet.assertj.MvcTestResult;

/**
 * Contract of {@code GET /api/v1/colonies} (ARES-101).
 */
@WebMvcTest
class ColonyControllerTest {

    @Autowired
    MockMvcTester mvc;

    @MockitoBean
    ColonyService service;

    @Test
    void listsBasesWithCodeNameAndStatus() {
        given(service.list(null)).willReturn(List.of(
                new Colony("ARS-01", "Ares Prime", ColonyStatus.OPERATIONAL, true, 40, LocalDate.of(2031, 3, 14)),
                new Colony("OLD-01", "Old Outpost", ColonyStatus.INACTIVE, false, null, null)));

        MvcTestResult result = mvc.get().uri("/api/v1/colonies").exchange();

        assertThat(result).hasStatusOk().hasContentTypeCompatibleWith(MediaType.APPLICATION_JSON);
        assertThat(result).bodyJson().isLenientlyEqualTo("""
                [
                  {"code":"ARS-01","name":"Ares Prime","status":"OPERATIONAL","active":true,
                   "maxPopulation":40,"establishedAt":"2031-03-14"},
                  {"code":"OLD-01","name":"Old Outpost","status":"INACTIVE","active":false,
                   "maxPopulation":null,"establishedAt":null}
                ]""");
    }

    @Test
    void passesTheActiveFilterToTheService() {
        given(service.list(false)).willReturn(List.of());

        assertThat(mvc.get().uri("/api/v1/colonies?active=false"))
                .hasStatusOk()
                .bodyJson().isEqualTo("[]");
        verify(service).list(false);
    }

    @Test
    void rejectsAnActiveFilterThatIsNotABoolean() {
        MvcTestResult result = mvc.get().uri("/api/v1/colonies?active=maybe").exchange();

        assertThat(result).hasStatus(HttpStatus.BAD_REQUEST)
                .hasContentTypeCompatibleWith(MediaType.APPLICATION_PROBLEM_JSON);
        assertThat(result).bodyJson().extractingPath("$.code").isEqualTo("MALFORMED_REQUEST");
        verify(service, never()).list(any());
    }
}
