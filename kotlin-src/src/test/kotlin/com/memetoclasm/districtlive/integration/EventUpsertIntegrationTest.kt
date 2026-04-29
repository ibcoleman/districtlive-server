package com.memetoclasm.districtlive.integration

import com.memetoclasm.districtlive.event.AgeRestriction
import com.memetoclasm.districtlive.event.EventRepositoryPort
import com.memetoclasm.districtlive.event.EventSourceAttribution
import com.memetoclasm.districtlive.event.EventUpsertCommand
import com.memetoclasm.districtlive.event.SourceType
import com.memetoclasm.districtlive.event.UpsertResult
import com.memetoclasm.districtlive.event.jpa.JpaArtistRepository
import com.memetoclasm.districtlive.event.jpa.JpaEventRepository
import com.memetoclasm.districtlive.event.jpa.JpaEventSourceRepository
import com.memetoclasm.districtlive.event.jpa.JpaVenueRepository
import org.junit.jupiter.api.AfterEach
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertNotNull
import org.junit.jupiter.api.Assertions.assertNull
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.context.SpringBootTest
import org.springframework.boot.testcontainers.service.connection.ServiceConnection
import org.springframework.dao.DataIntegrityViolationException
import org.springframework.jdbc.core.JdbcTemplate
import org.testcontainers.containers.PostgreSQLContainer
import org.testcontainers.junit.jupiter.Container
import org.testcontainers.junit.jupiter.Testcontainers
import java.math.BigDecimal
import java.time.Instant
import java.util.UUID

/**
 * Integration test verifying EventRepositoryPort.upsertEvent() behavior.
 *
 * Uses a real PostgreSQL 16 container via Testcontainers. Flyway runs all
 * migrations (V1–V17) automatically on startup. Tests verify persistence
 * boundary fixes: lazy initialization is prevented via @Transactional on the
 * port implementation, and duplicate key errors are caught as Either.Left.
 *
 * Covers: ingestion-reliability.AC1.1, AC1.2, AC1.3
 */
@SpringBootTest
@Testcontainers
class EventUpsertIntegrationTest {

    companion object {
        @Container
        @ServiceConnection
        @JvmStatic
        val postgres: PostgreSQLContainer<*> = PostgreSQLContainer("postgres:16-alpine")
    }

    @Autowired
    private lateinit var eventRepositoryPort: EventRepositoryPort

    @Autowired
    private lateinit var eventRepository: JpaEventRepository

    @Autowired
    private lateinit var venueRepository: JpaVenueRepository

    @Autowired
    private lateinit var artistRepository: JpaArtistRepository

    @Autowired
    private lateinit var eventSourceRepository: JpaEventSourceRepository

    @Autowired
    private lateinit var jdbcTemplate: JdbcTemplate

    private val testEventSlugs = mutableListOf<String>()
    private val testVenueSlugs = mutableListOf<String>()
    private val testArtistSlugs = mutableListOf<String>()

    @AfterEach
    fun cleanUpTestData() {
        // Delete events by slug
        testEventSlugs.forEach { slug ->
            eventRepository.findBySlug(slug)?.let { event ->
                eventRepository.deleteById(event.id)
            }
        }
        testEventSlugs.clear()

        // Delete artists by slug
        testArtistSlugs.forEach { slug ->
            artistRepository.findBySlug(slug)?.let { artist ->
                artistRepository.deleteById(artist.id)
            }
        }
        testArtistSlugs.clear()

        // Delete venues by slug
        testVenueSlugs.forEach { slug ->
            venueRepository.findBySlug(slug)?.let { venue ->
                venueRepository.deleteById(venue.id)
            }
        }
        testVenueSlugs.clear()
    }

    // =========================================================================
    // AC1.2: Upsert creates new events with correct data and source attrs
    // =========================================================================

