package io.github.jakiwz.aether.colonies.api;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.BDDMockito.given;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;

import io.github.jakiwz.aether.colonies.domain.Colony;
import io.github.jakiwz.aether.colonies.domain.ColonyService;
import io.github.jakiwz.aether.colonies.domain.ColonyStatus;
import java.time.LocalDate;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.assertj.MockMvcTester;
import org.springframework.test.web.servlet.assertj.MvcTestResult;

/**
 * Contract of {@code GET /api/v1/colonies} (ARES-101).
 */
@WebMvcTest(ColonyController.class)
class ColonyControllerTest {

    @Autowired
    MockMvcTester mvc;

    @MockitoBean
    ColonyService service;

    @Test
    void listsBasesWithCodeNameAndStatus() {
        given(service.list(null, 0, 20)).willReturn(new PageImpl<>(List.of(
                new Colony("ARS-01", "Ares Prime", ColonyStatus.OPERATIONAL, true, 40, LocalDate.of(2031, 3, 14)),
                new Colony("OLD-01", "Old Outpost", ColonyStatus.INACTIVE, false, null, null)),
                PageRequest.of(0, 20), 2));

        MvcTestResult result = mvc.get().uri("/api/v1/colonies").exchange();

        assertThat(result).hasStatusOk().hasContentTypeCompatibleWith(MediaType.APPLICATION_JSON);
        assertThat(result).bodyJson().isEqualTo("""
                {"items":[
                  {"code":"ARS-01","name":"Ares Prime","status":"OPERATIONAL","active":true,
                   "maxPopulation":40,"establishedAt":"2031-03-14"},
                  {"code":"OLD-01","name":"Old Outpost","status":"INACTIVE","active":false,
                   "maxPopulation":null,"establishedAt":null}
                 ],
                 "page":0,"size":20,"totalItems":2,"totalPages":1}""");
    }

    @Test
    void passesTheActiveFilterToTheService() {
        given(service.list(false, 2, 5)).willReturn(new PageImpl<>(List.of(), PageRequest.of(2, 5), 3));

        assertThat(mvc.get().uri("/api/v1/colonies?active=false&page=2&size=5"))
                .hasStatusOk()
                .bodyJson().isEqualTo("""
                        {"items":[],"page":2,"size":5,"totalItems":3,"totalPages":1}""");
        verify(service).list(false, 2, 5);
    }

    @Test
    void rejectsAnActiveFilterThatIsNotABoolean() {
        MvcTestResult result = mvc.get().uri("/api/v1/colonies?active=maybe").exchange();

        assertThat(result).hasStatus(HttpStatus.BAD_REQUEST)
                .hasContentTypeCompatibleWith(MediaType.APPLICATION_PROBLEM_JSON);
        assertThat(result).bodyJson().extractingPath("$.code").isEqualTo("MALFORMED_REQUEST");
        verify(service, never()).list(any(), anyInt(), anyInt());
    }

    @ParameterizedTest
    @ValueSource(strings = {"page=-1", "page=10001", "size=0", "size=101", "size=abc", "page=1e3"})
    void rejectsPagingOutsideTheLimits(String query) {
        MvcTestResult result = mvc.get().uri("/api/v1/colonies?" + query).exchange();

        assertThat(result).hasStatus(HttpStatus.BAD_REQUEST)
                .hasContentTypeCompatibleWith(MediaType.APPLICATION_PROBLEM_JSON);
        assertThat(result).bodyJson().extractingPath("$.code").isEqualTo("VALIDATION_FAILED");
        assertThat(result).bodyJson().extractingPath("$.errors[0].message").asString()
                .doesNotContain("java.", "Integer");
        verify(service, never()).list(any(), anyInt(), anyInt());
    }
}
