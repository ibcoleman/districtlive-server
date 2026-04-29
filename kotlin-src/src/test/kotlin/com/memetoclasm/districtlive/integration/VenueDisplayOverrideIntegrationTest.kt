package com.memetoclasm.districtlive.integration

import com.memetoclasm.districtlive.event.EventStatus
import com.memetoclasm.districtlive.event.dto.VenueMapper
import com.memetoclasm.districtlive.event.jpa.EventEntity
import com.memetoclasm.districtlive.event.jpa.JpaEventRepository
import com.memetoclasm.districtlive.event.jpa.JpaVenueRepository
import com.memetoclasm.districtlive.event.jpa.VenueEntity
import com.memetoclasm.districtlive.event.service.EventService
import org.junit.jupiter.api.AfterEach
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertNotNull
import org.junit.jupiter.api.Assertions.assertNull
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.context.SpringBootTest
import org.springframework.boot.testcontainers.service.connection.ServiceConnection
import org.springframework.data.domain.PageRequest
import org.springframework.jdbc.core.JdbcTemplate
import org.testcontainers.containers.PostgreSQLContainer
import org.testcontainers.junit.jupiter.Container
import org.testcontainers.junit.jupiter.Testcontainers
import java.time.Instant

/**
 * Integration test verifying venue display override columns, mapper resolution,
 * event filter behavior, and resolveVenue matching.
 *
 * Uses a real PostgreSQL 16 container via Testcontainers. Flyway runs all
 * migrations (V1–V15) automatically on startup. Do NOT use @ActiveProfiles("integration")
 * — that profile disables Flyway and uses H2.
 *
 * Covers: venue-name-sanitize.AC1.1–AC1.4, AC2.1–AC2.4, AC3.1–AC3.4, AC4.1–AC4.3, AC5.1–AC5.2
 */
@SpringBootTest
@Testcontainers
class VenueDisplayOverrideIntegrationTest {

    companion object {
        @Container
        @ServiceConnection
        @JvmStatic
        val postgres: PostgreSQLContainer<*> = PostgreSQLContainer("postgres:16-alpine")
    }

    @Autowired
    private lateinit var venueRepository: JpaVenueRepository

    @Autowired
    private lateinit var eventRepository: JpaEventRepository

    @Autowired
    private lateinit var eventService: EventService

    @Autowired
    private lateinit var venueMapper: VenueMapper

    @Autowired
    private lateinit var jdbcTemplate: JdbcTemplate

    // IDs for test-inserted rows so we can clean them up in @AfterEach
    private val insertedEventIds = mutableListOf<java.util.UUID>()
    private val insertedVenueIds = mutableListOf<java.util.UUID>()

    @BeforeEach
    fun insertTestFixtures() {
        // Insert the Kennedy Center venue with display overrides.
        // V15 migration's UPDATE is a no-op in a fresh DB (row doesn't exist in seed data).
        // We insert it here as test fixture data to verify column persistence and filter behavior.
        val kennedyCenter = venueRepository.save(
            VenueEntity(
                name = "Trump Kennedy Center - Concert Hall",
                slug = "trump-kennedy-center-concert-hall",
                displayName = "The Kennedy Center",
                displaySlug = "the-kennedy-center",
                address = "2700 F St NW, Washington, DC 20566",
                neighborhood = "Foggy Bottom"
            )
        )
        insertedVenueIds += kennedyCenter.id

        // Insert a test event linked to the Kennedy Center
        val kennedyCenterEvent = eventRepository.save(
            EventEntity(
                title = "Kennedy Center Test Concert",
                slug = "kennedy-center-test-concert-${System.currentTimeMillis()}",
                startTime = Instant.parse("2026-06-01T20:00:00Z"),
                status = EventStatus.ACTIVE,
                venue = kennedyCenter
            )
        )
        insertedEventIds += kennedyCenterEvent.id

        // Insert a test event linked to Black Cat (seeded by V8 — load it, don't insert)
        val blackCat = venueRepository.findBySlug("black-cat")
            ?: error("Black Cat venue not found — V8 seed migration must have run")
        val blackCatEvent = eventRepository.save(
            EventEntity(
                title = "Black Cat Test Show",
                slug = "black-cat-test-show-${System.currentTimeMillis()}",
                startTime = Instant.parse("2026-06-02T21:00:00Z"),
                status = EventStatus.ACTIVE,
                venue = blackCat
            )
        )
        insertedEventIds += blackCatEvent.id
    }