    @Test
    fun `AC1-2 upsertEvent creates new event with all fields populated`() {
        val slug = "test-event-new-${System.currentTimeMillis()}"
        val startTime = Instant.parse("2026-04-15T20:00:00Z")
        val endTime = Instant.parse("2026-04-15T23:00:00Z")

        val command = EventUpsertCommand(
            slug = slug,
            title = "Test Concert",
            description = "A test concert event",
            startTime = startTime,
            endTime = endTime,
            doorsTime = Instant.parse("2026-04-15T19:30:00Z"),
            venueName = "Test Venue",
            venueAddress = "123 Main St",
            artistNames = listOf("Artist One", "Artist Two"),
            minPrice = BigDecimal("25.00"),
            maxPrice = BigDecimal("75.00"),
            priceTier = null,
            ticketUrl = "https://tickets.example.com",
            imageUrl = "https://example.com/image.jpg",
            ageRestriction = AgeRestriction.EIGHTEEN_PLUS,
            sourceAttributions = listOf(
                EventSourceAttribution(
                    sourceType = SourceType.TICKETMASTER_API,
                    sourceIdentifier = "tm-123456",
                    sourceUrl = "https://ticketmaster.com/event/123456",
                    confidenceScore = BigDecimal("0.95")
                )
            )
        )

        testEventSlugs += slug
        testVenueSlugs += "test-venue"
        testArtistSlugs += "artist-one"
        testArtistSlugs += "artist-two"

        val result = eventRepositoryPort.upsertEvent(command)

        assertTrue(result.isRight(), "upsertEvent should return Right")
        val upsertResult = result.fold({ null }, { it })
        assertTrue(upsertResult is UpsertResult.Created, "Result should be Created")

        val createdId = (upsertResult as UpsertResult.Created).eventId
        val event = eventRepository.findById(createdId).orElse(null)

        assertNotNull(event, "Event should exist in database")
        assertEquals("Test Concert", event!!.title)
        assertEquals(slug, event.slug)
        assertEquals("A test concert event", event.description)
        assertEquals(startTime, event.startTime)
        assertEquals(endTime, event.endTime)
        assertEquals(AgeRestriction.EIGHTEEN_PLUS, event.ageRestriction)
        assertEquals(BigDecimal("25.00"), event.minPrice)
        assertEquals(BigDecimal("75.00"), event.maxPrice)
        assertEquals("https://tickets.example.com", event.ticketUrl)
        assertEquals("https://example.com/image.jpg", event.imageUrl)

        val venue = event.venue
        assertNotNull(venue, "Event should have venue")
        assertEquals("Test Venue", venue!!.name)
        assertEquals("test-venue", venue.slug)
        assertEquals("123 Main St", venue.address)

        assertEquals(2, event.artists.size, "Event should have 2 artists")
        val artistNames = event.artists.map { it.name }.sorted()
        assertEquals(listOf("Artist One", "Artist Two"), artistNames)

        val sources = eventSourceRepository.findByEventId(event.id)
        assertEquals(1, sources.size, "Event should have 1 source attribution")
        val source = sources[0]
        assertEquals(SourceType.TICKETMASTER_API, source.sourceType)
        assertEquals("tm-123456", source.sourceIdentifier)
        assertEquals("https://ticketmaster.com/event/123456", source.sourceUrl)
        assertEquals(BigDecimal("0.95"), source.confidenceScore)
    }

    @Test
    fun `AC1-2 upsertEvent auto-creates venue with null address`() {
        val slug = "test-no-address-${System.currentTimeMillis()}"
        val command = EventUpsertCommand(
            slug = slug,
            title = "Show with null venue address",
            description = null,
            startTime = Instant.parse("2026-04-16T20:00:00Z"),
            endTime = null,
            doorsTime = null,
            venueName = "Venue No Address",
            venueAddress = null,
            artistNames = emptyList(),
            minPrice = null,
            maxPrice = null,
            priceTier = null,
            ticketUrl = null,
            imageUrl = null,
            ageRestriction = AgeRestriction.ALL_AGES,
            sourceAttributions = emptyList()
        )

        testEventSlugs += slug
        testVenueSlugs += "venue-no-address"

        val result = eventRepositoryPort.upsertEvent(command)
        assertTrue(result.isRight(), "upsertEvent should return Right")

        val event = eventRepository.findBySlug(slug)
        assertNotNull(event, "Event should exist")
        assertNotNull(event!!.venue, "Event should have venue")
        assertEquals("Venue No Address", event.venue!!.name)
        assertNull(event.venue!!.address, "Venue address should be null")
    }

