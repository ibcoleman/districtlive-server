package com.memetoclasm.districtlive.ingestion.service

import com.memetoclasm.districtlive.event.AgeRestriction
import com.memetoclasm.districtlive.event.PriceTier
import com.memetoclasm.districtlive.event.SourceType
import java.math.BigDecimal
import java.time.Instant
import org.junit.jupiter.api.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class DeduplicationServiceTest {

    private val service = DeduplicationService()

    private fun createNormalizedEvent(
        title: String = "Test Artist",
        venueName: String = "Black Cat",
        venueAddress: String? = null,
        startTime: Instant = Instant.parse("2026-03-15T20:00:00Z"),
        sourceType: SourceType = SourceType.TICKETMASTER_API,
        sourceIdentifier: String = "ticketmaster-123",
        sourceUrl: String? = "https://ticketmaster.com/123",
        confidenceScore: BigDecimal = BigDecimal("0.90"),
        artistNames: List<String> = listOf("Test Artist"),
        minPrice: BigDecimal? = BigDecimal("25"),
        maxPrice: BigDecimal? = BigDecimal("30")
    ): NormalizedEvent = NormalizedEvent(
        title = title,
        slug = "test-slug",
        description = null,
        startTime = startTime,
        endTime = null,
        doorsTime = null,
        venueName = venueName,
        venueAddress = venueAddress,
        artistNames = artistNames,
        minPrice = minPrice,
        maxPrice = maxPrice,
        priceTier = PriceTier.PRICE_15_TO_30,
        ticketUrl = sourceUrl,
        imageUrl = null,
        ageRestriction = AgeRestriction.ALL_AGES,
        sourceType = sourceType,
        sourceIdentifier = sourceIdentifier,
        sourceUrl = sourceUrl,
        confidenceScore = confidenceScore
    )

    // AC3.1: Same show from Ticketmaster and venue scraper produces one canonical event with two source attributions
    @Test
    fun `AC3_1_same_venue_same_date_same_title_different_sources_merges_into_one_dedup_event_with_two_sources`() {
        val ticketmasterEvent = createNormalizedEvent(
            title = "Artist Name",
            venueName = "Black Cat",
            startTime = Instant.parse("2026-03-15T20:00:00Z"),
            sourceType = SourceType.TICKETMASTER_API,
            sourceIdentifier = "ticketmaster-123",
            confidenceScore = BigDecimal("0.90")
        )

        val scraperEvent = createNormalizedEvent(
            title = "Artist Name",
            venueName = "Black Cat",
            startTime = Instant.parse("2026-03-15T20:15:00Z"), // Slightly different start time, same date
            sourceType = SourceType.VENUE_SCRAPER,
            sourceIdentifier = "black-cat-scraper-456",
            confidenceScore = BigDecimal("0.70")
        )

        val result = service.deduplicate(listOf(ticketmasterEvent, scraperEvent))

        assertEquals(1, result.size)
        assertEquals(2, result[0].sources.size)

        val sources = result[0].sources.sortedBy { it.sourceIdentifier }
        assertEquals(SourceType.VENUE_SCRAPER, sources[0].sourceType)
        assertEquals(SourceType.TICKETMASTER_API, sources[1].sourceType)
    }

    // AC3.2: Highest-confidence source wins per field on merge (API data preferred over scraper for pricing)
    @Test
    fun `AC3_2_highest_confidence_source_wins_for_each_field`() {
        val apiEvent = createNormalizedEvent(
            title = "Artist Name",
            venueName = "Black Cat",
            startTime = Instant.parse("2026-03-15T20:00:00Z"),
            sourceType = SourceType.TICKETMASTER_API,
            sourceIdentifier = "api-123",
            minPrice = BigDecimal("25"),
            maxPrice = BigDecimal("45"),
            confidenceScore = BigDecimal("0.90")
        )

        val scraperEvent = createNormalizedEvent(
            title = "Artist Name",
            venueName = "Black Cat",
            startTime = Instant.parse("2026-03-15T20:00:00Z"),
            sourceType = SourceType.VENUE_SCRAPER,
            sourceIdentifier = "scraper-456",
            minPrice = BigDecimal("20"),
            maxPrice = BigDecimal("40"),
            confidenceScore = BigDecimal("0.70")
        )

        val result = service.deduplicate(listOf(apiEvent, scraperEvent))

        // API data has higher confidence (0.90 > 0.70), so its price fields should be used
        assertEquals(BigDecimal("25"), result[0].canonical.minPrice)
        assertEquals(BigDecimal("45"), result[0].canonical.maxPrice)
    }

    // AC3.3: Different shows at the same venue on the same date remain as separate events
    @Test
    fun `AC3_3_different_shows_same_venue_same_date_remain_separate`() {
        val firstShow = createNormalizedEvent(
            title = "Jazz Fusion Collective",
            venueName = "Black Cat",
            startTime = Instant.parse("2026-03-15T19:00:00Z"),
            sourceType = SourceType.TICKETMASTER_API,
            sourceIdentifier = "api-111",
            artistNames = listOf("Jazz Fusion Collective")
        )

        val secondShow = createNormalizedEvent(
            title = "Punk Rock Extravaganza",
            venueName = "Black Cat",
            startTime = Instant.parse("2026-03-15T22:00:00Z"),
            sourceType = SourceType.TICKETMASTER_API,
            sourceIdentifier = "api-222",
            artistNames = listOf("Punk Rock Extravaganza")
        )

        val result = service.deduplicate(listOf(firstShow, secondShow))

        assertEquals(2, result.size)
        assertEquals(1, result[0].sources.size)
        assertEquals(1, result[1].sources.size)
    }

    // AC3.4: Shows with slightly different titles (Jaro-Winkler > 0.85) match and deduplicate
    @Test
    fun `AC3_4_similar_titles_jarowinkler_gt_085_merge`() {
        val event1 = createNormalizedEvent(
            title = "Artist Name",
            venueName = "Black Cat",
            startTime = Instant.parse("2026-03-15T20:00:00Z"),
            sourceType = SourceType.TICKETMASTER_API,
            sourceIdentifier = "api-123",
            confidenceScore = BigDecimal("0.90")
        )

        val event2 = createNormalizedEvent(
            title = "Artist Name w/ Opener",
            venueName = "Black Cat",
            startTime = Instant.parse("2026-03-15T20:00:00Z"),
            sourceType = SourceType.VENUE_SCRAPER,
            sourceIdentifier = "scraper-456",
            confidenceScore = BigDecimal("0.70")
        )

        val result = service.deduplicate(listOf(event1, event2))

        assertEquals(1, result.size)
        assertEquals(2, result[0].sources.size)
    }

    // AC3.5: Shows with same title but different dates are not deduplicated
    @Test
    fun `AC3_5_same_title_different_dates_remain_separate`() {
        val event1 = createNormalizedEvent(
            title = "Artist Name",
            venueName = "Black Cat",
            startTime = Instant.parse("2026-03-15T20:00:00Z"),
            sourceType = SourceType.TICKETMASTER_API,
            sourceIdentifier = "api-123"
        )

        val event2 = createNormalizedEvent(
            title = "Artist Name",
            venueName = "Black Cat",
            startTime = Instant.parse("2026-03-22T20:00:00Z"), // Different date
            sourceType = SourceType.TICKETMASTER_API,
            sourceIdentifier = "api-456"
        )

        val result = service.deduplicate(listOf(event1, event2))

        assertEquals(2, result.size)
        assertEquals(1, result[0].sources.size)
        assertEquals(1, result[1].sources.size)
    }

    // Test: isPrimaryMatch with exact match
    @Test
    fun `isPrimaryMatch with exact venue date and title returns true`() {
        val event1 = createNormalizedEvent(
            title = "Artist Name",
            venueName = "Black Cat",
            startTime = Instant.parse("2026-03-15T20:00:00Z")
        )

        val event2 = createNormalizedEvent(
            title = "Artist Name",
            venueName = "Black Cat",
            startTime = Instant.parse("2026-03-15T20:30:00Z") // Same date, slightly different time
        )

        assertTrue(service.isPrimaryMatch(event1, event2))
    }

    // Test: isPrimaryMatch with different venues
    @Test
    fun `isPrimaryMatch with different venues returns false`() {
        val event1 = createNormalizedEvent(
            title = "Artist Name",
            venueName = "Black Cat",
            startTime = Instant.parse("2026-03-15T20:00:00Z")
        )

        val event2 = createNormalizedEvent(
            title = "Artist Name",
            venueName = "9:30 Club",
            startTime = Instant.parse("2026-03-15T20:00:00Z")
        )

        assertFalse(service.isPrimaryMatch(event1, event2))
    }

    // Test: isPrimaryMatch with different dates
    @Test
    fun `isPrimaryMatch with different dates returns false`() {
        val event1 = createNormalizedEvent(
            title = "Artist Name",
            venueName = "Black Cat",
            startTime = Instant.parse("2026-03-15T20:00:00Z")
        )

        val event2 = createNormalizedEvent(
            title = "Artist Name",
            venueName = "Black Cat",
            startTime = Instant.parse("2026-03-22T20:00:00Z")
        )

        assertFalse(service.isPrimaryMatch(event1, event2))
    }

    // Test: isPrimaryMatch with low title similarity
    @Test
    fun `isPrimaryMatch with low title similarity returns false`() {
        val event1 = createNormalizedEvent(
            title = "Jazz Fusion Night",
            venueName = "Black Cat",
            startTime = Instant.parse("2026-03-15T20:00:00Z"),
            artistNames = listOf("Jazz Fusion Night")
        )

        val event2 = createNormalizedEvent(
            title = "Punk Rock Showcase",
            venueName = "Black Cat",
            startTime = Instant.parse("2026-03-15T20:00:00Z"),
            artistNames = listOf("Punk Rock Showcase")
        )

        assertFalse(service.isPrimaryMatch(event1, event2))
    }

    // Test: isSecondaryMatch with shared artist and same date
    @Test
    fun `isSecondaryMatch with shared artist and same date returns true`() {
        val event1 = createNormalizedEvent(
            title = "Artist A",
            venueName = "Venue A",
            startTime = Instant.parse("2026-03-15T20:00:00Z"),
            artistNames = listOf("Shared Artist", "Other Artist")
        )

        val event2 = createNormalizedEvent(
            title = "Artist B",
            venueName = "Venue B",
            startTime = Instant.parse("2026-03-15T21:00:00Z"),
            artistNames = listOf("Shared Artist", "Different Artist")
        )

        assertTrue(service.isSecondaryMatch(event1, event2))
    }

    // Test: isSecondaryMatch with different dates
    @Test
    fun `isSecondaryMatch with different dates returns false`() {
        val event1 = createNormalizedEvent(
            title = "Artist A",
            venueName = "Venue A",
            startTime = Instant.parse("2026-03-15T20:00:00Z"),
            artistNames = listOf("Shared Artist")
        )

        val event2 = createNormalizedEvent(
            title = "Artist B",
            venueName = "Venue B",
            startTime = Instant.parse("2026-03-22T20:00:00Z"),
            artistNames = listOf("Shared Artist")
        )

        assertFalse(service.isSecondaryMatch(event1, event2))
    }

    // Test: isSecondaryMatch with no shared artists
    @Test
    fun `isSecondaryMatch with no shared artists returns false`() {
        val event1 = createNormalizedEvent(
            title = "Artist A",
            venueName = "Venue A",
            startTime = Instant.parse("2026-03-15T20:00:00Z"),
            artistNames = listOf("Artist A")
        )

        val event2 = createNormalizedEvent(
            title = "Artist B",
            venueName = "Venue B",
            startTime = Instant.parse("2026-03-15T20:00:00Z"),
            artistNames = listOf("Artist B")
        )

        assertFalse(service.isSecondaryMatch(event1, event2))
    }

    // Test: findDuplicates returns matching events
    @Test
    fun `findDuplicates returns all duplicate candidates`() {
        val event1 = createNormalizedEvent(
            title = "Artist Name",
            venueName = "Black Cat",
            startTime = Instant.parse("2026-03-15T20:00:00Z"),
            sourceIdentifier = "api-123",
            artistNames = listOf("Artist Name")
        )

        val event2 = createNormalizedEvent(
            title = "Artist Name",
            venueName = "Black Cat",
            startTime = Instant.parse("2026-03-15T20:15:00Z"),
            sourceIdentifier = "scraper-456",
            artistNames = listOf("Artist Name")
        )

        val event3 = createNormalizedEvent(
            title = "Different Artist",
            venueName = "Different Venue",
            startTime = Instant.parse("2026-03-15T20:00:00Z"),
            sourceIdentifier = "api-789",
            artistNames = listOf("Different Artist")
        )

        val duplicates = service.findDuplicates(event1, listOf(event2, event3))

        assertEquals(1, duplicates.size)
        assertEquals("scraper-456", duplicates[0].sourceIdentifier)
    }

    // Test: mergeEvents selects highest confidence source
    @Test
    fun `mergeEvents uses canonical from highest confidence source`() {
        val lowConfidenceEvent = createNormalizedEvent(
            title = "Low Confidence Title",
            venueName = "Venue",
            startTime = Instant.parse("2026-03-15T20:00:00Z"),
            sourceType = SourceType.VENUE_SCRAPER,
            sourceIdentifier = "scraper-123",
            confidenceScore = BigDecimal("0.70")
        )

        val highConfidenceEvent = createNormalizedEvent(
            title = "High Confidence Title",
            venueName = "Venue",
            startTime = Instant.parse("2026-03-15T20:00:00Z"),
            sourceType = SourceType.TICKETMASTER_API,
            sourceIdentifier = "api-456",
            confidenceScore = BigDecimal("0.90")
        )

        val merged = service.mergeEvents(listOf(lowConfidenceEvent, highConfidenceEvent))

        // Canonical should use fields from highest confidence source
        assertEquals("High Confidence Title", merged.canonical.title)
        assertEquals(SourceType.TICKETMASTER_API, merged.canonical.sourceType)
        assertEquals(BigDecimal("0.90"), merged.canonical.confidenceScore)
    }

    // Test: mergeEvents includes all source attributions
    @Test
    fun `mergeEvents includes all source attributions`() {
        val event1 = createNormalizedEvent(
            sourceType = SourceType.TICKETMASTER_API,
            sourceIdentifier = "api-123",
            confidenceScore = BigDecimal("0.90")
        )

        val event2 = createNormalizedEvent(
            sourceType = SourceType.VENUE_SCRAPER,
            sourceIdentifier = "scraper-456",
            confidenceScore = BigDecimal("0.70")
        )

        val event3 = createNormalizedEvent(
            sourceType = SourceType.MANUAL,
            sourceIdentifier = "manual-789",
            confidenceScore = BigDecimal("0.50")
        )

        val merged = service.mergeEvents(listOf(event1, event2, event3))

        assertEquals(3, merged.sources.size)
        assertEquals(
            setOf("api-123", "scraper-456", "manual-789"),
            merged.sources.map { it.sourceIdentifier }.toSet()
        )
    }

    // Test: deduplicate with empty list
    @Test
    fun `deduplicate with empty list returns empty result`() {
        val result = service.deduplicate(emptyList())
        assertEquals(0, result.size)
    }

    // Test: deduplicate with single event
    @Test
    fun `deduplicate with single event returns single dedup event`() {
        val event = createNormalizedEvent()
        val result = service.deduplicate(listOf(event))

        assertEquals(1, result.size)
        assertEquals(1, result[0].sources.size)
        assertEquals("test-slug", result[0].canonical.slug)
    }

    // Test: deduplicate merges artist lists from multiple sources
    @Test
    fun `deduplicate merges artist lists from duplicate events`() {
        val event1 = createNormalizedEvent(
            title = "Artist Name",
            venueName = "Black Cat",
            startTime = Instant.parse("2026-03-15T20:00:00Z"),
            artistNames = listOf("Artist A", "Artist B"),
            sourceIdentifier = "api-123"
        )

        val event2 = createNormalizedEvent(
            title = "Artist Name",
            venueName = "Black Cat",
            startTime = Instant.parse("2026-03-15T20:00:00Z"),
            artistNames = listOf("Artist B", "Artist C"),
            sourceIdentifier = "scraper-456"
        )

        val result = service.deduplicate(listOf(event1, event2))

        assertEquals(1, result.size)
        assertEquals(3, result[0].canonical.artistNames.size)
        assertEquals(
            setOf("Artist A", "Artist B", "Artist C"),
            result[0].canonical.artistNames.toSet()
        )
    }

    // Test: deduplicate handles timezone-aware "same date" logic
    @Test
    fun `deduplicate considers same NY calendar date as match even with different UTC times`() {
        // Both in America/New_York timezone, should be same date
        val event1 = createNormalizedEvent(
            title = "Artist Name",
            venueName = "Black Cat",
            startTime = Instant.parse("2026-03-16T03:59:00Z"), // 2026-03-15 23:59 in NY
            sourceType = SourceType.TICKETMASTER_API,
            sourceIdentifier = "api-123"
        )

        val event2 = createNormalizedEvent(
            title = "Artist Name",
            venueName = "Black Cat",
            startTime = Instant.parse("2026-03-16T04:01:00Z"), // 2026-03-16 00:01 in NY
            sourceType = SourceType.VENUE_SCRAPER,
            sourceIdentifier = "scraper-456"
        )

        // These are on different calendar dates in NY timezone, so should NOT match
        val result = service.deduplicate(listOf(event1, event2))
        assertEquals(2, result.size)
    }

    // Test: deduplicate with case-insensitive venue matching
    @Test
    fun `deduplicate performs case-insensitive venue name matching`() {
        val event1 = createNormalizedEvent(
            title = "Artist Name",
            venueName = "BLACK CAT",
            startTime = Instant.parse("2026-03-15T20:00:00Z"),
            sourceType = SourceType.TICKETMASTER_API,
            sourceIdentifier = "api-123"
        )

        val event2 = createNormalizedEvent(
            title = "Artist Name",
            venueName = "black cat",
            startTime = Instant.parse("2026-03-15T20:00:00Z"),
            sourceType = SourceType.VENUE_SCRAPER,
            sourceIdentifier = "scraper-456"
        )

        val result = service.deduplicate(listOf(event1, event2))

        assertEquals(1, result.size)
        assertEquals(2, result[0].sources.size)
    }

    // AC1.3: venueAddress survives dedup merge — highest-confidence non-null address wins
    @Test
    fun `AC1_3_venueAddress_merge_picks_highest_confidence_non_null_address`() {
        val highConfidenceEvent = createNormalizedEvent(
            title = "Artist Name",
            venueName = "Black Cat",
            venueAddress = "1848 14th St NW, Washington, DC 20009",
            startTime = Instant.parse("2026-03-15T20:00:00Z"),
            sourceType = SourceType.TICKETMASTER_API,
            sourceIdentifier = "api-123",
            confidenceScore = BigDecimal("0.90")
        )

        val lowConfidenceEvent = createNormalizedEvent(
            title = "Artist Name",
            venueName = "Black Cat",
            venueAddress = "1848 14th Street NW, DC",
            startTime = Instant.parse("2026-03-15T20:00:00Z"),
            sourceType = SourceType.VENUE_SCRAPER,
            sourceIdentifier = "scraper-456",
            confidenceScore = BigDecimal("0.70")
        )

        val result = service.deduplicate(listOf(highConfidenceEvent, lowConfidenceEvent))

        assertEquals(1, result.size)
        assertEquals("1848 14th St NW, Washington, DC 20009", result[0].canonical.venueAddress)
    }

    // AC1.3: venueAddress merge — non-null address wins over null regardless of confidence
    @Test
    fun `AC1_3_venueAddress_merge_non_null_wins_over_null_regardless_of_confidence`() {
        val highConfidenceNoAddress = createNormalizedEvent(
            title = "Artist Name",
            venueName = "Black Cat",
            venueAddress = null,
            startTime = Instant.parse("2026-03-15T20:00:00Z"),
            sourceType = SourceType.TICKETMASTER_API,
            sourceIdentifier = "api-123",
            confidenceScore = BigDecimal("0.90")
        )

        val lowConfidenceWithAddress = createNormalizedEvent(
            title = "Artist Name",
            venueName = "Black Cat",
            venueAddress = "1848 14th St NW, Washington, DC 20009",
            startTime = Instant.parse("2026-03-15T20:00:00Z"),
            sourceType = SourceType.VENUE_SCRAPER,
            sourceIdentifier = "scraper-456",
            confidenceScore = BigDecimal("0.70")
        )

        val result = service.deduplicate(listOf(highConfidenceNoAddress, lowConfidenceWithAddress))

        assertEquals(1, result.size)
        assertEquals("1848 14th St NW, Washington, DC 20009", result[0].canonical.venueAddress)
    }
}
