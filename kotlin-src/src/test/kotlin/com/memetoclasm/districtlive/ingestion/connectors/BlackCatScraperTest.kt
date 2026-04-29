package com.memetoclasm.districtlive.ingestion.connectors

import com.fasterxml.jackson.databind.ObjectMapper
import com.memetoclasm.districtlive.ingestion.RawEventDto
import com.memetoclasm.districtlive.event.SourceType
import org.jsoup.Jsoup
import org.jsoup.nodes.Document
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.DisplayName
import java.math.BigDecimal
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertTrue
import kotlin.test.assertFalse

@DisplayName("BlackCatScraper Tests")
class BlackCatScraperTest {

    private val objectMapper = ObjectMapper().apply { findAndRegisterModules() }

    private lateinit var scraper: TestableBlackCatScraper
    private lateinit var fixtureHtml: String

    @BeforeEach
    fun setup() {
        scraper = TestableBlackCatScraper(objectMapper)
        // Load fixture from classloader resources
        fixtureHtml = javaClass.classLoader?.getResourceAsStream("fixtures/black-cat-schedule.html")
            ?.bufferedReader()?.readText()
            ?: throw IllegalStateException("Could not load fixture: fixtures/black-cat-schedule.html")
    }

    @Test
    @DisplayName("AC1.1: Extracts valid events from Black Cat schedule page HTML")
    fun testExtractsValidEventsFromSchedulePage() {
        // Given: HTML fixture with Black Cat schedule
        val document = Jsoup.parse(fixtureHtml)

        // When: extractEvents is called
        val result = scraper.extractEvents(document)

        // Then: Should return non-empty list of valid RawEventDtos
        assertTrue(result.isNotEmpty(), "Should extract at least one event from fixture")
        assertTrue(result.size >= 4, "Should extract valid events (skipping malformed ones)")

        // Verify first event has correct fields
        val firstEvent = result.first()
        assertEquals("The Foo Fighters Experience", firstEvent.title)
        assertEquals("Black Cat", firstEvent.venueName)
        assertEquals("1811 14th St NW, Washington, DC 20009", firstEvent.venueAddress)
        assertNotNull(firstEvent.startTime, "Event should have parsed start time")
        assertEquals("https://www.etix.com/ticket/p/12345/foo-fighters-experience", firstEvent.ticketUrl)
        assertEquals("https://example.com/foo-fighters.jpg", firstEvent.imageUrl)
        assertEquals(SourceType.VENUE_SCRAPER, firstEvent.sourceType)
        assertEquals("black-cat", scraper.sourceId)
        assertEquals(BigDecimal("0.70"), firstEvent.confidenceScore)
    }

    @Test
    @DisplayName("AC1.5: Skips malformed events without throwing exception")
    fun testSkipsMalformedEventsWithoutException() {
        // Given: HTML with parseable and malformed events (event 4 has empty title)
        val document = Jsoup.parse(fixtureHtml)

        // When: extractEvents is called
        val result = scraper.extractEvents(document)

        // Then: Should skip malformed event (missing title) and return valid ones
        val eventTitles = result.map { it.title }
        assertFalse(eventTitles.contains(""), "Should not include events with blank titles")
        assertTrue(eventTitles.contains("The Foo Fighters Experience"), "Should include valid event 1")
        assertTrue(eventTitles.contains("Jazz Quartet Thursday Night"), "Should include valid event 2")
        assertTrue(eventTitles.contains("Free Live Session"), "Should include valid event 3")
        assertTrue(eventTitles.contains("Electronic Night Series"), "Should include valid event 5")
    }

    @Test
    @DisplayName("AC1.7: Returns empty list for page with zero events")
    fun testReturnsEmptyListForNoEvents() {
        // Given: HTML with no event containers
        val emptyHtml = """
            <!DOCTYPE html>
            <html>
            <head><title>Black Cat - Schedule</title></head>
            <body>
                <div class="schedule-container">
                    <h1>No Upcoming Events</h1>
                </div>
            </body>
            </html>
        """.trimIndent()

        val document = Jsoup.parse(emptyHtml)

        // When: extractEvents is called
        val result = scraper.extractEvents(document)

        // Then: Should return empty list (not an error)
        assertEquals(emptyList(), result, "Should return empty list for page with no events")
    }