    @Test
    fun `AC1-2 upsertEvent with null venueName creates event without venue`() {
        val slug = "test-no-venue-${System.currentTimeMillis()}"
        val command = EventUpsertCommand(
            slug = slug,
            title = "Virtual event",
            description = null,
            startTime = Instant.parse("2026-04-17T20:00:00Z"),
            endTime = null,
            doorsTime = null,
            venueName = null,
            venueAddress = null,
            artistNames = listOf("Virtual Artist"),
            minPrice = null,
            maxPrice = null,
            priceTier = null,
            ticketUrl = null,
            imageUrl = null,
            ageRestriction = AgeRestriction.ALL_AGES,
            sourceAttributions = emptyList()
        )

        testEventSlugs += slug
        testArtistSlugs += "virtual-artist"

        val result = eventRepositoryPort.upsertEvent(command)
        assertTrue(result.isRight(), "upsertEvent should return Right")

        val event = eventRepository.findBySlug(slug)
        assertNotNull(event, "Event should exist")
        assertNull(event!!.venue, "Event should have no venue")
    }

    // =========================================================================
    // AC1.1: Upsert updates existing events and adds new source attributions
    // =========================================================================

    @Test
    fun `AC1-1 upsertEvent updates existing event and adds source attribution`() {
        val slug = "test-event-update-${System.currentTimeMillis()}"

        // First insert
        val command1 = EventUpsertCommand(
            slug = slug,
            title = "Original Title",
            description = "Original description",
            startTime = Instant.parse("2026-04-18T20:00:00Z"),
            endTime = null,
            doorsTime = null,
            venueName = "Original Venue",
            venueAddress = "Original Address",
            artistNames = listOf("Original Artist"),
            minPrice = null,
            maxPrice = null,
            priceTier = null,
            ticketUrl = null,
            imageUrl = null,
            ageRestriction = AgeRestriction.ALL_AGES,
            sourceAttributions = listOf(
                EventSourceAttribution(
                    sourceType = SourceType.BANDSINTOWN_API,
                    sourceIdentifier = "bit-111",
                    sourceUrl = null,
                    confidenceScore = BigDecimal("0.80")
                )
            )
        )

        testEventSlugs += slug
        testVenueSlugs += "original-venue"
        testArtistSlugs += "original-artist"

        val result1 = eventRepositoryPort.upsertEvent(command1)
        assertTrue(result1.isRight(), "First upsert should succeed")
        assertTrue(result1.fold({ null }, { it }) is UpsertResult.Created, "First result should be Created")

        val event1 = eventRepository.findBySlug(slug)
        assertNotNull(event1, "Event should exist after first upsert")
        assertEquals("Original Title", event1!!.title)
        assertEquals(1, eventSourceRepository.findByEventId(event1.id).size)

        // Second upsert with different title and new source attribution
        val command2 = EventUpsertCommand(
            slug = slug,
            title = "Updated Title",
            description = "Updated description",
            startTime = Instant.parse("2026-04-18T21:00:00Z"),
            endTime = null,
            doorsTime = null,
            venueName = "Original Venue",
            venueAddress = "Original Address",
            artistNames = listOf("Original Artist"),
            minPrice = null,
            maxPrice = null,
            priceTier = null,
            ticketUrl = "https://new-url.com",
            imageUrl = null,
            ageRestriction = AgeRestriction.ALL_AGES,
            sourceAttributions = listOf(
                EventSourceAttribution(
                    sourceType = SourceType.BANDSINTOWN_API,
                    sourceIdentifier = "bit-111",
                    sourceUrl = null,
                    confidenceScore = BigDecimal("0.80")
                ),
                EventSourceAttribution(
                    sourceType = SourceType.VENUE_SCRAPER,
                    sourceIdentifier = "blackcat-222",
                    sourceUrl = "https://blackcat.com/event/222",
                    confidenceScore = BigDecimal("0.85")
                )
            )
        )

        val result2 = eventRepositoryPort.upsertEvent(command2)
        assertTrue(result2.isRight(), "Second upsert should succeed")
        assertTrue(result2.fold({ null }, { it }) is UpsertResult.Updated, "Second result should be Updated")

        val event2 = eventRepository.findBySlug(slug)
        assertNotNull(event2, "Event should still exist after update")
        assertEquals("Updated Title", event2!!.title)
        assertEquals("Updated description", event2.description)
        assertEquals(Instant.parse("2026-04-18T21:00:00Z"), event2.startTime)
        assertEquals("https://new-url.com", event2.ticketUrl)

        // Both source attributions should be present
        val sources = eventSourceRepository.findByEventId(event2.id)
        assertEquals(2, sources.size, "Event should now have 2 source attributions")
        val sourceIds = sources.map { it.sourceIdentifier }.sortedBy { it }
        assertEquals(listOf("bit-111", "blackcat-222"), sourceIds)
    }

