package com.memetoclasm.districtlive.ingestion.service

import com.memetoclasm.districtlive.event.PriceTier
import com.memetoclasm.districtlive.event.SourceType
import com.memetoclasm.districtlive.ingestion.IngestionError
import com.memetoclasm.districtlive.ingestion.RawEventDto
import java.math.BigDecimal
import java.time.Instant
import java.time.LocalDate
import org.junit.jupiter.api.Test
import org.junit.jupiter.params.ParameterizedTest
import org.junit.jupiter.params.provider.CsvSource
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class NormalizationServiceTest {

    private val service = NormalizationService()

    // Test venue matching
    @Test
    fun `matchVenue with exact name match returns matched venue slug`() {
        val candidates = listOf(
            VenueMatchCandidate("black-cat", "Black Cat", "1848 14th St NW, Washington, DC")
        )
        val result = service.matchVenue("Black Cat", null, candidates)
        assertTrue(result.matched)
        assertEquals("black-cat", result.venueSlug)
    }

    @Test
    fun `matchVenue with fuzzy match (Jaro-Winkler above threshold) returns matched venue slug`() {
        val candidates = listOf(
            VenueMatchCandidate("black-cat", "Black Cat", "1848 14th St NW, Washington, DC")
        )
        val result = service.matchVenue("Black Cat DC", null, candidates)
        // "Black Cat DC" vs "Black Cat" should have high Jaro-Winkler similarity
        assertTrue(result.matched)
        assertEquals("black-cat", result.venueSlug)
    }

    @Test
    fun `matchVenue with unknown venue returns no match`() {
        val candidates = listOf(
            VenueMatchCandidate("black-cat", "Black Cat", "1848 14th St NW, Washington, DC")
        )
        val result = service.matchVenue("Unknown Venue XYZ", null, candidates)
        assertTrue(!result.matched)
        assertEquals(null, result.venueSlug)
    }

    @Test
    fun `matchVenue with empty candidates returns no match`() {
        val result = service.matchVenue("Black Cat", null, emptyList())
        assertTrue(!result.matched)
        assertEquals(null, result.venueSlug)
    }

    // Test artist extraction
    @Test
    fun `extractArtists with slash separator splits correctly`() {
        val result = service.extractArtists("Artist w/ Opener", emptyList())
        assertEquals(listOf("Artist", "Opener"), result)
    }

    @Test
    fun `extractArtists with slash splits correctly`() {
        val result = service.extractArtists("Artist / Band / DJ", emptyList())
        assertEquals(listOf("Artist", "Band", "DJ"), result)
    }

    @Test
    fun `extractArtists deduplicates against existing artist names`() {
        val result = service.extractArtists("Artist / Band / DJ", listOf("Artist"))
        assertEquals(setOf("Artist", "Band", "DJ"), result.toSet())
    }

    @Test
    fun `extractArtists with standalone title returns empty list`() {
        // Titles with no separator pattern should not generate artist records
        val result = service.extractArtists("Solo Artist", emptyList())
        assertEquals(0, result.size)
    }

    @Test
    fun `extractArtists with standalone title and explicit artistNames returns artistNames`() {
        val result = service.extractArtists("2026 Fun-A-Day Showcase", listOf("Some Band"))
        assertEquals(listOf("Some Band"), result)
    }

    @Test
    fun `extractArtists with comma separator splits correctly`() {
        val result = service.extractArtists("Artist, Band, DJ", emptyList())
        assertEquals(3, result.size)
        assertEquals("Artist", result[0])
        assertEquals("Band", result[1])
        assertEquals("DJ", result[2])
    }

    // Test cleanArtistName via extractArtists
    @Test
    fun `cleanArtistName strips leading 'and ' from raw name (AC1_1)`() {
        // Title with separator + leading "and" in one part
        val result = service.extractArtists("and The Bandits / Some Opener", emptyList())
        // "and The Bandits" splits, becomes "The Bandits" after cleanup, "Some Opener" untouched
        assertEquals(2, result.size)
        assertEquals("The Bandits", result[0])
        assertEquals("Some Opener", result[1])
    }

    @Test
    fun `cleanArtistName strips leading '& ' from raw name (AC1_2a)`() {
        val result = service.extractArtists("", listOf("& The Bandits"))
        assertEquals(listOf("The Bandits"), result)
    }

    @Test
    fun `cleanArtistName strips leading 'with ' from raw name (AC1_2b)`() {
        val result = service.extractArtists("", listOf("with Someone"))
        assertEquals(listOf("Someone"), result)
    }

    @Test
    fun `cleanArtistName strips leading feat prefix from raw name (AC1_2c)`() {
        val result = service.extractArtists("", listOf("feat. Guest"))
        assertEquals(listOf("Guest"), result)
    }

    @Test
    fun `cleanArtistName strips leading ft prefix from raw name (AC1_2d)`() {
        val result = service.extractArtists("", listOf("ft. Guest"))
        assertEquals(listOf("Guest"), result)
    }

    @Test
    fun `cleanArtistName with and feat prefixes are case-insensitive (AC1_2e)`() {
        // "with " and "feat. " strip regardless of case
        assertEquals(listOf("Someone"), service.extractArtists("", listOf("With Someone")))
        assertEquals(listOf("Guest"), service.extractArtists("", listOf("Feat. Guest")))
        // "and " only strips lowercase — title-case "And" is preserved (band name protection)
        assertEquals(listOf("And The Bandits"), service.extractArtists("", listOf("And The Bandits")))
        assertEquals(listOf("The Bandits"), service.extractArtists("", listOf("and The Bandits")))
    }

    @Test
    fun `cleanArtistName strips trailing comma (AC1_3a)`() {
        val result = service.extractArtists("", listOf("Artist,"))
        assertEquals(listOf("Artist"), result)
    }

    @Test
    fun `cleanArtistName strips trailing semicolon (AC1_3b)`() {
        val result = service.extractArtists("", listOf("Artist;"))
        assertEquals(listOf("Artist"), result)
    }

    @Test
    fun `cleanArtistName strips trailing period (AC1_3c)`() {
        val result = service.extractArtists("", listOf("Artist."))
        assertEquals(listOf("Artist"), result)
    }

    @Test
    fun `cleanArtistName falls back to original if cleanup produces empty (AC1_4)`() {
        val result = service.extractArtists("", listOf("."))
        assertEquals(listOf("."), result)
    }

    @Test
    fun `cleanArtistName empty names are dropped from artist list (AC1_5)`() {
        val result = service.extractArtists("", listOf("  ", "Artist"))
        assertEquals(listOf("Artist"), result)
    }

    // New separator patterns
    @Test
    fun `extractArtists splits on ampersand separator`() {
        val result = service.extractArtists("Boy George & Culture Club", emptyList())
        assertEquals(listOf("Boy George", "Culture Club"), result)
    }

    @Test
    fun `extractArtists splits on spaced dash separator`() {
        val result = service.extractArtists("Clinton Kane - 4350 Live", emptyList())
        // "4350 Live" contains no tour keyword → not stripped, treated as second act
        assertEquals(listOf("Clinton Kane", "4350 Live"), result)
    }

    // Tour/subtitle suffix stripping
    @Test
    fun `extractArtists strips tour suffix before splitting`() {
        val result = service.extractArtists("LAUNDRY DAY: The Time of Your Life Tour", emptyList())
        // Colon suffix contains "Tour" → stripped, leaving single-artist title
        assertEquals(emptyList<String>(), result)
    }

    @Test
    fun `extractArtists strips tour suffix then splits on separator`() {
        val result = service.extractArtists("Peter McPoland & DUG: Big Lucky Tour", emptyList())
        assertEquals(listOf("Peter McPoland", "DUG"), result)
    }

    @Test
    fun `extractArtists does not strip colon suffix without tour keyword`() {
        // "Vol. 2" has no tour keyword → colon is NOT stripped
        val result = service.extractArtists("Artist: Vol. 2", emptyList())
        assertEquals(emptyList<String>(), result) // no separator → empty
    }

    // special guest prefix stripping
    @Test
    fun `cleanArtistName strips special guest prefix`() {
        val result = service.extractArtists("", listOf("special guest Andy Louis"))
        assertEquals(listOf("Andy Louis"), result)
    }

    @Test
    fun `cleanArtistName strips special guests prefix`() {
        val result = service.extractArtists("", listOf("special guests The Openers"))
        assertEquals(listOf("The Openers"), result)
    }

    @Test
    fun `extractArtists with dodie with special guest splits and cleans correctly`() {
        val result = service.extractArtists("dodie with special guest Andy Louis", emptyList())
        assertEquals(listOf("dodie", "Andy Louis"), result)
    }

    // Test price tier normalization
    @Test
    fun `normalizePriceTier with zero price returns FREE`() {
        val result = service.normalizePriceTier(BigDecimal("0"), null)
        assertEquals(PriceTier.FREE, result)
    }

    @Test
    fun `normalizePriceTier with price under 15 returns UNDER_15`() {
        val result = service.normalizePriceTier(BigDecimal("12"), BigDecimal("14"))
        assertEquals(PriceTier.UNDER_15, result)
    }

    @Test
    fun `normalizePriceTier with price 15-30 returns PRICE_15_TO_30`() {
        val result = service.normalizePriceTier(BigDecimal("25"), BigDecimal("30"))
        assertEquals(PriceTier.PRICE_15_TO_30, result)
    }

    @Test
    fun `normalizePriceTier with price over 30 returns OVER_30`() {
        val result = service.normalizePriceTier(BigDecimal("35"), BigDecimal("50"))
        assertEquals(PriceTier.OVER_30, result)
    }

    @Test
    fun `normalizePriceTier with null prices returns null`() {
        val result = service.normalizePriceTier(null, null)
        assertEquals(null, result)
    }

    @Test
    fun `normalizePriceTier uses max price for tier determination`() {
        val result = service.normalizePriceTier(BigDecimal("5"), BigDecimal("10"))
        assertEquals(PriceTier.UNDER_15, result)
    }

    // Test slug generation
    @Test
    fun `generateSlug creates URL-friendly slug from title, venue, date`() {
        val result = service.generateSlug(
            "Artist Name",
            "Black Cat",
            LocalDate.of(2026, 3, 15)
        )
        assertEquals("artist-name-black-cat-2026-03-15", result)
    }

    @Test
    fun `generateSlug handles special characters`() {
        val result = service.generateSlug(
            "Artist & Friends!",
            "The Black Cat",
            LocalDate.of(2026, 3, 15)
        )
        // Should strip special characters and convert to lowercase with hyphens
        assertTrue(result.contains("artist"))
        assertTrue(result.contains("friends"))
        assertTrue(result.contains("black"))
        assertTrue(result.contains("cat"))
        assertTrue(result.endsWith("2026-03-15"))
    }

    @Test
    fun `generateSlug handles multiple spaces`() {
        val result = service.generateSlug(
            "Artist   Name",
            "Black   Cat",
            LocalDate.of(2026, 3, 15)
        )
        // Multiple spaces should be collapsed to single hyphen
        assertTrue(result.contains("artist-name"))
        assertTrue(result.contains("black-cat"))
    }

    // Test timezone normalization
    @Test
    fun `normalizeTimezone returns instant as-is (already UTC)`() {
        val instant = Instant.parse("2026-03-15T20:00:00Z")
        val result = service.normalizeTimezone(instant)
        assertEquals(instant, result)
    }

    @Test
    fun `normalizeTimezone returns null for null input`() {
        val result = service.normalizeTimezone(null)
        assertEquals(null, result)
    }

    // Test genre tagging
    @Test
    fun `tagGenre with existing genres returns them as-is`() {
        val genres = listOf("Rock", "Pop")
        val result = service.tagGenre("Artist Name", genres)
        assertEquals(genres, result)
    }

    @Test
    fun `tagGenre with empty genres returns empty list`() {
        val result = service.tagGenre("Artist Name", emptyList())
        assertEquals(emptyList(), result)
    }

    // Test normalize() public API entry point
    @Test
    fun `normalize with valid RawEventDto list returns Right containing normalized events`() {
        val rawEvents = listOf(
            RawEventDto(
                sourceType = SourceType.TICKETMASTER_API,
                sourceIdentifier = "tm-123",
                title = "Artist Name",
                venueName = "Black Cat",
                startTime = Instant.parse("2026-03-15T20:00:00Z"),
                minPrice = BigDecimal("25"),
                maxPrice = BigDecimal("45"),
                confidenceScore = BigDecimal("0.90")
            ),
            RawEventDto(
                sourceType = SourceType.VENUE_SCRAPER,
                sourceIdentifier = "scraper-456",
                title = "Another Show",
                venueName = "9:30 Club",
                startTime = Instant.parse("2026-03-20T21:00:00Z"),
                confidenceScore = BigDecimal("0.70")
            )
        )

        val result = service.normalize(rawEvents)

        assertTrue(result.isRight())
        result.onRight { events ->
            assertEquals(2, events.size)
            assertEquals("Artist Name", events[0].title)
            assertEquals("Another Show", events[1].title)
            assertEquals("Black Cat", events[0].venueName)
            assertEquals("9:30 Club", events[1].venueName)
        }
    }

    @Test
    fun `normalize with null startTime skips event and returns empty list`() {
        val rawEvents = listOf(
            RawEventDto(
                sourceType = SourceType.TICKETMASTER_API,
                sourceIdentifier = "tm-123",
                title = "Artist Name",
                venueName = "Black Cat",
                startTime = null,  // Missing required startTime
                confidenceScore = BigDecimal("0.90")
            )
        )

        val result = service.normalize(rawEvents)

        assertTrue(result.isRight())
        result.onRight { events ->
            assertTrue(events.isEmpty())
        }
    }

    @Test
    fun `normalize with blank title skips event and returns empty list`() {
        val rawEvents = listOf(
            RawEventDto(
                sourceType = SourceType.TICKETMASTER_API,
                sourceIdentifier = "tm-123",
                title = "   ",  // Blank title
                venueName = "Black Cat",
                startTime = Instant.parse("2026-03-15T20:00:00Z"),
                confidenceScore = BigDecimal("0.90")
            )
        )

        val result = service.normalize(rawEvents)

        assertTrue(result.isRight())
        result.onRight { events ->
            assertTrue(events.isEmpty())
        }
    }

    // AC1.3: venueAddress passes through normalizeEvent() from RawEventDto to NormalizedEvent
    @Test
    fun `AC1_3_venueAddress_passes_through_normalization`() {
        val rawEvents = listOf(
            RawEventDto(
                sourceType = SourceType.TICKETMASTER_API,
                sourceIdentifier = "tm-123",
                title = "Artist Name",
                venueName = "Black Cat",
                venueAddress = "1234 Main St, Washington, DC",
                startTime = Instant.parse("2026-03-15T20:00:00Z"),
                confidenceScore = BigDecimal("0.90")
            )
        )

        val result = service.normalize(rawEvents)

        assertTrue(result.isRight())
        result.onRight { events ->
            assertEquals(1, events.size)
            assertEquals("1234 Main St, Washington, DC", events[0].venueAddress)
        }
    }

    // AC1.3: venueAddress null in RawEventDto produces null in NormalizedEvent (no error)
    @Test
    fun `AC1_3_venueAddress_null_produces_null_in_normalized_event`() {
        val rawEvents = listOf(
            RawEventDto(
                sourceType = SourceType.TICKETMASTER_API,
                sourceIdentifier = "tm-456",
                title = "Another Show",
                venueName = "9:30 Club",
                venueAddress = null,
                startTime = Instant.parse("2026-03-20T21:00:00Z"),
                confidenceScore = BigDecimal("0.80")
            )
        )

        val result = service.normalize(rawEvents)

        assertTrue(result.isRight())
        result.onRight { events ->
            assertEquals(1, events.size)
            assertEquals(null, events[0].venueAddress)
        }
    }

    // ---------------------------------------------------------------------------
    // cleanEventTitle
    // ---------------------------------------------------------------------------
    @ParameterizedTest(name = "[{index}] \"{0}\" -> \"{1}\"")
    @CsvSource(
        delimiter = '|',
        value = [
            // --- prefix stripping ---
            "An Evening with Mitski            | Mitski",
            "A Evening with Mitski             | Mitski",
            "an evening with Mitski            | Mitski",
            "Evening with Mitski               | Mitski",
            "Evening: Mitski                   | Mitski",
            "with Mitski                       | Mitski",
            "With Mitski                       | Mitski",
            "am Mitski                         | Mitski",
            "AM Mitski                         | Mitski",
            // --- no change expected ---
            "Mitski                            | Mitski",
            "DJ Snake & Lil Jon                | DJ Snake & Lil Jon",
            "With You (band name)              | You (band name)",
            // --- stripping must not produce blank (fall back to original) ---
            "with                              | with",
            "am                               | am",
        ]
    )
    fun `cleanEventTitle sandbox`(input: String, expected: String) {
        assertEquals(expected.trim(), service.cleanEventTitle(input.trim()))
    }

    @Test
    fun `cleanEventTitle applied during normalization strips with prefix from title and slug`() {
        val rawEvents = listOf(
            RawEventDto(
                sourceType = SourceType.VENUE_SCRAPER,
                sourceIdentifier = "usp-123",
                title = "with Mitski",
                venueName = "Union Stage",
                startTime = Instant.parse("2026-05-15T00:00:00Z"),
                confidenceScore = BigDecimal("0.80")
            )
        )

        val result = service.normalize(rawEvents)

        assertTrue(result.isRight())
        result.onRight { events ->
            assertEquals(1, events.size)
            assertEquals("Mitski", events[0].title)
            assertTrue(events[0].slug.startsWith("mitski-"), "Slug should start with 'mitski-', got: ${events[0].slug}")
        }
    }

    // ---------------------------------------------------------------------------
    // cleanArtistName — parameterized sandbox
    //
    // Add a row to explore how a weird string gets cleaned.
    // Format: "input string | expected output"
    // Run: ./district-live-server/gradlew -p district-live-server test --tests
    //      "com.memetoclasm.districtlive.ingestion.service.NormalizationServiceTest.cleanArtistName*"
    // ---------------------------------------------------------------------------
    @ParameterizedTest(name = "[{index}] \"{0}\" -> \"{1}\"")
    @CsvSource(
        delimiter = '|',
        value = [
            // --- leading prefix stripping ---
            "and The Bandits                | The Bandits",
            "AND THE BANDITS                | AND THE BANDITS",
            "& The Bandits                  | The Bandits",
            "with Someone                   | Someone",
            "feat. Guest                    | Guest",
            "ft. Guest                      | Guest",
            // --- trailing punctuation stripping ---
            "Artist,                        | Artist",
            "Artist;                        | Artist",
            "Artist.                        | Artist",
            "Artist...                      | Artist",
            // --- no change expected ---
            "Mitski                         | Mitski",
            "DJ Snake & Lil Jon             | DJ Snake & Lil Jon",
            "And Justice For All            | And Justice For All",
            // --- edge cases ---
            // "feat." has no trailing space so prefix doesn't match; trailing '.' is then stripped
            "feat.                          | feat",
            "and                            | and",
        ]
    )
    fun `cleanArtistName sandbox`(input: String, expected: String) {
        assertEquals(expected.trim(), service.cleanArtistName(input.trim()))
    }

    // AC2.2: Timezone edge case tests for slug generation
    @Test
    fun `AC2_2_slug_generation_11pm_eastern_produces_eastern_date`() {
        // 2026-03-16T03:00:00Z = 2026-03-15 11:00 PM ET
        val rawEvents = listOf(
            RawEventDto(
                sourceType = SourceType.TICKETMASTER_API,
                sourceIdentifier = "tz-test-1",
                title = "Late Night Show",
                venueName = "Black Cat",
                startTime = Instant.parse("2026-03-16T03:00:00Z"),
                confidenceScore = BigDecimal("0.90")
            )
        )

        val result = service.normalize(rawEvents)

        assertTrue(result.isRight())
        result.onRight { events ->
            assertEquals(1, events.size)
            // Slug should contain 2026-03-15 (Eastern date), NOT 2026-03-16 (UTC date)
            assertTrue(events[0].slug.contains("2026-03-15"), "Slug should contain Eastern date 2026-03-15, got: ${events[0].slug}")
        }
    }

    @Test
    fun `AC2_2_slug_generation_midnight_eastern_produces_correct_eastern_date`() {
        // 2026-03-16T04:00:00Z = 2026-03-16 12:00 AM ET (midnight)
        val rawEvents = listOf(
            RawEventDto(
                sourceType = SourceType.TICKETMASTER_API,
                sourceIdentifier = "tz-test-2",
                title = "Midnight Show",
                venueName = "9:30 Club",
                startTime = Instant.parse("2026-03-16T04:00:00Z"),
                confidenceScore = BigDecimal("0.90")
            )
        )

        val result = service.normalize(rawEvents)

        assertTrue(result.isRight())
        result.onRight { events ->
            assertEquals(1, events.size)
            // Slug should contain 2026-03-16 (Eastern date)
            assertTrue(events[0].slug.contains("2026-03-16"), "Slug should contain Eastern date 2026-03-16, got: ${events[0].slug}")
        }
    }

    @Test
    fun `AC2_2_slug_generation_11pm_eastern_daylight_time_produces_correct_date`() {
        // 2026-07-16T03:00:00Z = 2026-07-15 11:00 PM EDT (EDT is UTC-4, not UTC-5)
        val rawEvents = listOf(
            RawEventDto(
                sourceType = SourceType.TICKETMASTER_API,
                sourceIdentifier = "tz-test-3",
                title = "Summer Late Show",
                venueName = "Fillmore DC",
                startTime = Instant.parse("2026-07-16T03:00:00Z"),
                confidenceScore = BigDecimal("0.90")
            )
        )

        val result = service.normalize(rawEvents)

        assertTrue(result.isRight())
        result.onRight { events ->
            assertEquals(1, events.size)
            // Slug should contain 2026-07-15 (Eastern date during EDT)
            assertTrue(events[0].slug.contains("2026-07-15"), "Slug should contain Eastern date 2026-07-15, got: ${events[0].slug}")
        }
    }

    // Tests for normalizeVenueName

    @Test
    fun `normalizeVenueName strips Trump prefix from Kennedy Center Concert Hall`() {
        assertEquals("Kennedy Center", service.normalizeVenueName("Trump Kennedy Center - Concert Hall"))
    }

    @Test
    fun `normalizeVenueName strips Trump prefix from Kennedy Center Opera House`() {
        assertEquals("Kennedy Center", service.normalizeVenueName("Trump Kennedy Center - Opera House"))
    }

    @Test
    fun `normalizeVenueName strips Trump prefix case-insensitively`() {
        assertEquals("Kennedy Center", service.normalizeVenueName("trump Kennedy Center - Eisenhower Theater"))
    }

    @Test
    fun `normalizeVenueName leaves unaffected venue names unchanged`() {
        assertEquals("Black Cat", service.normalizeVenueName("Black Cat"))
        assertEquals("The Hamilton", service.normalizeVenueName("The Hamilton"))
        assertEquals("Howard Theatre-DC", service.normalizeVenueName("Howard Theatre-DC"))
    }

    @Test
    fun `normalizeVenueName strips sub-venue qualifier from Kennedy Center`() {
        assertEquals("Kennedy Center", service.normalizeVenueName("Trump Kennedy Center - Terrace Theater"))
    }
}