    @Test
    @DisplayName("Verifies all parsed events have required fields")
    fun testAllEventsHaveRequiredFields() {
        // Given: HTML fixture
        val document = Jsoup.parse(fixtureHtml)

        // When: extractEvents is called
        val result = scraper.extractEvents(document)

        // Then: All events should have required fields set
        result.forEach { event ->
            assertNotNull(event.sourceIdentifier, "Event should have sourceIdentifier")
            assertNotNull(event.title, "Event should have title")
            assertEquals("Black Cat", event.venueName, "All events should have venue name set")
            assertEquals("1811 14th St NW, Washington, DC 20009", event.venueAddress, "All events should have venue address set")
            assertEquals(SourceType.VENUE_SCRAPER, event.sourceType, "All events should have source type")
            assertEquals(BigDecimal("0.70"), event.confidenceScore, "All events should have confidence score set")
        }
    }

    @Test
    @DisplayName("Handles events without price gracefully")
    fun testHandlesEventWithoutPrice() {
        // Given: HTML with event that has no price
        val document = Jsoup.parse(fixtureHtml)

        // When: extractEvents is called
        val result = scraper.extractEvents(document)

        // Then: Event without price should still be extracted
        val freeEvent = result.find { it.title == "Free Live Session" }
        assertNotNull(freeEvent, "Should extract event without price")
        assertEquals(null, freeEvent.minPrice, "Event without price should have null minPrice")
        assertEquals("https://example.com/session.png", freeEvent.imageUrl, "Should still extract image URL")
    }

    @Test
    @DisplayName("Extracts etix.com ticket URLs and returns null when no ticket link present")
    fun testExtractsEtixTicketUrls() {
        // Given: HTML with events having etix.com ticket links and events without
        val document = Jsoup.parse(fixtureHtml)

        // When: extractEvents is called
        val result = scraper.extractEvents(document)

        // Then: Events with etix.com links should have ticketUrl set; others should have null
        val fooEvent = result.find { it.title == "The Foo Fighters Experience" }
        assertNotNull(fooEvent?.ticketUrl, "Should extract etix.com ticket URL")
        assertTrue(fooEvent!!.ticketUrl!!.contains("etix.com"), "Ticket URL should be from etix.com")

        val jazzEvent = result.find { it.title == "Jazz Quartet Thursday Night" }
        assertEquals(null, jazzEvent?.ticketUrl, "Event without ticket link should have null ticketUrl")

        val freeEvent = result.find { it.title == "Free Live Session" }
        assertEquals(null, freeEvent?.ticketUrl, "Free event without ticket link should have null ticketUrl")
    }

    @Test
    @DisplayName("Generates unique source identifiers for different events")
    fun testGeneratesUniqueSourceIdentifiers() {
        // Given: HTML fixture with multiple events
        val document = Jsoup.parse(fixtureHtml)

        // When: extractEvents is called
        val result = scraper.extractEvents(document)

        // Then: Each event should have unique identifier
        val identifiers = result.map { it.sourceIdentifier }
        assertEquals(identifiers.toSet().size, identifiers.size, "All events should have unique identifiers")
    }

    @Test
    @DisplayName("Correctly implements SourceConnector interface")
    fun testImplementsSourceConnectorInterface() {
        // Given: BlackCatScraper instance
        // When: Interface properties are accessed
        // Then: Should have correct values
        assertEquals("black-cat", scraper.sourceId)
        assertEquals(SourceType.VENUE_SCRAPER, scraper.sourceType)
        assertEquals("https://www.blackcatdc.com/schedule.html", scraper.url)
    }

    /**
     * Testable subclass that allows overriding fetch behavior for unit tests.
     * This class provides the same extractEvents logic but allows mocking the network call.
     */
    private class TestableBlackCatScraper(objectMapper: ObjectMapper) : BlackCatScraper(objectMapper) {
        // Inherits all functionality from BlackCatScraper
        // Can be used directly without mocking network calls since extractEvents
        // is called with a pre-parsed Document
    }
}
