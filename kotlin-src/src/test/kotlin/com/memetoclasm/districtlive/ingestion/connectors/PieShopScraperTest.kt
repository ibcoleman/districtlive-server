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

@DisplayName("PieShopScraper Tests")
class PieShopScraperTest {

    private val objectMapper = ObjectMapper().apply { findAndRegisterModules() }

    private lateinit var scraper: TestablePieShopScraper
    private lateinit var listingDocument: Document
    private lateinit var detailDocument: Document
    private lateinit var emptyListingDocument: Document

    @BeforeEach
    fun setup() {
        scraper = TestablePieShopScraper()

        val listingHtml = javaClass.classLoader?.getResourceAsStream("fixtures/pie-shop-listing.html")
            ?.bufferedReader()?.readText()
            ?: throw IllegalStateException("Could not load fixture: fixtures/pie-shop-listing.html")
        listingDocument = Jsoup.parse(listingHtml, "https://www.pieshopdc.com/shows")

        val detailHtml = javaClass.classLoader?.getResourceAsStream("fixtures/pie-shop-detail.html")
            ?.bufferedReader()?.readText()
            ?: throw IllegalStateException("Could not load fixture: fixtures/pie-shop-detail.html")
        detailDocument = Jsoup.parse(detailHtml, "https://www.pieshopdc.com/shows/haggus-suppression-shunt")

        val emptyHtml = javaClass.classLoader?.getResourceAsStream("fixtures/pie-shop-empty.html")
            ?.bufferedReader()?.readText()
            ?: throw IllegalStateException("Could not load fixture: fixtures/pie-shop-empty.html")
        emptyListingDocument = Jsoup.parse(emptyHtml)
    }

    @Test
    @DisplayName("AC1.1: extractEvents on listing fixture produces correct number of events with title, date, and sourceUrl")
    fun testExtractsCorrectNumberOfEventsFromListing() {
        scraper.detailDocument = detailDocument

        val result = scraper.extractEvents(listingDocument)

        assertEquals(3, result.size, "Should extract 3 events from listing fixture")

        val first = result[0]
        assertEquals("Haggus w/ Suppression, Shunt", first.title)
        assertNotNull(first.startTime, "Event should have a parsed start time")
        assertNotNull(first.sourceUrl, "Event should have a detail URL as sourceUrl")
        assertTrue(first.sourceUrl!!.contains("pieshopdc.com"), "sourceUrl should be the detail page link")

        val second = result[1]
        assertEquals("Jazz Night Collective", second.title)
        assertNotNull(second.sourceUrl)

        val third = result[2]
        assertEquals("Local Bands Showcase", third.title)
        assertNotNull(third.sourceUrl)
    }

    @Test
    @DisplayName("AC1.2: First event has correct detail fields from detail page")
    fun testDetailFieldsCorrectlyMapped() {
        scraper.detailDocument = detailDocument

        val result = scraper.extractEvents(listingDocument)
        assertTrue(result.isNotEmpty())

        val first = result[0]

        // Price from opendate-widget price="15.00"
        assertEquals(BigDecimal("15.00"), first.minPrice, "minPrice should be parsed from opendate-widget price attribute")

        // Description from .confirm-description
        assertNotNull(first.description, "description should be non-null when detail page is available")
        assertTrue(first.description!!.contains("Haggus"), "description should contain event text")

        // doorsTime from .uui-event_time-wrapper-doors "7:00 PM"
        assertNotNull(first.doorsTime, "doorsTime should be parsed from detail page")

        // startTime from .uui-event_time-wrapper-show "8:00 PM"
        assertNotNull(first.startTime, "startTime should be parsed from detail page show time")
    }

    @Test
    @DisplayName("AC1.3: Artist names extracted from title by splitting on comma and w/")
    fun testArtistNameSplitting() {
        scraper.detailDocument = detailDocument

        val result = scraper.extractEvents(listingDocument)
        assertTrue(result.isNotEmpty())

        val first = result[0]
        assertEquals("Haggus w/ Suppression, Shunt", first.title)
        assertEquals(listOf("Haggus", "Suppression", "Shunt"), first.artistNames,
            "Artist names should be split on 'w/' and ','")
    }

    @Test
    @DisplayName("AC1.4: When fetchDetailDocument returns null, event is still emitted with listing-only data")
    fun testDetailPageFailureFallback() {
        scraper.detailFetchFails = true

        val result = scraper.extractEvents(listingDocument)

        assertEquals(3, result.size, "All events should still be emitted even when detail fetch fails")

        val first = result[0]
        assertEquals("Haggus w/ Suppression, Shunt", first.title)
        assertNotNull(first.sourceUrl, "sourceUrl (detail link) should still be set from listing")
        assertNull(first.minPrice, "minPrice should be null when detail page unavailable")
        assertNull(first.description, "description should be null when detail page unavailable")
    }

    @Test
    @DisplayName("AC1.5: Empty listing fixture returns empty list, not an error")
    fun testEmptyListingReturnsEmptyList() {
        val result = scraper.extractEvents(emptyListingDocument)

        assertEquals(emptyList(), result, "Should return empty list when no .ec-col-item.w-dyn-item elements found")
    }

    @Test
    @DisplayName("AC1.6: Detail page with no price attribute on opendate-widget produces null minPrice")
    fun testMissingPriceProducesNullMinPrice() {
        // Detail fixture with no price attribute
        val detailNoPriceHtml = """
            <!DOCTYPE html>
            <html><body>
            <opendate-widget event-id="od-99999" venue="pie-shop"></opendate-widget>
            <div class="uui-event_time-wrapper-doors">7:00 PM</div>
            <div class="uui-event_time-wrapper-show">8:00 PM</div>
            <div class="confirm-description">Some description.</div>
            </body></html>
        """.trimIndent()
        scraper.detailDocument = Jsoup.parse(detailNoPriceHtml)

        val result = scraper.extractEvents(listingDocument)
        assertTrue(result.isNotEmpty())

        val first = result[0]
        assertNull(first.minPrice, "minPrice should be null when opendate-widget has no price attribute")
    }

    @Test
    @DisplayName("All events have required base fields set")
    fun testAllEventsHaveRequiredFields() {
        scraper.detailDocument = detailDocument

        val result = scraper.extractEvents(listingDocument)
        assertTrue(result.isNotEmpty())

        result.forEach { event ->
            assertTrue(event.sourceIdentifier.isNotBlank(), "sourceIdentifier should be non-blank")
            assertEquals("Pie Shop", event.venueName, "venueName should be 'Pie Shop'")
            assertEquals("1339 H St NE, Washington, DC 20002", event.venueAddress, "venueAddress should be set")
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
    @DisplayName("sourceId is 'pie-shop' and scraper implements SourceConnector")
    fun testSourceIdAndInterface() {
        assertEquals("pie-shop", scraper.sourceId)
        assertEquals(SourceType.VENUE_SCRAPER, scraper.sourceType)
    }

    private inner class TestablePieShopScraper : PieShopScraper(objectMapper) {
        var detailDocument: Document? = null
        var detailFetchFails = false

        override fun fetchDetailDocument(detailUrl: String): Document? {
            return if (detailFetchFails) null else detailDocument
        }
    }
}
