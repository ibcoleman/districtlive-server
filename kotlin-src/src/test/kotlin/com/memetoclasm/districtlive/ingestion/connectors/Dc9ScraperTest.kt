package com.memetoclasm.districtlive.ingestion.connectors

import com.fasterxml.jackson.databind.ObjectMapper
import com.memetoclasm.districtlive.event.SourceType
import org.jsoup.Jsoup
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.DisplayName
import java.math.BigDecimal
import java.time.ZoneId
import java.time.ZonedDateTime
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

@DisplayName("Dc9Scraper Tests")
class Dc9ScraperTest {

    private val objectMapper = ObjectMapper().apply { findAndRegisterModules() }

    private lateinit var scraper: TestableDc9Scraper
    private lateinit var fixtureHtml: String

    @BeforeEach
    fun setup() {
        scraper = TestableDc9Scraper(objectMapper)
        fixtureHtml = javaClass.classLoader?.getResourceAsStream("fixtures/dc9-events.html")
            ?.bufferedReader()?.readText()
            ?: throw IllegalStateException("Could not load fixture: fixtures/dc9-events.html")
    }

    @Test
    @DisplayName("Extracts valid events from DC9 homepage HTML")
    fun testExtractsValidEvents() {
        val document = Jsoup.parse(fixtureHtml)
        val result = scraper.extractEvents(document)

        // Should extract 4 events: skips blank title (10004) and duplicate (10002 second occurrence)
        assertEquals(4, result.size, "Should extract 4 valid, unique events")
    }

    @Test
    @DisplayName("Parses first event with all fields correctly")
    fun testParsesFirstEventCorrectly() {
        val document = Jsoup.parse(fixtureHtml)
        val result = scraper.extractEvents(document)

        val event = result.find { it.title == "Test Band Live" }
        assertNotNull(event, "Should find 'Test Band Live' event")
        assertEquals("DC9", event.venueName)
        assertEquals("1940 9th St NW, Washington, DC 20001", event.venueAddress)
        assertEquals(SourceType.VENUE_SCRAPER, event.sourceType)
        assertEquals(BigDecimal("0.70"), event.confidenceScore)
        assertEquals("https://link.dice.fm/abc123", event.ticketUrl)
        assertEquals("https://dc9.club/event/test-band-live/", event.sourceUrl)
        assertEquals("https://dc9.club/wp-content/uploads/2026/03/test-band-1300x1300.jpg", event.imageUrl)
        assertNotNull(event.startTime, "Should have parsed start time")

        // Verify start time is 8pm ET (show time)
        val zdt = ZonedDateTime.ofInstant(event.startTime, ZoneId.of("America/New_York"))
        assertEquals(20, zdt.hour, "Show time should be 8pm (20:00)")
        assertEquals(21, zdt.dayOfMonth, "Should be March 21")

        // Doors time should be separate (7pm)
        assertNotNull(event.doorsTime, "Should have doors time when different from show time")
        val doorsZdt = ZonedDateTime.ofInstant(event.doorsTime, ZoneId.of("America/New_York"))
        assertEquals(19, doorsZdt.hour, "Doors time should be 7pm (19:00)")
    }

    @Test
    @DisplayName("Handles late night event with same doors/show time")
    fun testLateNightSameDoorsAndShowTime() {
        val document = Jsoup.parse(fixtureHtml)
        val result = scraper.extractEvents(document)

        val event = result.find { it.title == "DJ Night Party" }
        assertNotNull(event)
        assertNotNull(event.startTime)

        val zdt = ZonedDateTime.ofInstant(event.startTime, ZoneId.of("America/New_York"))
        assertEquals(23, zdt.hour, "11pm show should be hour 23")

        // When doors == show, doorsTime should be null (no need to duplicate)
        assertNull(event.doorsTime, "Doors time should be null when same as show time")
    }

