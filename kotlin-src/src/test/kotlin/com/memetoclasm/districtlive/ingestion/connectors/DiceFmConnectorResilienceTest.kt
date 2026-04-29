package com.memetoclasm.districtlive.ingestion.connectors

import arrow.core.Either
import com.fasterxml.jackson.databind.ObjectMapper
import com.memetoclasm.districtlive.ingestion.ConnectorConfig
import com.memetoclasm.districtlive.ingestion.IngestionError
import kotlinx.coroutines.runBlocking
import org.junit.jupiter.api.DisplayName
import org.junit.jupiter.api.Test
import kotlin.test.assertEquals
import kotlin.test.assertIs
import kotlin.test.assertTrue

class DiceFmConnectorResilienceTest {

    private fun loadFixture(name: String): String =
        javaClass.getResourceAsStream("/fixtures/$name")!!.bufferedReader().readText()

    private val emptyEventsHtml: String = loadFixture("dicefm-empty-events.html")
    private val noJsonLdHtml: String = loadFixture("dicefm-no-jsonld.html")
    private val mixedEventsHtml: String = loadFixture("dicefm-mixed-events.html")
    private val songbyrdHtml: String = loadFixture("dicefm-venue-events.html")

    /**
     * Creates a testable connector where slugs in [failingSlugs] throw on fetch,
     * and all others return their mapped fixture HTML.
     */
    private fun makeConnector(
        slugToHtml: Map<String, String>,
        failingSlugs: Set<String> = emptySet()
    ): DiceFmConnector {
        val allSlugs = slugToHtml.keys + failingSlugs
        val config = ConnectorConfig(
            dice = ConnectorConfig.DiceConfig(
                venueSlugs = allSlugs.toList()
            )
        )
        return object : DiceFmConnector(config, ObjectMapper()) {
            override fun fetchVenueHtml(slug: String): String {
                if (slug in failingSlugs) throw RuntimeException("Simulated network failure for '$slug'")
                return slugToHtml[slug] ?: error("No fixture for slug '$slug'")
            }
        }
    }

    // ─── AC3.1 ───────────────────────────────────────────────────────────────

    @Test
    @DisplayName("AC3.1 - 1 of 2 venue fetches fails; events from the successful venue are still returned")
    fun `partial venue failure still returns events from successful venue`() {
        val c = makeConnector(
            slugToHtml = mapOf("songbyrd-r58r" to songbyrdHtml),
            failingSlugs = setOf("dc9-q2xvo")
        )
        val result = runBlocking { c.fetch() }
        assertTrue(result.isRight(), "Expected Right but got $result")
        val events = result.getOrNull()!!
        assertEquals(2, events.size, "Songbyrd fixture has 2 events; DC9 failed but should not block them")
    }

    // ─── AC3.2 ───────────────────────────────────────────────────────────────

    @Test
    @DisplayName("AC3.2 - venue page with empty event array returns empty list, not error")
    fun `empty event array returns empty list`() {
        val c = makeConnector(mapOf("empty-venue" to emptyEventsHtml))
        val result = runBlocking { c.fetch() }
        assertTrue(result.isRight(), "Expected Right(emptyList()) but got $result")
        assertTrue(result.getOrNull()!!.isEmpty(), "Expected empty list for venue with no events")
    }

    @Test
    @DisplayName("AC3.2 - parseDiceFmJsonLd with empty event array returns empty list")
    fun `parseDiceFmJsonLd with empty event array returns empty list`() {
        val c = makeConnector(mapOf("empty-venue" to emptyEventsHtml))
        val events = c.parseDiceFmJsonLd(emptyEventsHtml)
        assertTrue(events.isEmpty())
    }

    // ─── AC3.3 ───────────────────────────────────────────────────────────────

    @Test
    @DisplayName("AC3.3 - venue page with no JSON-LD block returns empty list (no exception)")
    fun `page without json ld returns empty list`() {
        val c = makeConnector(mapOf("no-jsonld-venue" to noJsonLdHtml))
        val result = runBlocking { c.fetch() }
        assertTrue(result.isRight(), "Expected Right(emptyList()) but got $result")
        assertTrue(result.getOrNull()!!.isEmpty())
    }

    @Test
    @DisplayName("AC3.3 - parseDiceFmJsonLd with no JSON-LD block returns empty list")
    fun `parseDiceFmJsonLd with no json ld returns empty list`() {
        val c = makeConnector(mapOf("slug" to noJsonLdHtml))
        val events = c.parseDiceFmJsonLd(noJsonLdHtml)
        assertTrue(events.isEmpty())
    }

    // ─── AC3.4 ───────────────────────────────────────────────────────────────

    @Test
    @DisplayName("AC3.4 - malformed events skipped; valid events in same venue still extracted")
    fun `malformed event entries are skipped but valid events extracted`() {
        val c = makeConnector(mapOf("test-venue" to mixedEventsHtml))
        val events = c.parseDiceFmJsonLd(mixedEventsHtml)
        assertEquals(1, events.size, "Only 1 valid event out of 3 entries (2 have blank/missing name)")
        assertEquals("Valid Event", events[0].title)
    }

    // ─── AC3.5 ───────────────────────────────────────────────────────────────

    @Test
    @DisplayName("AC3.5 - when ALL venue fetches fail, connector returns Left(IngestionError)")
    fun `all venue failures returns Left`() {
        val c = makeConnector(
            slugToHtml = emptyMap(),
            failingSlugs = setOf("slug-1", "slug-2", "slug-3")
        )
        val result = runBlocking { c.fetch() }
        assertIs<Either.Left<IngestionError>>(result, "Expected Left(IngestionError) when all venues fail")
        assertIs<IngestionError.ConnectionError>(result.value)
    }
}
