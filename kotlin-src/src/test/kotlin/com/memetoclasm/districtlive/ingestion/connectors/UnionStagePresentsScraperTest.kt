package com.memetoclasm.districtlive.ingestion.connectors

import com.fasterxml.jackson.databind.ObjectMapper
import com.memetoclasm.districtlive.event.SourceType
import com.memetoclasm.districtlive.ingestion.ConnectorConfig
import com.memetoclasm.districtlive.ingestion.IngestionError
import kotlinx.coroutines.runBlocking
import org.jsoup.Jsoup
import org.jsoup.nodes.Document
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.DisplayName
import org.junit.jupiter.api.Test
import java.math.BigDecimal
import java.time.Instant
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

@DisplayName("UnionStagePresentsScraper Tests")
class UnionStagePresentsScraperTest {

    private val objectMapper = ObjectMapper().apply { findAndRegisterModules() }

    private lateinit var scraper: TestableUnionStagePresentsScraper
    private lateinit var listingDocument: Document
    private lateinit var detailDocument: Document
    private lateinit var emptyListingDocument: Document

    private lateinit var connectorConfig: ConnectorConfig

    @BeforeEach
    fun setup() {
        val listingHtml = javaClass.classLoader?.getResourceAsStream("fixtures/union-stage-presents-listing.html")
            ?.bufferedReader()?.readText()
            ?: throw IllegalStateException("Could not load fixture: fixtures/union-stage-presents-listing.html")
        listingDocument = Jsoup.parse(listingHtml, "https://unionstagepresents.com")

        val detailHtml = javaClass.classLoader?.getResourceAsStream("fixtures/union-stage-presents-detail.html")
            ?.bufferedReader()?.readText()
            ?: throw IllegalStateException("Could not load fixture: fixtures/union-stage-presents-detail.html")
        detailDocument = Jsoup.parse(detailHtml, "https://unionstagepresents.com/shows/cut-worms-17-apr")

        val emptyHtml = javaClass.classLoader?.getResourceAsStream("fixtures/union-stage-presents-empty.html")
            ?.bufferedReader()?.readText()
            ?: throw IllegalStateException("Could not load fixture: fixtures/union-stage-presents-empty.html")
        emptyListingDocument = Jsoup.parse(emptyHtml)

        connectorConfig = ConnectorConfig(
            ticketmaster = ConnectorConfig.TicketmasterConfig(),
            bandsintown = ConnectorConfig.BandsintownConfig(),
            dice = ConnectorConfig.DiceConfig(),
            unionStagePresents = ConnectorConfig.UnionStagePresentsCfg(
                venues = listOf(
                    ConnectorConfig.UnionStagePresentsCfg.VenueMapping(slug = "union-stage", path = "/union-stage/shows"),
                    ConnectorConfig.UnionStagePresentsCfg.VenueMapping(slug = "jammin-java", path = "/jammin-java/shows")
                )
            )
        )

        scraper = TestableUnionStagePresentsScraper(connectorConfig)
    }

    @Test
    @DisplayName("extracts events from real listing fixture using .show-item selector")
    fun testExtractsEventsFromRealListingFixture() {
        scraper.detailDocument = detailDocument

        val result = scraper.extractEventsForVenue(listingDocument, "union-stage")

        // The real fixture has 74 show-item elements
        assertTrue(result.size >= 30, "Should extract many events from listing, got ${result.size}")
    }

    @Test
    @DisplayName("extracts correct title from h3.show-card-header")
    fun testExtractsCorrectTitle() {
        scraper.detailDocument = detailDocument

        val result = scraper.extractEventsForVenue(listingDocument, "union-stage")

        val titles = result.map { it.title }
        assertTrue(titles.any { it.contains("DC Stampede presents Jackson Perkins") },
            "Should find 'DC Stampede presents Jackson Perkins' in titles: $titles")
        assertTrue(titles.any { it.contains("Joseph") },
            "Should find 'Joseph' in titles: $titles")
    }

    @Test
    @DisplayName("extracts detail link from a.show-card-link href")
    fun testExtractsDetailLink() {
        scraper.detailDocument = detailDocument

        val result = scraper.extractEventsForVenue(listingDocument, "union-stage")
        val first = result[0]

        assertNotNull(first.sourceUrl, "sourceUrl should come from show-card-link href")
        assertTrue(first.sourceUrl!!.contains("/shows/"), "sourceUrl should contain /shows/ path")
        assertTrue(first.sourceUrl!!.contains("unionstagepresents.com"),
            "sourceUrl should be absolute URL with base domain")
    }

