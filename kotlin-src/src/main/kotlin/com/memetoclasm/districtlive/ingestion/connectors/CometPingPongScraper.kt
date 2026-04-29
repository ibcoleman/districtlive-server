package com.memetoclasm.districtlive.ingestion.connectors

import com.fasterxml.jackson.databind.ObjectMapper
import com.memetoclasm.districtlive.event.SourceType
import com.memetoclasm.districtlive.ingestion.RawEventDto
import org.jsoup.nodes.Document
import org.slf4j.LoggerFactory
import org.springframework.stereotype.Component
import java.math.BigDecimal
import java.time.LocalDate
import java.time.LocalTime
import java.time.ZonedDateTime
import java.time.format.DateTimeParseException

@Component
class CometPingPongScraper(objectMapper: ObjectMapper) : AbstractHtmlScraper(objectMapper) {

    private val logger = LoggerFactory.getLogger(CometPingPongScraper::class.java)

    override val sourceId: String = "comet-ping-pong"
    override val url: String = "https://calendar.rediscoverfirebooking.com/cpp-shows"

    companion object {
        const val VENUE_NAME = "Comet Ping Pong"
        const val VENUE_ADDRESS = "5037 Connecticut Ave NW, Washington, DC 20008"
    }

    override fun extractEvents(document: Document): List<RawEventDto> {
        val events = mutableListOf<RawEventDto>()
        // Select ONLY desktop items — ignore mobile duplicates (.uui-layout88_item-mobile-cpp)
        val items = document.select(".uui-layout88_item-cpp.w-dyn-item")

        for (item in items) {
            try {
                val title = item.select(".uui-heading-xxsmall-2").text().trim()
                if (title.isBlank()) continue

                val dateText = item.select(".heading-date").text().trim()
                val timeText = item.select(".heading-time").text().trim()
                val ageText = item.select(".ages-2").text().trim().ifBlank { null }
                val imageUrl = item.select(".image-42").attr("src").ifBlank { null }
                val detailLink = item.select("a.link-block-3[href]").attr("abs:href").ifBlank { null }

                // Parse date from listing
                val eventDate = try {
                    LocalDate.parse(dateText, AbstractHtmlScraper.DATE_FORMATTER)
                } catch (e: DateTimeParseException) {
                    logger.warn("Unparseable date '{}' for event '{}'", dateText, title)
                    null
                }

                // Parse time from listing (CPP provides time on listing page)
                val startTime = parseTimeWithDate(timeText, eventDate)
                    ?: eventDate?.let {
                        ZonedDateTime.of(it, LocalTime.of(20, 0), DC_ZONE).toInstant()
                    }

                // Extract artist names from title (split on comma)
                val artistNames = title.split(",")
                    .map { it.trim() }
                    .filter { it.isNotBlank() }

                // Fetch detail page for price and description
                var description: String? = null
                var minPrice: BigDecimal? = null

                if (detailLink != null) {
                    val detailDoc = fetchDetailDocument(detailLink)
                    if (detailDoc != null) {
                        // Price from tickets wrapper text (contains $-prefixed amount)
                        val priceText = detailDoc.select(".uui-event_tickets-wrapper").text().trim()
                        if (priceText.isNotBlank()) {
                            minPrice = parsePriceFromText(priceText)
                        }

                        // Description
                        description = detailDoc.select(".confirm-description").text().trim().ifBlank { null }
                    }
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
                        minPrice = minPrice,
                        ticketUrl = detailLink,
                        imageUrl = imageUrl,
                        ageRestriction = ageText,
                        confidenceScore = AbstractHtmlScraper.CONFIDENCE_SCORE
                    )
                )
            } catch (e: Exception) {
                logger.warn("Failed to parse Comet Ping Pong event", e)
            }
        }

        return events
    }
}