    @AfterEach
    fun cleanUpTestFixtures() {
        // Delete test-inserted events first (FK constraint: events reference venues)
        insertedEventIds.forEach { id -> eventRepository.deleteById(id) }
        insertedEventIds.clear()

        // Delete test-inserted venues (Black Cat is seeded — never delete it)
        insertedVenueIds.forEach { id -> venueRepository.deleteById(id) }
        insertedVenueIds.clear()
    }

    // -------------------------------------------------------------------------
    // AC1: Schema verification — display_name and display_slug columns exist
    // -------------------------------------------------------------------------

    @Test
    fun `AC1-1 display_name column exists on venues table with correct type and nullability`() {
        // venue-name-sanitize.AC1.1
        val row = jdbcTemplate.queryForMap(
            """
            SELECT data_type, character_maximum_length, is_nullable
            FROM information_schema.columns
            WHERE table_schema = 'public'
              AND table_name = 'venues'
              AND column_name = 'display_name'
            """.trimIndent()
        )
        assertEquals("character varying", row["data_type"], "display_name must be VARCHAR")
        assertEquals(255, (row["character_maximum_length"] as Number).toInt(), "display_name must be VARCHAR(255)")
        assertEquals("YES", row["is_nullable"], "display_name must be nullable")
    }

    @Test
    fun `AC1-2 display_slug column exists on venues table with correct type and nullability`() {
        // venue-name-sanitize.AC1.2
        val row = jdbcTemplate.queryForMap(
            """
            SELECT data_type, character_maximum_length, is_nullable
            FROM information_schema.columns
            WHERE table_schema = 'public'
              AND table_name = 'venues'
              AND column_name = 'display_slug'
            """.trimIndent()
        )
        assertEquals("character varying", row["data_type"], "display_slug must be VARCHAR")
        assertEquals(255, (row["character_maximum_length"] as Number).toInt(), "display_slug must be VARCHAR(255)")
        assertEquals("YES", row["is_nullable"], "display_slug must be nullable")
    }

    @Test
    fun `AC1-3 venues without override have null display columns`() {
        // venue-name-sanitize.AC1.3: Black Cat has no overrides — both columns null
        val blackCat = venueRepository.findBySlug("black-cat")
            ?: error("Black Cat venue not found")
        assertNull(blackCat.displayName, "Black Cat displayName must be null")
        assertNull(blackCat.displaySlug, "Black Cat displaySlug must be null")
    }

    @Test
    fun `AC1-4 pre-existing seeded venues are unmodified by V15 migration`() {
        // venue-name-sanitize.AC1.4: Black Cat source name and slug unchanged
        val blackCat = venueRepository.findBySlug("black-cat")
            ?: error("Black Cat venue not found")
        assertEquals("Black Cat", blackCat.name)
        assertEquals("black-cat", blackCat.slug)
    }

    // -------------------------------------------------------------------------
    // AC2: VenueMapper resolves effective name and slug
    // -------------------------------------------------------------------------

    @Test
    fun `AC2-1 toDto uses displayName when set`() {
        // venue-name-sanitize.AC2.1: Kennedy Center with displayName set
        val entity = venueRepository.findBySlug("trump-kennedy-center-concert-hall")
            ?: error("Kennedy Center venue not found")
        val dto = venueMapper.toDto(entity)
        assertEquals("The Kennedy Center", dto.name)
    }

    @Test
    fun `AC2-2 toDto uses displaySlug when set`() {
        // venue-name-sanitize.AC2.2: Kennedy Center with displaySlug set
        val entity = venueRepository.findBySlug("trump-kennedy-center-concert-hall")
            ?: error("Kennedy Center venue not found")
        val dto = venueMapper.toDto(entity)
        assertEquals("the-kennedy-center", dto.slug)
    }

    @Test
    fun `AC2-3 toDto falls back to source name when displayName is null`() {
        // venue-name-sanitize.AC2.3: Black Cat has no displayName override
        val entity = venueRepository.findBySlug("black-cat")
            ?: error("Black Cat venue not found")
        val dto = venueMapper.toDto(entity)
        assertEquals("Black Cat", dto.name)
    }

    @Test
    fun `AC2-4 toDto falls back to source slug when displaySlug is null`() {
        // venue-name-sanitize.AC2.4: Black Cat has no displaySlug override
        val entity = venueRepository.findBySlug("black-cat")
            ?: error("Black Cat venue not found")
        val dto = venueMapper.toDto(entity)
        assertEquals("black-cat", dto.slug)
    }

    // -------------------------------------------------------------------------
    // AC3: Event filter accepts both source and display slug
    // -------------------------------------------------------------------------