    @Test
    @DisplayName("parses date from .event-month and .event-day elements")
    fun testParsesDateFromListingCard() {
        scraper.detailDocument = null // No detail page — rely on listing dates

        val result = scraper.extractEventsForVenue(listingDocument, "union-stage")
        val first = result[0] // "DC Stampede presents Jackson Perkins" — Apr 01

        assertNotNull(first.startTime, "startTime should be parsed from listing date elements")
        // Apr 01 2026 with default show time from listing (8:00 PM ET = midnight UTC)
        val startInstant = first.startTime!!
        assertTrue(startInstant.isAfter(Instant.parse("2026-04-01T00:00:00Z")),
            "startTime should be in April 2026, got $startInstant")
        assertTrue(startInstant.isBefore(Instant.parse("2026-04-02T06:00:00Z")),
            "startTime should be on Apr 01, got $startInstant")
    }

    @Test
    @DisplayName("parses doors and show times from listing card .show-info divs")
    fun testParsesDoorsAndShowTimesFromListing() {
        scraper.detailDocument = null // No detail page

        val result = scraper.extractEventsForVenue(listingDocument, "union-stage")
        val first = result[0] // Doors 7:00 pm / Show 8:00 pm on Apr 01

        assertNotNull(first.doorsTime, "doorsTime should be parsed from listing card")
        assertNotNull(first.startTime, "startTime should use show time from listing card")

        // Doors 7 PM ET on Apr 1 = 2026-04-01T23:00:00Z
        assertEquals(Instant.parse("2026-04-01T23:00:00Z"), first.doorsTime,
            "doorsTime should be 7 PM ET")
        // Show 8 PM ET on Apr 1 = 2026-04-02T00:00:00Z
        assertEquals(Instant.parse("2026-04-02T00:00:00Z"), first.startTime,
            "startTime should be 8 PM ET")
    }

    @Test
    @DisplayName("detail page #event-data provides price, precise times, and description")
    fun testDetailPageEventDataAttributes() {
        scraper.detailDocument = detailDocument

        val result = scraper.extractEventsForVenue(listingDocument, "union-stage")

        // The detail page is for "Cut Worms" but gets returned for ALL events
        // in the test since TestableUnionStagePresentsScraper returns the same detail doc.
        // Just verify the first event gets enriched with detail page data.
        val first = result[0]

        // Price from data-price="$34.00"
        assertNotNull(first.minPrice, "minPrice should be extracted from detail page #event-data data-price")
        assertEquals(BigDecimal("34.00"), first.minPrice)

        // Description from .about-copy.w-richtext
        assertNotNull(first.description, "description should come from detail page")

        // Image from data-image
        assertNotNull(first.imageUrl, "imageUrl should come from detail page #event-data data-image")
    }

    @Test
    @DisplayName("detail page overrides listing times with ISO timestamps from #event-data")
    fun testDetailPageOverridesTimesWithIsoTimestamps() {
        scraper.detailDocument = detailDocument

        val result = scraper.extractEventsForVenue(listingDocument, "union-stage")
        val first = result[0]

        // Detail page has: data-start="2026-04-18T00:00:00.000Z", data-doors="2026-04-17T23:00:00.000Z"
        // data-end="2026-04-18T03:00:00.000Z"
        // These should override the listing-parsed times
        assertEquals(Instant.parse("2026-04-18T00:00:00.000Z"), first.startTime,
            "startTime should be overridden by detail page data-start")
        assertEquals(Instant.parse("2026-04-17T23:00:00.000Z"), first.doorsTime,
            "doorsTime should be overridden by detail page data-doors")
        assertEquals(Instant.parse("2026-04-18T03:00:00.000Z"), first.endTime,
            "endTime should come from detail page data-end")
    }

    @Test
    @DisplayName("listing data preserved when detail page unavailable")
    fun testListingDataPreservedWhenDetailUnavailable() {
        scraper.detailDocument = null

        val result = scraper.extractEventsForVenue(listingDocument, "union-stage")

        assertTrue(result.isNotEmpty(), "Should still return events without detail page")

        val first = result[0]
        assertNotNull(first.title, "title should come from listing")
        assertNotNull(first.startTime, "startTime should fall back to listing-parsed time")
        assertNull(first.minPrice, "minPrice should be null without detail page")
        assertNull(first.description, "description should be null without detail page")
    }

    @Test
    @DisplayName("support act from listing card extracted as artist names")
    fun testSupportActExtractedAsArtistNames() {
        scraper.detailDocument = null

        val result = scraper.extractEventsForVenue(listingDocument, "union-stage")

        // Event 2: "Joseph - Closer to Happy Tour" with support "The Man The Myth The Meatslab"
        val joseph = result.find { it.title.contains("Joseph") }
        assertNotNull(joseph, "Should find Joseph event")
        // Support act should be in artistNames; title-based extraction is done by NormalizationService
        assertTrue(joseph.artistNames.any { it.contains("The Man The Myth The Meatslab") },
            "Artist names should include support act from subtitle: ${joseph.artistNames}")
    }

    @Test
    @DisplayName("venue name and address set correctly per venue slug")
    fun testVenueAttributionPerSlug() {
        scraper.detailDocument = null

        val result = scraper.extractEventsForVenue(listingDocument, "union-stage")

        result.forEach { event ->
            assertEquals("Union Stage", event.venueName, "venueName should be 'Union Stage'")
            assertEquals("740 Water St SW, Washington, DC 20024", event.venueAddress)
        }
    }