    @Test
    fun `AC1-1 upsertEvent resolves existing venue by name without creating duplicate`() {
        val venueName = "Kennedy Center"
        val slug1 = "test-show-1-${System.currentTimeMillis()}"
        val slug2 = "test-show-2-${System.currentTimeMillis()}"

        testEventSlugs += slug1
        testEventSlugs += slug2
        testVenueSlugs += "kennedy-center"

        // First event creates the venue
        val command1 = EventUpsertCommand(
            slug = slug1,
            title = "Show 1",
            description = null,
            startTime = Instant.parse("2026-04-19T20:00:00Z"),
            endTime = null,
            doorsTime = null,
            venueName = venueName,
            venueAddress = "2700 F St NW",
            artistNames = emptyList(),
            minPrice = null,
            maxPrice = null,
            priceTier = null,
            ticketUrl = null,
            imageUrl = null,
            ageRestriction = AgeRestriction.ALL_AGES,
            sourceAttributions = emptyList()
        )

        eventRepositoryPort.upsertEvent(command1)
        val venue1 = venueRepository.findByNameIgnoreCase(venueName)
        assertNotNull(venue1, "Venue should be created")

        // Second event should resolve the same venue (not create a new one)
        val command2 = EventUpsertCommand(
            slug = slug2,
            title = "Show 2",
            description = null,
            startTime = Instant.parse("2026-04-20T20:00:00Z"),
            endTime = null,
            doorsTime = null,
            venueName = venueName,
            venueAddress = "2700 F St NW",
            artistNames = emptyList(),
            minPrice = null,
            maxPrice = null,
            priceTier = null,
            ticketUrl = null,
            imageUrl = null,
            ageRestriction = AgeRestriction.ALL_AGES,
            sourceAttributions = emptyList()
        )

        eventRepositoryPort.upsertEvent(command2)
        val venue2 = venueRepository.findByNameIgnoreCase(venueName)
        assertNotNull(venue2, "Venue should be resolved")
        assertEquals(venue1!!.id, venue2!!.id, "Both events should reference the same venue")
    }

