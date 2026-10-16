package io.github.jakiwz.aether;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.util.List;
import org.flywaydb.core.Flyway;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.annotation.Transactional;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.postgresql.PostgreSQLContainer;

/**
 * Loads the demo dataset (TASK-004) with the {@code demo} profile and checks the acceptance
 * criteria of issue #10, plus the built-in negative cases the database must reject.
 */
@SpringBootTest
@ActiveProfiles("demo")
@Testcontainers
@Transactional // every test rolls back, so the negative cases never alter the shared dataset
class DemoDatasetIT {

    @Container
    @ServiceConnection
    static final PostgreSQLContainer POSTGRES = new PostgreSQLContainer("postgres:16-alpine");

    @Autowired
    JdbcTemplate jdbc;

    @Autowired
    Flyway flyway;

    @Test
    void appliesTheDemoDatasetAfterTheSchema() {
        assertThat(flyway.info().pending()).isEmpty();
        assertThat(flyway.info().applied())
                .anySatisfy(m -> assertThat(m.getDescription()).isEqualTo("demo dataset"));
    }

    @Test
    void hasAtLeastThreeBasesAndFifteenCrewMembers() {
        assertThat(count("SELECT count(*) FROM aether.colony")).isGreaterThanOrEqualTo(3);
        assertThat(count("SELECT count(*) FROM aether.crew_member")).isGreaterThanOrEqualTo(15);
        assertThat(count("SELECT count(DISTINCT id_home_colony) FROM aether.crew_member")).isGreaterThanOrEqualTo(3);
    }

    @Test
    void hasMissionsInEveryLifecycleState() {
        List<String> statuses = jdbc.queryForList("SELECT DISTINCT status FROM aether.mission", String.class);

        assertThat(statuses).containsExactlyInAnyOrder(
                "DRAFT", "PLANNED", "APPROVAL_PENDING", "APPROVED",
                "IN_PROGRESS", "COMPLETED", "ABORTED", "CANCELLED");
    }

    @Test
    void hasVehiclesAndStockedResources() {
        assertThat(count("""
                SELECT count(*) FROM aether.asset a JOIN aether.asset_type t ON t.id_asset_type = a.id_asset_type
                WHERE t.category = 'VEHICLE'""")).isGreaterThanOrEqualTo(5);
        assertThat(count("SELECT count(DISTINCT status) FROM aether.asset")).isGreaterThanOrEqualTo(4);
        assertThat(count("SELECT count(*) FROM aether.resource")).isGreaterThanOrEqualTo(5);
        assertThat(count("SELECT count(*) FROM aether.inventory_stock WHERE quantity > 0")).isGreaterThanOrEqualTo(10);
    }

    @Test
    void stockMatchesTheMovementLedger() {
        assertThat(count("""
                SELECT count(*) FROM aether.inventory_stock st
                WHERE st.quantity <> (
                    SELECT COALESCE(sum(CASE WHEN mv.to_location_id = st.id_location THEN mv.quantity ELSE -mv.quantity END), 0)
                    FROM aether.inventory_movement mv
                    WHERE mv.id_resource = st.id_resource
                      AND mv.id_lot IS NOT DISTINCT FROM st.id_lot
                      AND st.id_location IN (mv.to_location_id, mv.from_location_id))""")).isZero();
    }

    @Test
    void providesCasesForQueriesAndNegativeTests() {
        // stock below threshold, empty stock, expired lot and certification, unavailable crew, asset in maintenance
        assertThat(count("""
                SELECT count(*) FROM aether.inventory_stock st JOIN aether.inventory_threshold th
                  ON th.id_location = st.id_location AND th.id_resource = st.id_resource
                WHERE st.quantity < th.minimum_quantity""")).isGreaterThanOrEqualTo(2);
        assertThat(count("SELECT count(*) FROM aether.inventory_stock WHERE quantity = 0")).isGreaterThanOrEqualTo(1);
        assertThat(count("SELECT count(*) FROM aether.resource_lot WHERE status = 'EXPIRED'")).isGreaterThanOrEqualTo(1);
        assertThat(count("SELECT count(*) FROM aether.crew_certification WHERE status = 'EXPIRED'")).isGreaterThanOrEqualTo(1);
        assertThat(count("SELECT count(*) FROM aether.crew_member WHERE status <> 'ACTIVE'")).isGreaterThanOrEqualTo(3);
        assertThat(count("SELECT count(*) FROM aether.asset WHERE status IN ('MAINTENANCE','OUT_OF_SERVICE')")).isGreaterThanOrEqualTo(2);
        assertThat(count("SELECT count(*) FROM aether.incident WHERE severity = 'CRITICAL' AND status <> 'CLOSED'")).isGreaterThanOrEqualTo(1);
    }

    @Test
    void rejectsDoubleBookingACrewMemberAlreadyOnAnOverlappingMission() {
        // CRW-008 is confirmed on PHX-003; PHX-009 overlaps that window (BR-003).
        assertThatThrownBy(() -> jdbc.update("""
                INSERT INTO aether.mission_crew_assignment(id_mission, id_crew_member, mission_role, assigned_from, assigned_to)
                SELECT m.id_mission, cm.id_crew_member, 'Geologist', m.planned_start_at, m.planned_end_at
                FROM aether.mission m, aether.crew_member cm WHERE m.code = 'PHX-009' AND cm.employee_code = 'CRW-008'"""))
                .isInstanceOf(DataIntegrityViolationException.class)
                .hasMessageContaining("ex_crew_no_overlapping_missions");
    }

    @Test
    void rejectsDoubleBookingAVehicleAlreadyOnAnOverlappingMission() {
        // ROV-VLM-01 is confirmed on PHX-003 (BR-005).
        assertThatThrownBy(() -> jdbc.update("""
                INSERT INTO aether.mission_asset_assignment(id_mission, id_asset, assigned_from, assigned_to)
                SELECT m.id_mission, a.id_asset, m.planned_start_at, m.planned_end_at
                FROM aether.mission m, aether.asset a WHERE m.code = 'PHX-009' AND a.code = 'ROV-VLM-01'"""))
                .isInstanceOf(DataIntegrityViolationException.class)
                .hasMessageContaining("ex_asset_no_overlapping_missions");
    }

    @Test
    void rejectsConsumingFromAnEmptyStock() {
        // The Elysium emergency locker has no medical kits left (BR-007).
        assertThatThrownBy(() -> jdbc.update("""
                UPDATE aether.inventory_stock st SET quantity = quantity - 1
                FROM aether.inventory_location l, aether.resource r
                WHERE l.id_location = st.id_location AND r.id_resource = st.id_resource
                  AND l.code = 'EMERG-01' AND r.code = 'MED_KIT'"""))
                .isInstanceOf(DataIntegrityViolationException.class)
                .hasMessageContaining("ck_inventory_quantity_nonnegative");
    }

    @Test
    void rejectsReusingAnExistingCrewCode() {
        assertThatThrownBy(() -> jdbc.update("""
                INSERT INTO aether.crew_member(id_person, employee_code, operational_role)
                SELECT id_person, 'CRW-001', 'Pilot' FROM aether.person WHERE email = 'laura.rossi@aether.demo'"""))
                .isInstanceOf(DataIntegrityViolationException.class)
                .hasMessageContaining("employee_code");
    }

    private long count(String sql) {
        Long value = jdbc.queryForObject(sql, Long.class);
        return value == null ? 0 : value;
    }
}