    @Test
    @DisplayName("Handles event with no date or ticket link")
    fun testEventWithNoDateOrTicket() {
        val document = Jsoup.parse(fixtureHtml)
        val result = scraper.extractEvents(document)

        val event = result.find { it.title == "Pop Up Event" }
        assertNotNull(event, "Should still extract event without date/ticket")
        assertNull(event.startTime, "Start time should be null when no date")
        assertNull(event.ticketUrl, "Ticket URL should be null when not present")
        assertEquals("https://dc9.club/event/pop-up-event/", event.sourceUrl, "Should use detail URL as source URL")
    }

    @Test
    @DisplayName("Skips events with blank titles")
    fun testSkipsBlankTitles() {
        val document = Jsoup.parse(fixtureHtml)
        val result = scraper.extractEvents(document)

        val titles = result.map { it.title }
        assertTrue(titles.none { it.isBlank() }, "Should not include events with blank titles")
    }

    @Test
    @DisplayName("Deduplicates events by listing ID")
    fun testDeduplicatesByListingId() {
        val document = Jsoup.parse(fixtureHtml)
        val result = scraper.extractEvents(document)

        val djEvents = result.filter { it.title == "DJ Night Party" }
        assertEquals(1, djEvents.size, "Should only include one copy of duplicate listing")
    }

    @Test
    @DisplayName("Parses half-hour times correctly")
    fun testParsesHalfHourTimes() {
        val document = Jsoup.parse(fixtureHtml)
        val result = scraper.extractEvents(document)

        val event = result.find { it.title == "Acoustic Night" }
        assertNotNull(event)
        assertNotNull(event.startTime)

        val zdt = ZonedDateTime.ofInstant(event.startTime, ZoneId.of("America/New_York"))
        assertEquals(19, zdt.hour, "7:30pm show should be hour 19")
        assertEquals(30, zdt.minute, "Should have 30 minutes")

        assertNotNull(event.doorsTime)
        val doorsZdt = ZonedDateTime.ofInstant(event.doorsTime, ZoneId.of("America/New_York"))
        assertEquals(18, doorsZdt.hour, "6:30pm doors should be hour 18")
        assertEquals(30, doorsZdt.minute, "Doors should have 30 minutes")
    }

    @Test
    @DisplayName("All events have required fields set")
    fun testAllEventsHaveRequiredFields() {
        val document = Jsoup.parse(fixtureHtml)
        val result = scraper.extractEvents(document)

        result.forEach { event ->
            assertNotNull(event.sourceIdentifier, "Should have sourceIdentifier")
            assertTrue(event.title.isNotBlank(), "Should have non-blank title")
            assertEquals("DC9", event.venueName)
            assertEquals("1940 9th St NW, Washington, DC 20001", event.venueAddress)
            assertEquals(SourceType.VENUE_SCRAPER, event.sourceType)
            assertEquals(BigDecimal("0.70"), event.confidenceScore)
        }
    }

    @Test
    @DisplayName("Generates unique source identifiers")
    fun testGeneratesUniqueSourceIdentifiers() {
        val document = Jsoup.parse(fixtureHtml)
        val result = scraper.extractEvents(document)

        val identifiers = result.map { it.sourceIdentifier }
        assertEquals(identifiers.toSet().size, identifiers.size, "All events should have unique identifiers")
    }

    @Test
    @DisplayName("Returns empty list for page with no events")
    fun testReturnsEmptyListForNoEvents() {
        val emptyHtml = """
            <!DOCTYPE html>
            <html><head><title>DC9</title></head>
            <body><div class="home"></div></body>
            </html>
        """.trimIndent()
        val document = Jsoup.parse(emptyHtml)
        val result = scraper.extractEvents(document)
        assertEquals(emptyList(), result)
    }

    @Test
    @DisplayName("Correctly implements SourceConnector interface")
    fun testImplementsSourceConnectorInterface() {
        assertEquals("dc9", scraper.sourceId)
        assertEquals(SourceType.VENUE_SCRAPER, scraper.sourceType)
        assertEquals("https://dc9.club/", scraper.url)
    }

    private class TestableDc9Scraper(objectMapper: ObjectMapper) : Dc9Scraper(objectMapper)
}