    @Test
    fun `AC1-1 upsertEvent resolves existing artist by name without creating duplicate`() {
        val artistName = "The Beatles"
        val slug1 = "test-beatles-show-1-${System.currentTimeMillis()}"
        val slug2 = "test-beatles-show-2-${System.currentTimeMillis()}"

        testEventSlugs += slug1
        testEventSlugs += slug2
        testArtistSlugs += "the-beatles"

        // First event creates the artist
        val command1 = EventUpsertCommand(
            slug = slug1,
            title = "Beatles Show 1",
            description = null,
            startTime = Instant.parse("2026-04-19T20:00:00Z"),
            endTime = null,
            doorsTime = null,
            venueName = null,
            venueAddress = null,
            artistNames = listOf(artistName),
            minPrice = null,
            maxPrice = null,
            priceTier = null,
            ticketUrl = null,
            imageUrl = null,
            ageRestriction = AgeRestriction.ALL_AGES,
            sourceAttributions = emptyList()
        )

        eventRepositoryPort.upsertEvent(command1)
        val artist1 = artistRepository.findByNameIgnoreCase(artistName)
        assertNotNull(artist1, "Artist should be created")

        // Second event should resolve the same artist (not create a new one)
        val command2 = EventUpsertCommand(
            slug = slug2,
            title = "Beatles Show 2",
            description = null,
            startTime = Instant.parse("2026-04-20T20:00:00Z"),
            endTime = null,
            doorsTime = null,
            venueName = null,
            venueAddress = null,
            artistNames = listOf(artistName),
            minPrice = null,
            maxPrice = null,
            priceTier = null,
            ticketUrl = null,
            imageUrl = null,
            ageRestriction = AgeRestriction.ALL_AGES,
            sourceAttributions = emptyList()
        )

        eventRepositoryPort.upsertEvent(command2)
        val artist2 = artistRepository.findByNameIgnoreCase(artistName)
        assertNotNull(artist2, "Artist should be resolved")
        assertEquals(artist1!!.id, artist2!!.id, "Both events should reference the same artist")
    }

    // =========================================================================
    // AC2.1: Duplicate events prevented at database level — upsert behavior
    // =========================================================================

    @Test
    fun `AC2-1 upsertEvent with duplicate slug updates existing event without creating duplicate row`() {
        val slug = "test-dup-prevent-${System.currentTimeMillis()}"

        // First insert
        val command1 = EventUpsertCommand(
            slug = slug,
            title = "Original Title",
            description = "Original description",
            startTime = Instant.parse("2026-04-21T20:00:00Z"),
            endTime = null,
            doorsTime = null,
            venueName = "Test Venue",
            venueAddress = "123 Main St",
            artistNames = emptyList(),
            minPrice = null,
            maxPrice = null,
            priceTier = null,
            ticketUrl = null,
            imageUrl = null,
            ageRestriction = AgeRestriction.ALL_AGES,
            sourceAttributions = emptyList()
        )

        testEventSlugs += slug
        testVenueSlugs += "test-venue"

        val result1 = eventRepositoryPort.upsertEvent(command1)
        assertTrue(result1.isRight(), "First upsert should succeed")
        assertTrue(result1.fold({ null }, { it }) is UpsertResult.Created, "First result should be Created")

        // Verify exactly one event with this slug exists
        val count1 = jdbcTemplate.queryForObject(
            "SELECT COUNT(*) FROM events WHERE slug = ?",
            arrayOf(slug),
            Int::class.java
        )
        assertEquals(1, count1, "Should have exactly one event with this slug after first upsert")

        // Second upsert with same slug but different title
        val command2 = EventUpsertCommand(
            slug = slug,
            title = "Updated Title",
            description = "Updated description",
            startTime = Instant.parse("2026-04-21T21:00:00Z"),
            endTime = null,
            doorsTime = null,
            venueName = "Test Venue",
            venueAddress = "123 Main St",
            artistNames = emptyList(),
            minPrice = null,
            maxPrice = null,
            priceTier = null,
            ticketUrl = null,
            imageUrl = null,
            ageRestriction = AgeRestriction.ALL_AGES,
            sourceAttributions = emptyList()
        )

        val result2 = eventRepositoryPort.upsertEvent(command2)
        assertTrue(result2.isRight(), "Second upsert should succeed")
        assertTrue(result2.fold({ null }, { it }) is UpsertResult.Updated, "Second result should be Updated")

        // Verify still exactly one event with this slug
        val count2 = jdbcTemplate.queryForObject(
            "SELECT COUNT(*) FROM events WHERE slug = ?",
            arrayOf(slug),
            Int::class.java
        )
        assertEquals(1, count2, "Should still have exactly one event with this slug after second upsert")

        // Verify the event was updated with new values
        val event = eventRepository.findBySlug(slug)
        assertNotNull(event, "Event should exist")
        assertEquals("Updated Title", event!!.title)
        assertEquals("Updated description", event.description)
    }

