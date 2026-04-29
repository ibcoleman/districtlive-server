package com.memetoclasm.districtlive.ingestion.connectors

import com.fasterxml.jackson.databind.ObjectMapper
import com.memetoclasm.districtlive.event.SourceType
import org.jsoup.Jsoup
import org.jsoup.nodes.Document
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.DisplayName
import org.junit.jupiter.api.Test
import java.math.BigDecimal
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

@DisplayName("CometPingPongScraper Tests")
class CometPingPongScraperTest {

    private val objectMapper = ObjectMapper().apply { findAndRegisterModules() }

    private lateinit var scraper: TestableCometPingPongScraper
    private lateinit var listingDocument: Document
    private lateinit var detailDocument: Document
    private lateinit var emptyListingDocument: Document

    @BeforeEach
    fun setup() {
        scraper = TestableCometPingPongScraper()

        val listingHtml = javaClass.classLoader?.getResourceAsStream("fixtures/comet-ping-pong-listing.html")
            ?.bufferedReader()?.readText()
            ?: throw IllegalStateException("Could not load fixture: fixtures/comet-ping-pong-listing.html")
        listingDocument = Jsoup.parse(listingHtml, "https://calendar.rediscoverfirebooking.com/cpp-shows")

        val detailHtml = javaClass.classLoader?.getResourceAsStream("fixtures/comet-ping-pong-detail.html")
            ?.bufferedReader()?.readText()
            ?: throw IllegalStateException("Could not load fixture: fixtures/comet-ping-pong-detail.html")
        detailDocument = Jsoup.parse(detailHtml, "https://calendar.rediscoverfirebooking.com/cpp-shows/the-beths")

        val emptyHtml = javaClass.classLoader?.getResourceAsStream("fixtures/comet-ping-pong-empty.html")
            ?.bufferedReader()?.readText()
            ?: throw IllegalStateException("Could not load fixture: fixtures/comet-ping-pong-empty.html")
        emptyListingDocument = Jsoup.parse(emptyHtml)
    }

    @Test
    @DisplayName("AC2.1: extractEvents on listing fixture produces correct number of events with title, date, time, ageRestriction, and imageUrl")
    fun testExtractsCorrectNumberOfEventsFromListing() {
        scraper.detailDocument = detailDocument

        val result = scraper.extractEvents(listingDocument)

        // 3 desktop items, 1 mobile duplicate — should produce exactly 3
        assertEquals(3, result.size, "Should extract 3 events from listing fixture (desktop only)")

        val first = result[0]
        assertEquals("The Beths", first.title)
        assertNotNull(first.startTime, "Event should have a parsed start time from listing")
        assertNotNull(first.sourceUrl, "Event should have a detail URL as sourceUrl")
        assertTrue(first.sourceUrl!!.contains("the-beths"), "sourceUrl should be the detail page link")
        assertEquals("All Ages", first.ageRestriction, "ageRestriction should be parsed from .ages-2")
        assertNotNull(first.imageUrl, "imageUrl should be parsed from .image-42")
        assertTrue(first.imageUrl!!.contains("the-beths"), "imageUrl should point to the event image")

        val second = result[1]
        assertEquals("Illuminati Hotties", second.title)
        assertEquals("21+", second.ageRestriction)

        val third = result[2]
        assertEquals("Alex G", third.title)
        assertEquals("All Ages", third.ageRestriction)
    }

    @Test
    @DisplayName("AC2.2: Events enriched with detail page fields: minPrice from .uui-event_tickets-wrapper, description from .confirm-description")
    fun testDetailFieldsCorrectlyMapped() {
        scraper.detailDocument = detailDocument

        val result = scraper.extractEvents(listingDocument)
        assertTrue(result.isNotEmpty())

        val first = result[0]

        // Price from .uui-event_tickets-wrapper text "$10"
        assertEquals(BigDecimal("10"), first.minPrice, "minPrice should be parsed from .uui-event_tickets-wrapper")

        // Description from .confirm-description
        assertNotNull(first.description, "description should be non-null when detail page is available")
        assertTrue(first.description!!.contains("Beths"), "description should contain event text")
    }

    @Test
    @DisplayName("AC2.3: Fixture with both desktop and mobile items produces only the desktop item count — mobile duplicates ignored")
    fun testMobileItemsIgnored() {
        scraper.detailDocument = detailDocument

        val result = scraper.extractEvents(listingDocument)

        // Fixture has 3 desktop items and 1 mobile duplicate — only 3 should be extracted
        assertEquals(3, result.size, "Mobile duplicates (.uui-layout88_item-mobile-cpp) should be ignored")

        // Verify we have the correct 3 events (not duplicates)
        val titles = result.map { it.title }
        assertEquals(listOf("The Beths", "Illuminati Hotties", "Alex G"), titles)
    }

