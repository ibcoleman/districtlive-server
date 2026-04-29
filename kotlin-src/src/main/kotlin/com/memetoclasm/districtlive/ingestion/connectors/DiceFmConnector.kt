package com.memetoclasm.districtlive.ingestion.connectors

import arrow.core.Either
import arrow.core.raise.either
import com.fasterxml.jackson.databind.JsonNode
import com.fasterxml.jackson.databind.ObjectMapper
import com.memetoclasm.districtlive.event.SourceType
import com.memetoclasm.districtlive.ingestion.ConnectorConfig
import com.memetoclasm.districtlive.ingestion.IngestionError
import com.memetoclasm.districtlive.ingestion.RawEventDto
import com.memetoclasm.districtlive.ingestion.SourceConnector
import org.jsoup.Connection
import org.jsoup.Jsoup
import org.jsoup.nodes.Document
import org.slf4j.LoggerFactory
import org.springframework.stereotype.Component
import java.math.BigDecimal
import java.time.Instant
import java.time.OffsetDateTime
import java.time.format.DateTimeParseException
import java.util.UUID

@Component
class DiceFmConnector(
    private val connectorConfig: ConnectorConfig,
    private val objectMapper: ObjectMapper
) : SourceConnector {

    override val sourceId: String = SOURCE_ID
    override val sourceType: SourceType = SourceType.DICE_FM

    private val logger = LoggerFactory.getLogger(DiceFmConnector::class.java)

    override suspend fun fetch(): Either<IngestionError, List<RawEventDto>> = either {
        val config = connectorConfig.dice
        val results = mutableListOf<RawEventDto>()
        val failedSlugs = mutableListOf<String>()

        for (slug in config.venueSlugs) {
            try {
                val html = fetchVenueHtml(slug)
                val events = parseDiceFmJsonLd(html)
                results.addAll(events)
                logger.debug("Fetched {} events from Dice.fm venue '{}'", events.size, slug)
            } catch (e: Exception) {
                logger.warn("Failed to fetch Dice.fm venue '{}': {}", slug, e.message)
                failedSlugs.add(slug)
            }
        }

        // Raise only when every slug failed. results.isEmpty() is redundant here (failedSlugs and
        // results are mutually exclusive: the catch block adds to failedSlugs, the try block adds to
        // results — so if all slugs threw, results is always empty) but kept as a defensive guard.
        if (failedSlugs.size == config.venueSlugs.size && results.isEmpty()) {
            raise(
                IngestionError.ConnectionError(
                    SOURCE_ID,
                    "All ${failedSlugs.size} Dice.fm venue fetches failed"
                )
            )
        }

        results
    }

    override fun healthCheck(): Boolean {
        val config = connectorConfig.dice
        if (config.venueSlugs.isEmpty()) return true

        return try {
            val firstSlug = config.venueSlugs.first()
            val connection = Jsoup.connect("$BASE_URL$firstSlug")
                .timeout(10_000)
                .userAgent("Mozilla/5.0 (compatible; DistrictLive/1.0)")
                .method(Connection.Method.HEAD)

            val response = connection.execute()
            response.statusCode() == 200
        } catch (e: Exception) {
            logger.warn("Health check failed for Dice.fm: ${e.message}")
            false
        }
    }

    /**
     * Fetches raw HTML for a Dice.fm venue page. Protected and open so tests can
     * override it to return fixture HTML without HTTP.
     */
    protected open fun fetchVenueHtml(slug: String): String {
        return Jsoup.connect("$BASE_URL$slug")
            .timeout(30_000)
            .userAgent("Mozilla/5.0 (compatible; DistrictLive/1.0)")
            .get()
            .html()
    }

    /**
     * Parses JSON-LD from a Dice.fm venue page HTML string. Internal and accessible
     * for direct testing without HTTP.
     *
     * Dice.fm embeds a single `Place` JSON-LD block with a nested `event[]` array of
     * `MusicEvent` objects — unlike standard JSON-LD where events appear at the top level.
     */
    internal fun parseDiceFmJsonLd(html: String): List<RawEventDto> {
        val document: Document = Jsoup.parse(html)
        val scriptTags = document.select("script[type=application/ld+json]")

        for (script in scriptTags) {
            val json = script.data().ifBlank { script.html() }.trim()
            if (json.isBlank()) continue
            try {
                val node = objectMapper.readTree(json)
                if (node.path("@type").asText("") == "Place") {
                    return parsePlaceNode(node)
                }
            } catch (e: Exception) {
                logger.warn("Failed to parse JSON-LD block: {}", e.message)
            }
        }

        logger.warn("No Place JSON-LD block found in Dice.fm page")
        return emptyList()
    }

    private fun parsePlaceNode(placeNode: JsonNode): List<RawEventDto> {
        val venueName = placeNode.path("name").asText(null)
        val venueAddress = extractAddress(placeNode.path("address"))

        val eventArray = placeNode.path("event")
        if (!eventArray.isArray) return emptyList()

        val events = mutableListOf<RawEventDto>()
        for (eventNode in eventArray) {
            try {
                val dto = mapMusicEventToDto(eventNode, venueName, venueAddress)
                if (dto != null) events.add(dto)
            } catch (e: Exception) {
                logger.warn("Skipping malformed MusicEvent: {}", e.message)
            }
        }
        return events
    }

    private fun mapMusicEventToDto(
        eventNode: JsonNode,
        parentVenueName: String?,
        parentVenueAddress: String?
    ): RawEventDto? {
        val title = eventNode.path("name").asText(null)?.takeIf { it.isNotBlank() } ?: return null
        val url = eventNode.path("url").asText(null)?.takeIf { it.isNotBlank() }
        val startTime = eventNode.path("startDate").asText(null)?.let { parseIsoInstant(it) }
        val endTime = eventNode.path("endDate").asText(null)?.let { parseIsoInstant(it) }
        val description = eventNode.path("description").asText(null)?.takeIf { it.isNotBlank() }
        val imageUrl = extractFirstImage(eventNode.path("image"))
        val (minPrice, maxPrice) = extractPricing(eventNode.path("offers"))

        // Event's own location overrides parent Place
        val locationNode = eventNode.path("location")
        val venueName = locationNode.path("name").asText(null)?.takeIf { it.isNotBlank() }
            ?: parentVenueName
        val venueAddress = extractAddress(locationNode.path("address"))
            ?: parentVenueAddress

        val sourceIdentifier = url?.let { deriveSourceIdentifier(it) }
            ?: deriveSourceIdentifier("$title|${eventNode.path("startDate").asText("")}")

        return RawEventDto(
            sourceType = SourceType.DICE_FM,
            sourceIdentifier = sourceIdentifier,
            sourceUrl = url,
            ticketUrl = url,
            title = title,
            description = description,
            venueName = venueName,
            venueAddress = venueAddress,
            startTime = startTime,
            endTime = endTime,
            imageUrl = imageUrl,
            minPrice = minPrice,
            maxPrice = maxPrice,
            confidenceScore = BigDecimal("0.80")
        )
    }

    private fun extractAddress(addressNode: JsonNode): String? = when {
        addressNode.isMissingNode || addressNode.isNull -> null
        addressNode.isTextual -> addressNode.asText(null)?.takeIf { it.isNotBlank() }
        addressNode.isObject -> {
            val parts = listOf(
                addressNode.path("streetAddress").asText(""),
                addressNode.path("addressLocality").asText(""),
                addressNode.path("addressRegion").asText(""),
                addressNode.path("postalCode").asText("")
            ).filter { it.isNotBlank() }
            parts.joinToString(", ").takeIf { it.isNotBlank() }
        }
        else -> null
    }

    private fun extractFirstImage(imageNode: JsonNode): String? = when {
        imageNode.isMissingNode || imageNode.isNull -> null
        imageNode.isArray && imageNode.size() > 0 -> {
            val first = imageNode[0]
            if (first.isTextual) first.asText(null) else first.path("url").asText(null)
        }
        imageNode.isTextual -> imageNode.asText(null)
        imageNode.isObject -> imageNode.path("url").asText(null)
        else -> null
    }

    private fun extractPricing(offersNode: JsonNode): Pair<BigDecimal?, BigDecimal?> {
        if (offersNode.isMissingNode || offersNode.isNull || !offersNode.isArray) {
            return Pair(null, null)
        }
        val prices = offersNode
            .mapNotNull { offer -> offer.path("price").asText(null)?.toBigDecimalOrNull() }
            .filter { it > BigDecimal.ZERO }
        return if (prices.isEmpty()) Pair(null, null) else Pair(prices.min(), prices.max())
    }

    private fun parseIsoInstant(dateStr: String): Instant? = try {
        OffsetDateTime.parse(dateStr).toInstant()
    } catch (e: DateTimeParseException) {
        try {
            Instant.parse(dateStr)
        } catch (e2: DateTimeParseException) {
            logger.warn("Could not parse date '{}': {}", dateStr, e.message)
            null
        }
    }

    /**
     * Derives a stable, unique sourceIdentifier from a Dice.fm event URL.
     * Strips the domain prefix, leaving e.g. "event/abc1-test-artist-live-songbyrd".
     * Falls back to a deterministic UUID based on the input bytes if extraction fails.
     */
    internal fun deriveSourceIdentifier(input: String): String {
        val extracted = input.substringAfter("dice.fm/")
        return if (extracted.isNotBlank()) {
            extracted
        } else {
            UUID.nameUUIDFromBytes(input.toByteArray()).toString()
        }
    }

    companion object {
        const val SOURCE_ID = "dicefm"
        private const val BASE_URL = "https://dice.fm/venue/"
    }
}
