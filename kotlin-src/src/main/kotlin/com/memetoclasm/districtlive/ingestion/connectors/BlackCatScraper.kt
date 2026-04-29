package com.memetoclasm.districtlive.ingestion.connectors

import com.fasterxml.jackson.databind.ObjectMapper
import com.memetoclasm.districtlive.ingestion.RawEventDto
import com.memetoclasm.districtlive.event.SourceType
import org.jsoup.nodes.Document
import org.slf4j.LoggerFactory
import org.springframework.stereotype.Component
import java.math.BigDecimal
import java.time.LocalDate
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.time.format.DateTimeParseException

@Component
class BlackCatScraper(objectMapper: ObjectMapper) : AbstractHtmlScraper(objectMapper) {

    private val logger = LoggerFactory.getLogger(BlackCatScraper::class.java)

    override val sourceId: String = "black-cat"
    override val url: String = "https://www.blackcatdc.com/schedule.html"

    companion object {
        private const val BASE_URL = "https://www.blackcatdc.com"
        private const val EVENT_CONTAINER_SELECTOR = "div.show"
        private const val EVENT_TITLE_SELECTOR = "h1.headline a"
        private const val EVENT_DATE_SELECTOR = "h2.date"
        private const val EVENT_SHOW_TEXT_SELECTOR = "p.show-text"
        private const val EVENT_TICKET_LINK_SELECTOR = "div.show-details > a[href*='etix.com']"
        private const val EVENT_IMAGE_SELECTOR = "div.band-photo-sm img"

        private const val VENUE_NAME = "Black Cat"
        private const val VENUE_ADDRESS = "1811 14th St NW, Washington, DC 20009"
        private val CONFIDENCE_SCORE = BigDecimal("0.70")

        // Date formats Black Cat uses: "Saturday February 21", "Sunday March 22"
        private val DATE_FORMATTERS = listOf(
            DateTimeFormatter.ofPattern("EEEE MMMM d yyyy"),
            DateTimeFormatter.ofPattern("MMMM d yyyy"),
            DateTimeFormatter.ofPattern("MMM d yyyy")
        )
    }

    override fun extractEvents(document: Document): List<RawEventDto> {
        val eventElements = document.select(EVENT_CONTAINER_SELECTOR)

        if (eventElements.isEmpty()) {
            logger.warn("No event containers found using selector: $EVENT_CONTAINER_SELECTOR")
            return emptyList()
        }

        val events = mutableListOf<RawEventDto>()
        val currentYear = LocalDate.now().year

        for (element in eventElements) {
            try {
                val titleEl = element.selectFirst(EVENT_TITLE_SELECTOR) ?: continue
                val title = titleEl.text().trim()
                if (title.isBlank()) continue

                val dateText = element.select(EVENT_DATE_SELECTOR).text().trim()
                val startTime = parseEventDate(dateText, currentYear)

                val showText = element.select(EVENT_SHOW_TEXT_SELECTOR).first()?.text() ?: ""
                val ticketUrl = element.selectFirst(EVENT_TICKET_LINK_SELECTOR)?.attr("href")
                    ?.takeIf { it.isNotBlank() }

                val rawImageSrc = element.selectFirst(EVENT_IMAGE_SELECTOR)?.attr("src") ?: ""
                val imageUrl = when {
                    rawImageSrc.startsWith("http") -> rawImageSrc
                    rawImageSrc.isNotBlank() -> "$BASE_URL$rawImageSrc"
                    else -> null
                }

                val detailLink = titleEl.attr("href").let {
                    when {
                        it.startsWith("http") -> it
                        it.isNotBlank() -> "$BASE_URL$it"
                        else -> null
                    }
                }

                events.add(RawEventDto(
                    sourceType = SourceType.VENUE_SCRAPER,
                    sourceIdentifier = generateSourceIdentifier(title, dateText),
                    sourceUrl = detailLink ?: ticketUrl,
                    title = title,
                    venueName = VENUE_NAME,
                    venueAddress = VENUE_ADDRESS,
                    startTime = startTime,
                    ticketUrl = ticketUrl,
                    imageUrl = imageUrl,
                    confidenceScore = CONFIDENCE_SCORE
                ))
            } catch (e: Exception) {
                logger.warn("Failed to parse Black Cat event: ${e.message}")
            }
        }

        logger.debug("Extracted ${events.size} events from Black Cat schedule")
        return events
    }

    private fun parseEventDate(dateText: String, currentYear: Int): java.time.Instant? {
        if (dateText.isBlank()) return null
        // Append current year since the page doesn't include it
        val withYear = "$dateText $currentYear"
        for (formatter in DATE_FORMATTERS) {
            try {
                val localDate = LocalDate.parse(withYear, formatter)
                return localDate.atStartOfDay(ZoneId.of("America/New_York")).toInstant()
            } catch (_: DateTimeParseException) {
                continue
            }
        }
        logger.debug("Could not parse Black Cat date: '$dateText'")
        return null
    }
}