    // =========================================================================
    // AC2.3: Raw SQL INSERT with duplicate slug is rejected by UNIQUE constraint
    // =========================================================================

    @Test
    fun `AC2-3 raw SQL INSERT with duplicate slug throws DataIntegrityViolationException with uq_events_slug constraint`() {
        val slug = "test-raw-sql-dup-${System.currentTimeMillis()}"

        // First insert an event via upsert
        val command = EventUpsertCommand(
            slug = slug,
            title = "First Event",
            description = null,
            startTime = Instant.parse("2026-04-22T20:00:00Z"),
            endTime = null,
            doorsTime = null,
            venueName = null,
            venueAddress = null,
            artistNames = emptyList(),
            minPrice = null,
            maxPrice = null,
            priceTier = null,
            ticketUrl = null,
            imageUrl = null,
            ageRestriction = AgeRestriction.ALL_AGES,
            sourceAttributions = emptyList()
        )

        testEventSlugs += slug

        val result = eventRepositoryPort.upsertEvent(command)
        assertTrue(result.isRight(), "First upsert should succeed")

        // Now try to insert a second event with the same slug via raw SQL
        val newId = UUID.randomUUID()
        var exceptionThrown = false
        var exceptionMessage = ""

        try {
            jdbcTemplate.update(
                "INSERT INTO events (id, title, slug, start_time, age_restriction) VALUES (?, ?, ?, ?, ?)",
                newId,
                "Second Event",
                slug,
                "2026-04-22T21:00:00Z",
                "ALL_AGES"
            )
        } catch (e: DataIntegrityViolationException) {
            exceptionThrown = true
            exceptionMessage = e.message ?: ""
        }

        assertTrue(exceptionThrown, "DataIntegrityViolationException should be thrown for duplicate slug")
        assertTrue(
            exceptionMessage.contains("uq_events_slug") || exceptionMessage.contains("unique constraint"),
            "Exception message should mention uq_events_slug constraint: $exceptionMessage"
        )
    }

    @Test
    fun `UNIQUE constraint uq_events_slug exists on events table`() {
        val constraintExists = jdbcTemplate.queryForObject(
            """
            SELECT EXISTS (
                SELECT 1 FROM information_schema.table_constraints
                WHERE table_name = 'events' AND constraint_type = 'UNIQUE' AND constraint_name = 'uq_events_slug'
            )
            """.trimIndent(),
            Boolean::class.javaObjectType
        ) ?: false

        assertTrue(constraintExists, "UNIQUE constraint uq_events_slug should exist on events table")
    }

    @Test
    fun `source health is reset after migration`() {
        // All sources should be healthy with zero consecutive failures
        val healthyCount = jdbcTemplate.queryForObject(
            "SELECT COUNT(*) FROM sources WHERE healthy = true AND consecutive_failures = 0",
            Int::class.java
        )
        val totalCount = jdbcTemplate.queryForObject(
            "SELECT COUNT(*) FROM sources",
            Int::class.java
        )

        assertEquals(
            totalCount,
            healthyCount,
            "All sources should be healthy with zero consecutive failures"
        )
    }
}
