package com.memetoclasm.districtlive.ingestion.connectors

import arrow.core.Either
import arrow.core.left
import arrow.core.right
import com.fasterxml.jackson.databind.ObjectMapper
import com.memetoclasm.districtlive.ingestion.IngestionError
import com.memetoclasm.districtlive.ingestion.RawEventDto
import com.memetoclasm.districtlive.ingestion.SourceConnector
import com.memetoclasm.districtlive.event.SourceType
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.jsoup.Connection
import org.jsoup.Jsoup
import org.jsoup.nodes.Document
import org.slf4j.LoggerFactory
import java.math.BigDecimal
import java.time.Instant
import java.time.LocalDate
import java.time.LocalTime
import java.time.ZoneId
import java.time.ZonedDateTime
import java.time.format.DateTimeFormatter

abstract class AbstractHtmlScraper(
    protected val objectMapper: ObjectMapper
) : SourceConnector {

    private val logger = LoggerFactory.getLogger(AbstractHtmlScraper::class.java)

    abstract val url: String

    override val sourceType: SourceType = SourceType.VENUE_SCRAPER

    companion object {
        private const val REQUEST_TIMEOUT_MS = 10000
        private const val USER_AGENT =
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
        val DC_ZONE: ZoneId = ZoneId.of("America/New_York")
        val TIME_PATTERN: Regex = Regex("(\\d{1,2}(?::\\d{2})?)\\s*(AM|PM|am|pm)", RegexOption.IGNORE_CASE)
        val DATE_FORMATTER: DateTimeFormatter = DateTimeFormatter.ofPattern("MMMM d, yyyy")
        val CONFIDENCE_SCORE: BigDecimal = BigDecimal("0.70")
    }

    override suspend fun fetch(): Either<IngestionError, List<RawEventDto>> = try {
        fetchDocument(url).map { document ->
            try {
                extractEvents(document)
            } catch (e: Exception) {
                logger.error("Error extracting events from $url", e)
                throw e
            }
        }.mapLeft { error ->
            logger.error("Error fetching or processing document from $url")
            error
        }
    } catch (e: Exception) {
        logger.error("Unexpected error in fetch() for $url", e)
        IngestionError.ParseError(sourceId, e.message ?: "Failed to extract events").left()
    }

    protected suspend fun fetchDocument(documentUrl: String): Either<IngestionError, Document> = try {
        val document = withContext(Dispatchers.IO) {
            Jsoup.connect(documentUrl)
                .timeout(REQUEST_TIMEOUT_MS)
                .userAgent(USER_AGENT)
                .followRedirects(true)
                .get()
        }
        document.right()
    } catch (e: Exception) {
        when (e) {
            is java.net.SocketTimeoutException, is java.net.ConnectException, is java.net.UnknownHostException -> {
                IngestionError.ConnectionError(sourceId, "Connection error: ${e.message ?: e.javaClass.simpleName}").left()
            }
            is org.jsoup.HttpStatusException -> {
                IngestionError.HttpError(e.statusCode, e.message ?: "HTTP error").left()
            }
            else -> {
                IngestionError.ConnectionError(sourceId, e.message ?: "Failed to fetch document").left()
            }
        }
    }

    protected fun extractJsonLd(document: Document): List<Map<String, Any>> {
        val jsonLdScripts = document.select("script[type=application/ld+json]")
        val events = mutableListOf<Map<String, Any>>()

        for (scriptTag in jsonLdScripts) {
            try {
                val jsonLdContent = scriptTag.html()
                val jsonNode = objectMapper.readTree(jsonLdContent)

                val eventType = when {
                    jsonNode.isArray -> {
                        // Handle array of objects
                        for (item in jsonNode) {
                            val type = item.path("@type").asText()
                            if (type == "Event" || type == "MusicEvent") {
                                @Suppress("UNCHECKED_CAST")
                                events.add(objectMapper.convertValue(item, Map::class.java) as Map<String, Any>)
                            }
                        }
                        continue
                    }
                    else -> {
                        jsonNode.path("@type").asText()
                    }
                }

                if (eventType == "Event" || eventType == "MusicEvent") {
                    @Suppress("UNCHECKED_CAST")
                    val eventMap = objectMapper.convertValue(jsonNode, Map::class.java) as Map<String, Any>
                    events.add(eventMap)
                }
            } catch (e: Exception) {
                logger.warn("Failed to parse JSON-LD from script tag: ${e.message}")
            }
        }

        return events
    }

    protected fun parseJsonLdEvent(jsonLd: Map<String, Any>): RawEventDto? {
        return try {
            val name = jsonLd["name"]?.toString() ?: return null
        val startDate = jsonLd["startDate"]?.toString()?.let { parseIsoInstant(it) }
        val endDate = jsonLd["endDate"]?.toString()?.let { parseIsoInstant(it) }

        val location = extractLocationData(jsonLd["location"])
        val venueName = location?.get("name")?.toString()
        val venueAddress = location?.get("address")?.toString()

        val description = jsonLd["description"]?.toString()
        val imageUrl = when (val image = jsonLd["image"]) {
            is String -> image
            is List<*> -> image.firstOrNull()?.toString()
            is Map<*, *> -> image["url"]?.toString()
            else -> null
        }

        val offers = extractOffersData(jsonLd["offers"])
        val minPrice = (offers?.get("price") ?: offers?.get("lowPrice"))?.toString()?.toBigDecimalOrNull()
        val maxPrice = offers?.get("highPrice")?.toString()?.toBigDecimalOrNull()
        val ticketUrl = offers?.get("url")?.toString()

        RawEventDto(
            sourceType = SourceType.VENUE_SCRAPER,
            sourceIdentifier = name.hashCode().toString(),
            sourceUrl = ticketUrl,
            title = name,
            description = description,
            venueName = venueName,
            venueAddress = venueAddress,
            startTime = startDate,
            endTime = endDate,
            minPrice = minPrice,
            maxPrice = maxPrice,
            ticketUrl = ticketUrl,
            imageUrl = imageUrl,
            confidenceScore = BigDecimal("0.75")
            )
        } catch (e: Exception) {
            logger.warn("Failed to parse JSON-LD event: ${e.message}. Raw data: $jsonLd")
            null
        }
    }

    private fun parseIsoInstant(dateString: String): Instant? = try {
        when {
            dateString.contains("T") -> Instant.parse(dateString)
            dateString.length == 10 -> {
                // Parse date-only format YYYY-MM-DD as start of day
                Instant.parse("${dateString}T00:00:00Z")
            }
            else -> null
        }
    } catch (e: Exception) {
        logger.warn("Failed to parse ISO date: $dateString")
        null
    }

    private fun extractLocationData(location: Any?): Map<String, Any>? = try {
        when (location) {
            is Map<*, *> -> {
                @Suppress("UNCHECKED_CAST")
                location as Map<String, Any>
            }
            is String -> mapOf("name" to location)
            else -> null
        }
    } catch (e: Exception) {
        logger.warn("Failed to extract location data: ${e.message}")
        null
    }

    private fun extractOffersData(offers: Any?): Map<String, Any>? = try {
        when (offers) {
            is List<*> -> {
                // If array, take the first offer
                offers.firstOrNull().let { offer ->
                    when (offer) {
                        is Map<*, *> -> {
                            @Suppress("UNCHECKED_CAST")
                            offer as Map<String, Any>
                        }
                        else -> null
                    }
                }
            }
            is Map<*, *> -> {
                @Suppress("UNCHECKED_CAST")
                offers as Map<String, Any>
            }
            else -> null
        }
    } catch (e: Exception) {
        logger.warn("Failed to extract offers data: ${e.message}")
        null
    }

    protected fun parsePriceFromText(priceText: String): BigDecimal? {
        return try {
            if (priceText.isBlank()) return null

            // Extract first dollar amount found
            val priceRegex = Regex("""\$\s*(\d+(?:\.\d{2})?)""")
            val matchResult = priceRegex.find(priceText)
            matchResult?.groupValues?.getOrNull(1)?.toBigDecimalOrNull()
        } catch (e: Exception) {
            logger.debug("Failed to parse price: $priceText - ${e.message}")
            null
        }
    }

    protected fun generateSourceIdentifier(title: String, dateText: String): String {
        // Combine title and date with separator, pad hashCode to fixed length
        val combined = "$title|$dateText"
        val hash = combined.hashCode().toString()
        return hash.take(16).padEnd(16, '0')
    }

    /**
     * Fetch a detail page document. Protected open so subclasses (and tests) can override
     * to return fixture HTML without making HTTP calls.
     */
    protected open fun fetchDetailDocument(detailUrl: String): Document? {
        return try {
            Jsoup.connect(detailUrl)
                .userAgent("DistrictLive/1.0")
                .timeout(10_000)
                .get()
        } catch (e: Exception) {
            logger.warn("Failed to fetch detail page: $detailUrl", e)
            null
        }
    }

    /**
     * Parse a time string (e.g. "8:00 PM") together with a date into an Instant,
     * using America/New_York timezone. Returns null if date or timeText is missing/unparseable.
     */
    protected fun parseTimeWithDate(timeText: String, date: LocalDate?, zone: ZoneId = DC_ZONE): Instant? {
        if (date == null || timeText.isBlank()) return null
        val match = TIME_PATTERN.find(timeText) ?: return null
        val (timePart, amPm) = match.destructured
        val parts = timePart.split(":")
        var hour = parts[0].toInt()
        val minute = if (parts.size > 1) parts[1].toInt() else 0
        val isPm = amPm.equals("PM", ignoreCase = true)
        if (isPm && hour != 12) hour += 12
        if (!isPm && hour == 12) hour = 0
        val localTime = LocalTime.of(hour, minute)
        return ZonedDateTime.of(date, localTime, zone).toInstant()
    }

    abstract fun extractEvents(document: Document): List<RawEventDto>

    override fun healthCheck(): Boolean = try {
        val connection = Jsoup.connect(url)
            .timeout(REQUEST_TIMEOUT_MS)
            .userAgent(USER_AGENT)
            .followRedirects(true)
            .method(Connection.Method.HEAD)

        val response = connection.execute()
        response.statusCode() == 200
    } catch (e: Exception) {
        logger.warn("Health check failed for $url: ${e.message}")
        false
    }
}
