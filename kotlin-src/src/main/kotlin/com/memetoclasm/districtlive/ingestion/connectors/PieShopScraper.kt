package com.memetoclasm.districtlive.ingestion.connectors

import com.fasterxml.jackson.databind.ObjectMapper
import com.memetoclasm.districtlive.event.SourceType
import com.memetoclasm.districtlive.ingestion.RawEventDto
import org.jsoup.nodes.Document
import org.slf4j.LoggerFactory
import org.springframework.stereotype.Component
import java.math.BigDecimal
import java.time.Instant
import java.time.LocalDate
import java.time.LocalTime
import java.time.ZonedDateTime
import java.time.format.DateTimeParseException

@Component
class PieShopScraper(objectMapper: ObjectMapper) : AbstractHtmlScraper(objectMapper) {

    private val logger = LoggerFactory.getLogger(PieShopScraper::class.java)

    override val sourceId: String = "pie-shop"
    override val url: String = "https://www.pieshopdc.com/shows"

    companion object {
        const val VENUE_NAME = "Pie Shop"
        const val VENUE_ADDRESS = "1339 H St NE, Washington, DC 20002"
    }

    override fun extractEvents(document: Document): List<RawEventDto> {
        val events = mutableListOf<RawEventDto>()
        val items = document.select(".ec-col-item.w-dyn-item")

        for (item in items) {
            try {
                val title = item.select(".title > div").text().trim()
                if (title.isBlank()) continue

                val dateText = item.select(".start-date > div").text().trim()
                val detailLink = item.select("a[href]").attr("abs:href").ifBlank { null }

                // Parse date from listing
                val eventDate = try {
                    LocalDate.parse(dateText, AbstractHtmlScraper.DATE_FORMATTER)
                } catch (e: DateTimeParseException) {
                    logger.warn("Unparseable date '{}' for event '{}'", dateText, title)
                    null
                }

                // Extract artist names from title
                val artistNames = title.split(",", " w/ ", " W/ ")
                    .map { it.trim() }
                    .filter { it.isNotBlank() }

                // Fetch detail page for enrichment
                var description: String? = null
                var minPrice: BigDecimal? = null
                var doorsTime: Instant? = null
                var showTime: Instant? = null
                var imageUrl: String? = null

                if (detailLink != null) {
                    val detailDoc = fetchDetailDocument(detailLink)
                    if (detailDoc != null) {
                        // Price from opendate-widget price attribute (numeric string like "15.00")
                        val priceAttr = detailDoc.select("opendate-widget").attr("price")
                        if (priceAttr.isNotBlank()) {
                            minPrice = priceAttr.toBigDecimalOrNull()
                        }

                        // Description
                        description = detailDoc.select(".confirm-description").text().trim().ifBlank { null }

                        // Doors time
                        val doorsText = detailDoc.select(".uui-event_time-wrapper-doors").text().trim()
                        doorsTime = parseTimeWithDate(doorsText, eventDate)

                        // Show time
                        val showText = detailDoc.select(".uui-event_time-wrapper-show").text().trim()
                        showTime = parseTimeWithDate(showText, eventDate)

                        // Image
                        val imgSrc = detailDoc.select("img").firstOrNull()?.attr("abs:src")
                        imageUrl = imgSrc?.ifBlank { null }
                    }
                }

                // Use show time as startTime, fall back to 8 PM default
                val startTime = showTime
                    ?: eventDate?.let {
                        ZonedDateTime.of(it, LocalTime.of(20, 0), DC_ZONE).toInstant()
                    }

                events.add(
                    RawEventDto(
                        sourceType = SourceType.VENUE_SCRAPER,
                        sourceIdentifier = generateSourceIdentifier(title, dateText),
                        sourceUrl = detailLink,
                        title = title,
                        description = description,
                        venueName = VENUE_NAME,
                        venueAddress = VENUE_ADDRESS,
                        artistNames = artistNames,
                        startTime = startTime,
                        doorsTime = doorsTime,
                        minPrice = minPrice,
                        ticketUrl = detailLink,
                        imageUrl = imageUrl,
                        confidenceScore = AbstractHtmlScraper.CONFIDENCE_SCORE
                    )
                )
            } catch (e: Exception) {
                logger.warn("Failed to parse Pie Shop event", e)
            }
        }

        return events
    }
}
