package com.memetoclasm.districtlive.ingestion.service

import com.fasterxml.jackson.databind.JsonNode
import com.fasterxml.jackson.databind.ObjectMapper
import org.apache.commons.text.similarity.JaroWinklerSimilarity
import org.junit.jupiter.api.Disabled
import org.junit.jupiter.api.Test
import org.junit.jupiter.params.ParameterizedTest
import org.junit.jupiter.params.provider.Arguments
import org.junit.jupiter.params.provider.MethodSource
import java.util.stream.Stream
import kotlin.test.assertTrue

/**
 * Fixture-driven normalization tests using 50 real Ticketmaster DMV events.
 *
 * These tests serve two purposes:
 *
 * 1. **[multiActTitles_extractCorrectly]** — For event titles that contain explicit
 *    multi-act separators (w/, with, /, ,), title-only extraction should produce ≥1 artist.
 *
 * 2. **[withAttractionNames_cleanedNamesMatchCanonical]** — When the connector passes
 *    Ticketmaster attraction names as explicit `artistNames`, extraction + cleaning should
 *    produce a result with Jaro-Winkler ≥ 0.80 vs the TM canonical name. This models the
 *    intended future improvement: connector reads attractions[] instead of leaving artistNames=[].
 *
 * 3. **[sandbox_printFullPipelineComparison]** — @Disabled diagnostic. Run manually to see
 *    the full comparison table revealing pipeline gaps (single-artist events currently return
 *    no artists when connector passes empty artistNames).
 *
 * Key finding from fixture data: The TicketmasterConnector currently passes artistNames=[]
 * to NormalizationService, so single-artist events like "Hanumankind" produce no artist
 * records. The fix is to populate artistNames from attractions[] in the connector.
 */
class TicketmasterFixtureNormalizationTest {

    private val service = NormalizationService()
    private val similarity = JaroWinklerSimilarity()

    private val separatorRegex = Regex("""\s+(?:w/|with|/)\s+|,\s*""")

    // ───────────────────────────────────────────────────────────────
    // Test 1: title-only extraction works for multi-act events
    // ───────────────────────────────────────────────────────────────

    @ParameterizedTest(name = "[{index}] {0}")
    @MethodSource("multiActTitleEvents")
    fun `multiActTitles - title-only extraction produces non-blank artists`(
        eventName: String,
        @Suppress("UNUSED_PARAMETER") attractionNames: List<String>
    ) {
        val extracted = service.extractArtists(eventName, emptyList())

        assertTrue(extracted.isNotEmpty(), "Expected ≥1 artist from multi-act title: \"$eventName\"")
        extracted.forEach { name ->
            assertTrue(name.isNotBlank(), "Blank artist name from: \"$eventName\"")
            assertTrue(name.length >= 2, "Suspiciously short name '$name' from: \"$eventName\"")
        }
    }

    // ───────────────────────────────────────────────────────────────
    // Test 2: passing attraction names produces clean, matching output
    // ───────────────────────────────────────────────────────────────

    @ParameterizedTest(name = "[{index}] {0} → [{1}]")
    @MethodSource("singleAttractionEvents")
    fun `withAttractionNames - cleaned name matches TM canonical (Jaro-Winkler ≥ 0·80)`(
        eventName: String,
        canonicalName: String
    ) {
        // Simulate improved connector that passes attractions[] as explicit artistNames
        val extracted = service.extractArtists(eventName, listOf(canonicalName))

        assertTrue(extracted.isNotEmpty(), "Expected ≥1 artist when passing canonicalName='$canonicalName'")

        val bestScore = extracted.maxOf { similarity.apply(it.lowercase(), canonicalName.lowercase()) }
        assertTrue(
            bestScore >= 0.80,
            "Expected Jaro-Winkler ≥ 0.80 vs canonical '$canonicalName'; " +
                "got ${"%.3f".format(bestScore)} for $extracted from \"$eventName\""
        )
    }

    // ───────────────────────────────────────────────────────────────
    // Diagnostic sandbox (disabled — run manually)
    // ───────────────────────────────────────────────────────────────

