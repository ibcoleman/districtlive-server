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

@DisplayName("SevenDrumCityScraper Tests")
class SevenDrumCityScraperTest {

    private val objectMapper = ObjectMapper().apply { findAndRegisterModules() }

    private lateinit var scraper: TestableSevenDrumCityScraper
    private lateinit var fixtureHtml: String

    @BeforeEach
    fun setup() {
        scraper = TestableSevenDrumCityScraper(objectMapper)
        // Load fixture from classloader resources
        fixtureHtml = javaClass.classLoader?.getResourceAsStream("fixtures/7-drum-city-events.html")
            ?.bufferedReader()?.readText()
            ?: throw IllegalStateException("Could not load fixture: fixtures/7-drum-city-events.html")
    }

    @Test
    @DisplayName("AC1.3: Extracts valid events from Webflow CMS event items")
    fun testExtractsValidEventsFromHiddenElements() {
        // Given: HTML fixture with Webflow CMS event items
        val document = Jsoup.parse(fixtureHtml)

        // When: extractEvents is called
        val result = scraper.extractEvents(document)

        // Then: Should return non-empty list of valid RawEventDtos
        assertTrue(result.isNotEmpty(), "Should extract at least one event from fixture")
        assertTrue(result.size >= 6, "Should extract valid events (skipping malformed ones)")

        // Verify first event has correct fields
        val firstEvent = result.first()
        assertEquals("The Funk Collective Live", firstEvent.title)
        assertEquals("The Pocket (7 Drum City)", firstEvent.venueName)
        assertEquals("2611 Bladensburg Rd NE, Washington, DC 20018", firstEvent.venueAddress)
        assertNotNull(firstEvent.startTime, "Event should have parsed start time")
        assertEquals(SourceType.VENUE_SCRAPER, firstEvent.sourceType)
        assertEquals("7-drum-city", scraper.sourceId)
        assertEquals(BigDecimal("0.65"), firstEvent.confidenceScore)
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
        assertTrue(eventTitles.contains("The Funk Collective Live"), "Should include valid event 1")
        assertTrue(eventTitles.contains("Soul Session Saturdays"), "Should include valid event 2")
        assertTrue(eventTitles.contains("Jazz Brunch Series"), "Should include valid event 3")
        assertTrue(eventTitles.contains("Electronic Nights"), "Should include valid event 5")
        assertTrue(eventTitles.contains("Acoustic Showcase"), "Should include valid event 6")
    }