    @Test
    @DisplayName("all events have VENUE_SCRAPER sourceType and valid sourceIdentifier")
    fun testSourceTypeAndIdentifier() {
        scraper.detailDocument = null

        val result = scraper.extractEventsForVenue(listingDocument, "union-stage")

        result.forEach { event ->
            assertEquals(SourceType.VENUE_SCRAPER, event.sourceType)
            assertNotNull(event.sourceIdentifier)
            assertTrue(event.sourceIdentifier.isNotBlank())
        }

        // sourceIdentifiers should be unique
        val ids = result.map { it.sourceIdentifier }
        assertEquals(ids.size, ids.toSet().size, "sourceIdentifiers should be unique")
    }

    @Test
    @DisplayName("empty listing returns empty list")
    fun testEmptyListingReturnsEmptyList() {
        val result = scraper.extractEventsForVenue(emptyListingDocument, "union-stage")
        assertEquals(emptyList(), result)
    }

    @Test
    @DisplayName("multi-venue fetch combines events from all configured venues")
    fun testMultiVenueFetchCombinesEvents() = runBlocking {
        scraper.detailDocument = detailDocument

        val result = scraper.fetch()
        assertTrue(result.isRight(), "Should return Right")

        val events = result.getOrNull() ?: emptyList()
        // Both venues use same listing fixture in test, so we get events for both
        val unionStageEvents = events.filter { it.venueName == "Union Stage" }
        val jamminJavaEvents = events.filter { it.venueName == "Jammin Java" }
        assertTrue(unionStageEvents.isNotEmpty(), "Should have Union Stage events")
        assertTrue(jamminJavaEvents.isNotEmpty(), "Should have Jammin Java events")
    }

    @Test
    @DisplayName("partial venue failure returns results from successful venues")
    fun testPartialVenueFailure() = runBlocking {
        scraper.detailDocument = detailDocument
        scraper.failedVenues.add("jammin-java")

        val result = scraper.fetch()
        assertTrue(result.isRight(), "Should return Right when at least one venue succeeds")

        val events = result.getOrNull() ?: emptyList()
        assertTrue(events.isNotEmpty())
        assertTrue(events.none { it.venueName == "Jammin Java" })
    }

    @Test
    @DisplayName("all venues failing returns Either.Left ConnectionError")
    fun testAllVenuesFailingReturnsError() = runBlocking {
        scraper.failedVenues.add("union-stage")
        scraper.failedVenues.add("jammin-java")

        val result = scraper.fetch()
        assertTrue(result.isLeft())
        assertTrue(result.leftOrNull() is IngestionError.ConnectionError)
    }

    @Test
    @DisplayName("sourceId is 'union-stage-presents'")
    fun testSourceId() {
        assertEquals("union-stage-presents", scraper.sourceId)
        assertEquals(SourceType.VENUE_SCRAPER, scraper.sourceType)
    }

    @Test
    @DisplayName("HTML entities in titles are decoded")
    fun testHtmlEntitiesDecoded() {
        scraper.detailDocument = null

        val result = scraper.extractEventsForVenue(listingDocument, "union-stage")

        // Event 5 has &#x27; in title: "NateWantsToBattle &#x27;Phantom Burial Tour&#x27;"
        val nate = result.find { it.title.contains("NateWantsToBattle") }
        assertNotNull(nate, "Should find NateWantsToBattle event")
        // Jsoup should decode &#x27; to '
        assertTrue(nate.title.contains("'") || nate.title.contains("Phantom"),
            "HTML entities should be decoded in title: ${nate.title}")
        assertTrue(!nate.title.contains("&#x27;"),
            "Raw HTML entities should not appear in title: ${nate.title}")
    }

    @Test
    @DisplayName("confidenceScore is set to standard scraper confidence")
    fun testConfidenceScore() {
        scraper.detailDocument = null

        val result = scraper.extractEventsForVenue(listingDocument, "union-stage")
        result.forEach { event ->
            assertEquals(AbstractHtmlScraper.CONFIDENCE_SCORE, event.confidenceScore)
        }
    }

    /**
     * Testable subclass that overrides network-dependent methods to use fixtures.
     */
    private inner class TestableUnionStagePresentsScraper(
        connectorConfig: ConnectorConfig
    ) : UnionStagePresentsScraper(connectorConfig, objectMapper) {

        var detailDocument: Document? = null
        val failedVenues = mutableListOf<String>()

        override fun fetchListingDocument(listingUrl: String): Document? {
            for (venue in failedVenues) {
                if (listingUrl.contains(venue)) {
                    return null
                }
            }
            return listingDocument
        }

        override fun fetchDetailDocument(detailUrl: String): Document? {
            return detailDocument
        }
    }
}