    @Test
    fun `AC3-1 findEvents by display slug returns Kennedy Center events`() {
        // venue-name-sanitize.AC3.1: filter by displaySlug "the-kennedy-center"
        val pageable = PageRequest.of(0, 20)
        val result = eventService.findEvents(venueSlug = "the-kennedy-center", pageable = pageable)
        val page = result.getOrNull() ?: error("findEvents returned Left")
        val titles = page.content.map { it.title }
        assert(titles.any { it == "Kennedy Center Test Concert" }) {
            "Expected 'Kennedy Center Test Concert' in results; got: $titles"
        }
    }

    @Test
    fun `AC3-2 findEvents by source slug returns Kennedy Center events (backward compat)`() {
        // venue-name-sanitize.AC3.2: filter by source slug "trump-kennedy-center-concert-hall"
        val pageable = PageRequest.of(0, 20)
        val result = eventService.findEvents(venueSlug = "trump-kennedy-center-concert-hall", pageable = pageable)
        val page = result.getOrNull() ?: error("findEvents returned Left")
        val titles = page.content.map { it.title }
        assert(titles.any { it == "Kennedy Center Test Concert" }) {
            "Expected 'Kennedy Center Test Concert' in results; got: $titles"
        }
    }

    @Test
    fun `AC3-3 findEvents by non-overridden venue slug returns correct events`() {
        // venue-name-sanitize.AC3.3: filter by "black-cat" returns Black Cat events only
        val pageable = PageRequest.of(0, 20)
        val result = eventService.findEvents(venueSlug = "black-cat", pageable = pageable)
        val page = result.getOrNull() ?: error("findEvents returned Left")
        val titles = page.content.map { it.title }
        assert(titles.any { it == "Black Cat Test Show" }) {
            "Expected 'Black Cat Test Show' in results; got: $titles"
        }
        assert(titles.none { it.contains("Kennedy Center") }) {
            "Kennedy Center event must not appear in black-cat filter; got: $titles"
        }
    }

    @Test
    fun `AC3-4 findEvents by nonexistent slug returns empty result`() {
        // venue-name-sanitize.AC3.4: no error, just empty page
        val pageable = PageRequest.of(0, 20)
        val result = eventService.findEvents(venueSlug = "nonexistent-slug", pageable = pageable)
        val page = result.getOrNull() ?: error("findEvents returned Left")
        assertEquals(0, page.totalElements, "Expected empty page for nonexistent slug")
    }

    // -------------------------------------------------------------------------
    // AC4: Kennedy Center override columns persist correctly
    // -------------------------------------------------------------------------

    @Test
    fun `AC4-1 Kennedy Center displayName persists as The Kennedy Center`() {
        // venue-name-sanitize.AC4.1
        val entity = venueRepository.findBySlug("trump-kennedy-center-concert-hall")
            ?: error("Kennedy Center venue not found")
        assertEquals("The Kennedy Center", entity.displayName)
    }

    @Test
    fun `AC4-2 Kennedy Center displaySlug persists as the-kennedy-center`() {
        // venue-name-sanitize.AC4.2
        val entity = venueRepository.findBySlug("trump-kennedy-center-concert-hall")
            ?: error("Kennedy Center venue not found")
        assertEquals("the-kennedy-center", entity.displaySlug)
    }

    @Test
    fun `AC4-3 Kennedy Center source name column is preserved unchanged`() {
        // venue-name-sanitize.AC4.3: source name still holds the original scraped name
        val entity = venueRepository.findBySlug("trump-kennedy-center-concert-hall")
            ?: error("Kennedy Center venue not found")
        assertEquals("Trump Kennedy Center - Concert Hall", entity.name)
    }

    // -------------------------------------------------------------------------
    // AC5: resolveVenue() matching — findByNameIgnoreCase behavior
    // -------------------------------------------------------------------------

    @Test
    fun `AC5-1 findByNameIgnoreCase resolves Kennedy Center by source name`() {
        // venue-name-sanitize.AC5.1: same query resolveVenue() uses internally
        val entity = venueRepository.findByNameIgnoreCase("Trump Kennedy Center - Concert Hall")
        assertNotNull(entity, "Expected to find Kennedy Center by source name")
        assertEquals("trump-kennedy-center-concert-hall", entity!!.slug)
    }

    @Test
    fun `AC5-2 findByNameIgnoreCase returns null for unknown venue name`() {
        // venue-name-sanitize.AC5.2: unknown venue → null → auto-create triggered
        val entity = venueRepository.findByNameIgnoreCase("Some Brand New Venue That Does Not Exist")
        assertNull(entity, "Expected null for unknown venue name")
    }
}