    @Test
    @DisplayName("AC1.7: Returns empty list for page with zero events")
    fun testReturnsEmptyListForNoEvents() {
        // Given: HTML with no event containers
        val emptyHtml = """
            <!DOCTYPE html>
            <html>
            <head><title>The Pocket - No Events</title></head>
            <body>
                <div class="events-container">
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
            assertEquals("The Pocket (7 Drum City)", event.venueName, "All events should have venue name set")
            assertEquals("2611 Bladensburg Rd NE, Washington, DC 20018", event.venueAddress, "All events should have venue address set")
            assertEquals(SourceType.VENUE_SCRAPER, event.sourceType, "All events should have source type")
            assertEquals(BigDecimal("0.65"), event.confidenceScore, "All events should have confidence score set")
        }
    }

    @Test
    @DisplayName("Handles events without description gracefully")
    fun testHandlesEventWithoutDescription() {
        // Given: HTML with event that has no description
        val document = Jsoup.parse(fixtureHtml)

        // When: extractEvents is called
        val result = scraper.extractEvents(document)

        // Then: Event without description should still be extracted
        val acousticEvent = result.find { it.title == "Acoustic Showcase" }
        assertNotNull(acousticEvent, "Should extract event without description")
        assertEquals(null, acousticEvent.description, "Event without description should have null description")
    }

    @Test
    @DisplayName("Parses abbreviated month date formats correctly")
    fun testParsesVariousDateFormats() {
        // Given: HTML with events having abbreviated month names (Mar, Apr)
        val document = Jsoup.parse(fixtureHtml)

        // When: extractEvents is called
        val result = scraper.extractEvents(document)

        // Then: Events with abbreviated month names should have startTime parsed
        val funkEvent = result.find { it.title == "The Funk Collective Live" }
        assertNotNull(funkEvent?.startTime, "Should parse 'Mar 15' abbreviated month format")

        val acousticEvent = result.find { it.title == "Acoustic Showcase" }
        assertNotNull(acousticEvent?.startTime, "Should parse 'Apr 19' abbreviated month format")

        val morningEvent = result.find { it.title == "Morning Sessions" }
        assertNotNull(morningEvent?.startTime, "Should parse 'Mar 31' abbreviated month format")
    }

    @Test
    @DisplayName("Parses PM time formats correctly")
    fun testParsesPmTimeFormats() {
        // Given: HTML with events having PM times
        val document = Jsoup.parse(fixtureHtml)

        // When: extractEvents is called
        val result = scraper.extractEvents(document)

        // Then: PM times should be parsed to correct hour (8 PM = hour 20, etc.)
        val funkEvent = result.find { it.title == "The Funk Collective Live" }
        assertNotNull(funkEvent?.startTime, "Should extract time for 8:00 PM event")
        // 8 PM should be hour 20 in 24-hour format
        val funkHour = funkEvent!!.startTime!!.atZone(java.time.ZoneId.of("America/New_York")).hour
        assertEquals(20, funkHour, "Should parse 8:00 PM as hour 20")
    }

    @Test
    @DisplayName("Parses AM time formats correctly")
    fun testParsesAmTimeFormats() {
        // Given: HTML with AM time event
        val document = Jsoup.parse(fixtureHtml)

        // When: extractEvents is called
        val result = scraper.extractEvents(document)

        // Then: AM times should be parsed correctly
        val morningEvent = result.find { it.title == "Morning Sessions" }
        assertNotNull(morningEvent?.startTime, "Should extract time for 10:00 AM event")
        val morningHour = morningEvent!!.startTime!!.atZone(java.time.ZoneId.of("America/New_York")).hour
        assertEquals(10, morningHour, "Should parse 10:00 AM as hour 10")
    }

    @Test
    @DisplayName("Handles events without time gracefully")
    fun testHandlesEventWithoutTime() {
        // Given: HTML with event that has no time
        val document = Jsoup.parse(fixtureHtml)

        // When: extractEvents is called
        val result = scraper.extractEvents(document)

        // Then: Event without time should default to 8pm (hour 20)
        val jazzEvent = result.find { it.title == "Jazz Brunch Series" }
        assertNotNull(jazzEvent?.startTime, "Should extract date for event without time")
        val jazzHour = jazzEvent!!.startTime!!.atZone(java.time.ZoneId.of("America/New_York")).hour
        assertEquals(20, jazzHour, "Event without time should default to hour 20 (8pm)")
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
        // Given: SevenDrumCityScraper instance
        // When: Interface properties are accessed
        // Then: Should have correct values
        assertEquals("7-drum-city", scraper.sourceId)
        assertEquals(SourceType.VENUE_SCRAPER, scraper.sourceType)
        assertEquals("https://thepocket.7drumcity.com", scraper.url)
    }

    @Test
    @DisplayName("Extracts support act names from h4.supports-line elements")
    fun testExtractsSupportActsAsArtistNames() {
        // Given: HTML fixture — "The Funk Collective Live" has two h4.supports-line acts
        val document = Jsoup.parse(fixtureHtml)

        // When: extractEvents is called
        val result = scraper.extractEvents(document)

        // Then: Support act names should appear in artistNames for events that have them
        val funkEvent = result.find { it.title == "The Funk Collective Live" }
        assertNotNull(funkEvent, "Should extract The Funk Collective Live")
        assertTrue(funkEvent!!.artistNames.contains("DJ Shadow"), "Should include DJ Shadow as support act")
        assertTrue(funkEvent.artistNames.contains("MC Flow"), "Should include MC Flow as support act")

        // Events without support acts should have empty artistNames
        val jazzEvent = result.find { it.title == "Jazz Brunch Series" }
        assertNotNull(jazzEvent, "Should extract Jazz Brunch Series")
        assertTrue(jazzEvent!!.artistNames.isEmpty(), "Event without support acts should have empty artistNames")
    }

    /**
     * Testable subclass that allows overriding fetch behavior for unit tests.
     * This class provides the same extractEvents logic but allows mocking the network call.
     */
    private class TestableSevenDrumCityScraper(objectMapper: ObjectMapper) : SevenDrumCityScraper(objectMapper) {
        // Inherits all functionality from SevenDrumCityScraper
        // Can be used directly without mocking network calls since extractEvents
        // is called with a pre-parsed Document
    }
}
