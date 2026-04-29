package com.memetoclasm.districtlive.ingestion.connectors

import com.fasterxml.jackson.databind.ObjectMapper
import com.memetoclasm.districtlive.event.SourceType
import com.memetoclasm.districtlive.ingestion.ConnectorConfig
import kotlinx.coroutines.runBlocking
import org.junit.jupiter.api.DisplayName
import org.junit.jupiter.api.Test
import java.math.BigDecimal
import java.time.OffsetDateTime
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlin.test.assertTrue

class DiceFmConnectorTest {

    private val fixtureHtml: String = javaClass.getResourceAsStream(
        "/fixtures/dicefm-venue-events.html"
    )!!.bufferedReader().readText()

    private val secondVenueHtml: String = javaClass.getResourceAsStream(
        "/fixtures/dicefm-second-venue-events.html"
    )!!.bufferedReader().readText()

    /** Creates a testable connector; overrides fetchVenueHtml to return fixture HTML. */
    private fun makeTestableConnector(slugToHtml: Map<String, String>): DiceFmConnector {
        val config = ConnectorConfig(
            dice = ConnectorConfig.DiceConfig(
                venueSlugs = slugToHtml.keys.toList()
            )
        )
        return object : DiceFmConnector(config, ObjectMapper()) {
            override fun fetchVenueHtml(slug: String): String =
                slugToHtml[slug] ?: error("No fixture registered for slug '$slug'")
        }
    }

    private fun connector(): DiceFmConnector =
        makeTestableConnector(mapOf("songbyrd-r58r" to fixtureHtml))

    // ─── AC1.1 ───────────────────────────────────────────────────────────────

    @Test
    @DisplayName("AC1.1 - extracts all MusicEvent entries from JSON-LD Place block")
    fun `extracts two events from fixture`() {
        val events = connector().parseDiceFmJsonLd(fixtureHtml)
        assertEquals(2, events.size)
    }

    // ─── AC1.2 ───────────────────────────────────────────────────────────────

    @Test
    @DisplayName("AC1.2 - first event has title, startTime, venueName, venueAddress, sourceUrl, description")
    fun `first event has required fields`() {
        val events = connector().parseDiceFmJsonLd(fixtureHtml)
        val first = events[0]

        assertEquals("Test Artist Live", first.title)
        assertNotNull(first.startTime, "startTime must be populated")
        assertEquals("Songbyrd Music House", first.venueName)
        assertEquals("540 Penn St NE, Washington, DC 20002", first.venueAddress)
        assertEquals("https://dice.fm/event/abc1-test-artist-live-songbyrd", first.sourceUrl)
        assertEquals("A great show at Songbyrd", first.description)
    }

    // ─── AC1.3 ───────────────────────────────────────────────────────────────

    @Test
    @DisplayName("AC1.3 - sourceIdentifier is stable across repeated parses")
    fun `sourceIdentifier is deterministic`() {
        val c = connector()
        val first = c.parseDiceFmJsonLd(fixtureHtml)
        val second = c.parseDiceFmJsonLd(fixtureHtml)
        assertEquals(first[0].sourceIdentifier, second[0].sourceIdentifier)
        assertEquals(first[1].sourceIdentifier, second[1].sourceIdentifier)
    }

    @Test
    @DisplayName("AC1.3 - sourceIdentifier is derived from event URL slug")
    fun `sourceIdentifier derived from dice fm url`() {
        val events = connector().parseDiceFmJsonLd(fixtureHtml)
        // URL: https://dice.fm/event/abc1-test-artist-live-songbyrd → strip domain
        assertEquals("event/abc1-test-artist-live-songbyrd", events[0].sourceIdentifier)
    }

    // ─── AC1.4 ───────────────────────────────────────────────────────────────

    @Test
    @DisplayName("AC1.4 - aggregates events from multiple venue slugs into flat list")
    fun `aggregates events from two venues`() {
        val c = makeTestableConnector(
            mapOf(
                "songbyrd-r58r" to fixtureHtml,
                "dc9-q2xvo" to secondVenueHtml
            )
        )
        val result = runBlocking { c.fetch() }
        assertTrue(result.isRight())
        val events = result.getOrNull()!!
        assertEquals(3, events.size, "2 from Songbyrd + 1 from DC9 = 3 total")
    }

    // ─── AC2.1 ───────────────────────────────────────────────────────────────

    @Test
    @DisplayName("AC2.1 - ISO 8601 date with timezone offset parses to correct Instant")
    fun `startDate with timezone offset parses to correct Instant`() {
        val events = connector().parseDiceFmJsonLd(fixtureHtml)
        val startTime = events[0].startTime
        assertNotNull(startTime)
        assertEquals(OffsetDateTime.parse("2026-04-01T20:00:00-04:00").toInstant(), startTime)
    }

    @Test
    @DisplayName("AC2.1 - endDate also parses correctly")
    fun `endDate parses to correct Instant`() {
        val events = connector().parseDiceFmJsonLd(fixtureHtml)
        val endTime = events[0].endTime
        assertNotNull(endTime)
        assertEquals(OffsetDateTime.parse("2026-04-01T23:00:00-04:00").toInstant(), endTime)
    }

    // ─── AC2.2 ───────────────────────────────────────────────────────────────

    @Test
    @DisplayName("AC2.2 - imageUrl extracted from first element of image array")
    fun `imageUrl is first element of image array`() {
        val events = connector().parseDiceFmJsonLd(fixtureHtml)
        assertEquals("https://cdn.dice.fm/test-image-1.jpg", events[0].imageUrl)
        assertEquals("https://cdn.dice.fm/test-image-2.jpg", events[1].imageUrl)
    }

    // ─── AC2.3 ───────────────────────────────────────────────────────────────

    @Test
    @DisplayName("AC2.3 - sourceType is DICE_FM and confidenceScore is 0.80")
    fun `sourceType is DICE_FM and confidenceScore is 0_80`() {
        val events = connector().parseDiceFmJsonLd(fixtureHtml)
        for (event in events) {
            assertEquals(SourceType.DICE_FM, event.sourceType)
            assertEquals(BigDecimal("0.80"), event.confidenceScore)
        }
    }

    // ─── Additional field tests ───────────────────────────────────────────────

    @Test
    @DisplayName("Pricing: first event has minPrice=20.00, maxPrice=30.00")
    fun `pricing extracted from offers array`() {
        val events = connector().parseDiceFmJsonLd(fixtureHtml)
        assertEquals(BigDecimal("20.00"), events[0].minPrice)
        assertEquals(BigDecimal("30.00"), events[0].maxPrice)
    }

    @Test
    @DisplayName("Pricing: event with empty offers has null prices")
    fun `empty offers results in null pricing`() {
        val events = connector().parseDiceFmJsonLd(fixtureHtml)
        assertNull(events[1].minPrice)
        assertNull(events[1].maxPrice)
    }

    @Test
    @DisplayName("Missing JSON-LD: HTML without Place block returns empty list")
    fun `html without place json ld returns empty list`() {
        val htmlWithoutJsonLd = "<html><body><h1>No events</h1></body></html>"
        val events = connector().parseDiceFmJsonLd(htmlWithoutJsonLd)
        assertTrue(events.isEmpty())
    }

    @Test
    @DisplayName("ticketUrl equals sourceUrl (Dice.fm event page is the ticket link)")
    fun `ticketUrl equals sourceUrl`() {
        val events = connector().parseDiceFmJsonLd(fixtureHtml)
        assertEquals(events[0].sourceUrl, events[0].ticketUrl)
    }
}