    @Test
    @DisplayName("AC2.4: When fetchDetailDocument returns null, event is still emitted with listing-only data")
    fun testDetailPageFailureFallback() {
        scraper.detailFetchFails = true

        val result = scraper.extractEvents(listingDocument)

        assertEquals(3, result.size, "All events should still be emitted even when detail fetch fails")

        val first = result[0]
        assertEquals("The Beths", first.title)
        assertNotNull(first.startTime, "startTime should still be set from listing page time")
        assertNotNull(first.imageUrl, "imageUrl should still be set from listing page")
        assertNotNull(first.ageRestriction, "ageRestriction should still be set from listing page")
        assertNotNull(first.sourceUrl, "sourceUrl (detail link) should still be set from listing")
        assertNull(first.minPrice, "minPrice should be null when detail page unavailable")
        assertNull(first.description, "description should be null when detail page unavailable")
    }

    @Test
    @DisplayName("AC2.5: Empty listing fixture returns empty list, not an error")
    fun testEmptyListingReturnsEmptyList() {
        val result = scraper.extractEvents(emptyListingDocument)

        assertEquals(emptyList(), result, "Should return empty list when no .uui-layout88_item-cpp.w-dyn-item elements found")
    }

    @Test
    @DisplayName("AC2.6: Event with no .ages-2 element (or empty text) has ageRestriction = null")
    fun testMissingAgeRestrictionIsNull() {
        val htmlWithNoAge = """
            <!DOCTYPE html>
            <html><body>
            <div class="uui-layout88_item-cpp w-dyn-item">
                <a class="link-block-3" href="https://calendar.rediscoverfirebooking.com/cpp-shows/no-age">
                    <div class="uui-heading-xxsmall-2">No Age Band</div>
                    <div class="heading-date">March 15, 2026</div>
                    <div class="heading-time">8:00 PM</div>
                    <img class="image-42" src="https://example.com/img.jpg">
                </a>
            </div>
            </body></html>
        """.trimIndent()
        val doc = Jsoup.parse(htmlWithNoAge, "https://calendar.rediscoverfirebooking.com/cpp-shows")

        scraper.detailDocument = null

        val result = scraper.extractEvents(doc)
        assertTrue(result.isNotEmpty())

        val first = result[0]
        assertNull(first.ageRestriction, "ageRestriction should be null when .ages-2 element is absent")
    }

    @Test
    @DisplayName("All events have required base fields set")
    fun testAllEventsHaveRequiredFields() {
        scraper.detailDocument = detailDocument

        val result = scraper.extractEvents(listingDocument)
        assertTrue(result.isNotEmpty())

        result.forEach { event ->
            assertTrue(event.sourceIdentifier.isNotBlank(), "sourceIdentifier should be non-blank")
            assertEquals("Comet Ping Pong", event.venueName, "venueName should be 'Comet Ping Pong'")
            assertEquals("5037 Connecticut Ave NW, Washington, DC 20008", event.venueAddress, "venueAddress should be set")
            assertEquals(SourceType.VENUE_SCRAPER, event.sourceType, "sourceType should be VENUE_SCRAPER")
            assertEquals(BigDecimal("0.70"), event.confidenceScore, "confidenceScore should be 0.70")
        }
    }

    @Test
    @DisplayName("sourceIdentifier values are unique across events")
    fun testSourceIdentifiersAreUnique() {
        scraper.detailDocument = detailDocument

        val result = scraper.extractEvents(listingDocument)
        assertTrue(result.size > 1)

        val identifiers = result.map { it.sourceIdentifier }
        assertEquals(identifiers.size, identifiers.toSet().size, "sourceIdentifier values should be unique across events")
    }

    @Test
    @DisplayName("sourceId is 'comet-ping-pong' and scraper implements SourceConnector")
    fun testSourceIdAndInterface() {
        assertEquals("comet-ping-pong", scraper.sourceId)
        assertEquals(SourceType.VENUE_SCRAPER, scraper.sourceType)
    }

    private inner class TestableCometPingPongScraper : CometPingPongScraper(objectMapper) {
        var detailDocument: Document? = null
        var detailFetchFails = false

        override fun fetchDetailDocument(detailUrl: String): Document? {
            return if (detailFetchFails) null else detailDocument
        }
    }
}
