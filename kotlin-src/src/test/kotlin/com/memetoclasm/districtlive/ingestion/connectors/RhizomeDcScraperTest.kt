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

@DisplayName("RhizomeDcScraper Tests")
class RhizomeDcScraperTest {

    private val objectMapper = ObjectMapper().apply { findAndRegisterModules() }

    private lateinit var scraper: TestableRhizomeDcScraper
    private lateinit var fixtureHtml: String

    @BeforeEach
    fun setup() {
        scraper = TestableRhizomeDcScraper(objectMapper)
        // Load fixture from classloader resources
        fixtureHtml = javaClass.classLoader?.getResourceAsStream("fixtures/rhizome-dc-events.html")
            ?.bufferedReader()?.readText()
            ?: throw IllegalStateException("Could not load fixture: fixtures/rhizome-dc-events.html")
    }

    @Test
    @DisplayName("AC1.2: Extracts valid events from Squarespace EventList markup")
    fun testExtractsValidEventsFromSquarespaceEventList() {
        // Given: HTML fixture with Squarespace EventList article elements
        val document = Jsoup.parse(fixtureHtml)

        // When: extractEvents is called
        val result = scraper.extractEvents(document)

        // Then: Should return non-empty list of valid RawEventDtos from CSS selectors
        assertTrue(result.isNotEmpty(), "Should extract at least one event from Squarespace markup")
        assertEquals(2, result.size, "Should extract 2 events from fixture")

        // Verify first event (Deep House Sessions) has correct fields
        val deepHouseEvent = result.find { it.title == "Deep House Sessions" }
        assertNotNull(deepHouseEvent, "Should extract Deep House Sessions event")
        assertEquals("Deep House Sessions", deepHouseEvent.title)
        assertEquals("Rhizome DC", deepHouseEvent.venueName)
        assertEquals("6950 Maple St NW, Washington, DC 20012", deepHouseEvent.venueAddress)
        assertNotNull(deepHouseEvent.startTime, "Event should have parsed start time from datetime attribute")
        assertNotNull(deepHouseEvent.endTime, "Event should have parsed end time")
        assertEquals(BigDecimal("20"), deepHouseEvent.minPrice, "Should extract price from excerpt text")
        assertEquals("https://www.eventbrite.com/rhizome-deep-house", deepHouseEvent.ticketUrl)
        assertEquals("https://example.com/deep-house.jpg", deepHouseEvent.imageUrl)
        assertEquals(SourceType.VENUE_SCRAPER, deepHouseEvent.sourceType)
        assertEquals("rhizome-dc", scraper.sourceId)
        assertEquals(BigDecimal("0.80"), deepHouseEvent.confidenceScore)
    }

    @Test
    @DisplayName("AC1.2: Extracts second event correctly")
    fun testExtractsSecondEventCorrectly() {
        // Given: HTML fixture with two event articles
        val document = Jsoup.parse(fixtureHtml)

        // When: extractEvents is called
        val result = scraper.extractEvents(document)

        // Then: Should extract Afrobeats Showcase with correct fields
        val afrobeatsEvent = result.find { it.title == "Afrobeats Showcase" }
        assertNotNull(afrobeatsEvent, "Should extract Afrobeats Showcase event")
        assertEquals("Afrobeats Showcase", afrobeatsEvent.title)
        assertEquals(BigDecimal("15"), afrobeatsEvent.minPrice)
        assertTrue(afrobeatsEvent.imageUrl?.startsWith("https://example.com/afrobeats") ?: false,
            "Should extract image from data-src attribute")
    }

    @Test
    @DisplayName("AC1.5: Skips articles missing required elements without throwing exception")
    fun testSkipsMalformedArticlesWithoutException() {
        // Given: HTML fixture — only articles with title links are included
        val document = Jsoup.parse(fixtureHtml)

        // When: extractEvents is called
        val result = scraper.extractEvents(document)

        // Then: Should extract exactly the valid events (2)
        assertEquals(2, result.size, "Should extract only valid events")
        val titles = result.map { it.title }
        assertFalse(titles.contains(""), "Should not include events with blank titles")
    }