    @Test
    @Disabled("Diagnostic only — run manually to inspect pipeline output")
    fun `sandbox - print full pipeline comparison for all fixture events`() {
        val events = allFixtureEvents().toList()
        val colW = 46

        println()
        println("  ${"EVENT NAME".padEnd(colW)}| ${"TITLE-ONLY EXTRACTION".padEnd(colW)}| TM CANONICAL NAME(S)")
        println("  " + "-".repeat(colW * 3 + 4))

        for (args in events) {
            val eventName = args.get()[0] as String
            @Suppress("UNCHECKED_CAST")
            val attractionNames = args.get()[1] as List<String>

            val extracted = service.extractArtists(eventName, emptyList())
            val groundTruth = attractionNames.ifEmpty { listOf("(none)") }

            val bestScore = if (attractionNames.isNotEmpty() && extracted.isNotEmpty()) {
                extracted.flatMap { e -> attractionNames.map { a ->
                    similarity.apply(e.lowercase(), a.lowercase())
                }}.maxOrNull() ?: 0.0
            } else null

            val tag = when {
                extracted.isEmpty()  -> "✗ (no extraction — pipeline gap)"
                bestScore == null    -> "  (no TM ground truth)"
                bestScore >= 0.90   -> "✓"
                bestScore >= 0.75   -> "~"
                else                -> "✗ (low similarity ${"%.2f".format(bestScore)})"
            }

            println(
                "$tag ${eventName.take(colW - 2).padEnd(colW - 2)}" +
                "| ${extracted.joinToString(", ").take(colW - 2).padEnd(colW - 2)}" +
                "| ${groundTruth.joinToString(", ")}"
            )
        }
        println()
    }

    // ───────────────────────────────────────────────────────────────
    // Fixture loading
    // ───────────────────────────────────────────────────────────────

    companion object {
        private val mapper = ObjectMapper()

        private val fixtureRoot: JsonNode by lazy {
            val stream = TicketmasterFixtureNormalizationTest::class.java
                .classLoader
                .getResourceAsStream("fixtures/ticketmaster-dc-events.json")
                ?: error("Fixture not found: fixtures/ticketmaster-dc-events.json")
            mapper.readTree(stream)
        }

        private val separatorRegex = Regex("""\s+(?:w/|with|/)\s+|,\s*""")

        /** Events whose title contains at least one multi-act separator. */
        @JvmStatic
        fun multiActTitleEvents(): Stream<Arguments> =
            fixtureRoot.path("_embedded").path("events")
                .map { event ->
                    val name = event.path("name").asText()
                    val attractions = event.path("_embedded").path("attractions")
                        .map { it.path("name").asText() }.filter { it.isNotBlank() }
                    Arguments.of(name, attractions)
                }
                .filter { args -> separatorRegex.containsMatchIn(args.get()[0] as String) }
                .stream()

        /** All 50 fixture events — used by the sandbox diagnostic. */
        @JvmStatic
        fun allFixtureEvents(): Stream<Arguments> =
            fixtureRoot.path("_embedded").path("events")
                .map { event ->
                    val name = event.path("name").asText()
                    val attractions = event.path("_embedded").path("attractions")
                        .map { it.path("name").asText() }.filter { it.isNotBlank() }
                    Arguments.of(name, attractions)
                }
                .stream()

        /**
         * Events with exactly one TM attraction — unambiguous ground truth for
         * testing single-artist enrichment via explicit artistNames.
         */
        @JvmStatic
        fun singleAttractionEvents(): Stream<Arguments> =
            fixtureRoot.path("_embedded").path("events")
                .mapNotNull { event ->
                    val attractions = event.path("_embedded").path("attractions").toList()
                    if (attractions.size == 1) {
                        val canonical = attractions[0].path("name").asText()
                        if (canonical.isNotBlank())
                            Arguments.of(event.path("name").asText(), canonical)
                        else null
                    } else null
                }
                .stream()
    }
}