    @Test
    @DisplayName("AC1.7: Returns empty list for page with no Squarespace event articles")
    fun testReturnsEmptyListForNoEvents() {
        // Given: HTML with no article.eventlist-event--upcoming elements
        val emptyHtml = """
            <!DOCTYPE html>
            <html>
            <head><title>Rhizome DC - Events</title></head>
            <body>
                <div class="event-container">
                    <h1>No Events</h1>
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
            assertEquals("Rhizome DC", event.venueName, "All events should have venue name set")
            assertEquals("6950 Maple St NW, Washington, DC 20012", event.venueAddress, "All events should have venue address set")
            assertEquals(SourceType.VENUE_SCRAPER, event.sourceType, "All events should have source type")
            assertEquals(BigDecimal("0.80"), event.confidenceScore, "All events should have confidence score set to 0.80")
        }
    }

    @Test
    @DisplayName("Correctly implements SourceConnector interface")
    fun testImplementsSourceConnectorInterface() {
        // Given: RhizomeDcScraper instance
        // When: Interface properties are accessed
        // Then: Should have correct values
        assertEquals("rhizome-dc", scraper.sourceId)
        assertEquals(SourceType.VENUE_SCRAPER, scraper.sourceType)
        assertEquals("https://www.rhizomedc.org/new-events", scraper.url)
    }

    @Test
    @DisplayName("Handles events without optional fields gracefully")
    fun testHandlesOptionalMissingFields() {
        // Given: HTML fixture (Deep House event has endTime; Afrobeats may not)
        val document = Jsoup.parse(fixtureHtml)

        // When: extractEvents is called
        val result = scraper.extractEvents(document)

        // Then: All events should be extracted regardless of missing optional fields
        assertEquals(2, result.size, "Should extract all events regardless of missing optional fields")
        result.forEach { event ->
            assertNotNull(event.title, "title is required")
            assertNotNull(event.sourceIdentifier, "sourceIdentifier is required")
        }
    }

    @Test
    @DisplayName("Extracts price from excerpt free text")
    fun testExtractsPriceFromExcerptText() {
        // Given: HTML fixture with prices in excerpt text ($20 and $15)
        val document = Jsoup.parse(fixtureHtml)

        // When: extractEvents is called
        val result = scraper.extractEvents(document)

        // Then: Prices should be parsed from dollar amounts in excerpt
        val deepHouseEvent = result.find { it.title == "Deep House Sessions" }
        assertEquals(BigDecimal("20"), deepHouseEvent?.minPrice, "Should parse $20 from excerpt text")
        assertEquals(BigDecimal("20"), deepHouseEvent?.maxPrice, "Single price: min == max")

        val afrobeatsEvent = result.find { it.title == "Afrobeats Showcase" }
        assertEquals(BigDecimal("15"), afrobeatsEvent?.minPrice, "Should parse $15 from excerpt text")
    }

    @Test
    @DisplayName("Extracts ticket URL from excerpt link and returns null when absent")
    fun testExtractsTicketUrlFromExcerptLink() {
        // Given: HTML fixture — Deep House has external ticket link, Afrobeats does not
        val document = Jsoup.parse(fixtureHtml)

        // When: extractEvents is called
        val result = scraper.extractEvents(document)

        // Then: External ticket URLs should be extracted; internal/absent should return null
        val deepHouseEvent = result.find { it.title == "Deep House Sessions" }
        assertEquals(
            "https://www.eventbrite.com/rhizome-deep-house",
            deepHouseEvent?.ticketUrl,
            "Should extract Eventbrite ticket URL"
        )

        val afrobeatsEvent = result.find { it.title == "Afrobeats Showcase" }
        assertEquals(null, afrobeatsEvent?.ticketUrl, "Event without external ticket link should have null ticketUrl")
    }

    @Test
    @DisplayName("Maps datetime attribute to Instant correctly")
    fun testMapsDatetimeAttributeToInstant() {
        // Given: HTML fixture with datetime attributes on time.event-date elements
        val document = Jsoup.parse(fixtureHtml)

        // When: extractEvents is called
        val result = scraper.extractEvents(document)

        // Then: Deep House event should have both start and end times, end after start
        val deepHouse = result.find { it.title == "Deep House Sessions" }
        assertNotNull(deepHouse?.startTime, "Should parse startTime from datetime attribute + start time")
        assertNotNull(deepHouse?.endTime, "Should parse endTime from datetime attribute + end time")
        assertTrue(deepHouse!!.endTime!! > deepHouse.startTime!!, "End time should be after start time")
    }

    /**
     * Testable subclass that allows overriding fetch behavior for unit tests.
     * This class provides the same extractEvents logic but allows testing without network calls.
     */
    private class TestableRhizomeDcScraper(objectMapper: ObjectMapper) : RhizomeDcScraper(objectMapper) {
        // Inherits all functionality from RhizomeDcScraper
        // Can be used directly without mocking network calls since extractEvents
        // is called with a pre-parsed Document
    }
}
