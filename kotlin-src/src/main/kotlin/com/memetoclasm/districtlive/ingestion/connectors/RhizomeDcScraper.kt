package com.memetoclasm.districtlive.ingestion.connectors

import com.fasterxml.jackson.databind.ObjectMapper
import com.memetoclasm.districtlive.ingestion.RawEventDto
import com.memetoclasm.districtlive.event.SourceType
import org.jsoup.nodes.Document
import org.slf4j.LoggerFactory
import org.springframework.stereotype.Component
import java.math.BigDecimal
import java.time.Instant
import java.time.LocalDate
import java.time.LocalTime
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.time.format.DateTimeParseException

@Component
class RhizomeDcScraper(objectMapper: ObjectMapper) : AbstractHtmlScraper(objectMapper) {

    private val logger = LoggerFactory.getLogger(RhizomeDcScraper::class.java)

    override val sourceId: String = "rhizome-dc"
    override val url: String = "https://www.rhizomedc.org/new-events"

    companion object {
        private const val BASE_URL = "https://www.rhizomedc.org"
        private const val VENUE_NAME = "Rhizome DC"
        private const val VENUE_ADDRESS = "6950 Maple St NW, Washington, DC 20012"
        private val CONFIDENCE_SCORE = BigDecimal("0.80")

        // Squarespace EventList selectors
        private const val EVENT_CONTAINER_SELECTOR = "article.eventlist-event--upcoming"
        private const val EVENT_TITLE_SELECTOR = "h1.eventlist-title a.eventlist-title-link"
        private const val EVENT_DATE_SELECTOR = "time.event-date"
        private const val EVENT_TIME_START_SELECTOR = "time.event-time-12hr-start"
        private const val EVENT_TIME_END_SELECTOR = "time.event-time-12hr-end"
        private const val EVENT_IMAGE_SELECTOR = "img.eventlist-thumbnail"
        private const val EVENT_EXCERPT_SELECTOR = "div.eventlist-excerpt"

        private val PRICE_REGEX = Regex("""\$(\d+)(?:[-–](\d+))?""")
        private val TIME_12HR_FORMATTER = DateTimeFormatter.ofPattern("h:mm a")
        private val EASTERN = ZoneId.of("America/New_York")
    }

    override fun extractEvents(document: Document): List<RawEventDto> {
        val eventElements = document.select(EVENT_CONTAINER_SELECTOR)

        if (eventElements.isEmpty()) {
            logger.warn("No event containers found using selector: $EVENT_CONTAINER_SELECTOR")
            return emptyList()
        }

        val events = mutableListOf<RawEventDto>()

        for (element in eventElements) {
            try {
                val titleEl = element.selectFirst(EVENT_TITLE_SELECTOR) ?: continue
                val title = titleEl.text().trim()
                if (title.isBlank()) continue

                val relativeUrl = titleEl.attr("href")
                val eventUrl = if (relativeUrl.isNotBlank()) "$BASE_URL$relativeUrl" else null

                // Machine-readable date from datetime attribute
                val dateAttr = element.selectFirst(EVENT_DATE_SELECTOR)?.attr("datetime") ?: ""
                val localDate = parseDateAttr(dateAttr)

                // Start/end times
                val startTimeText = element.selectFirst(EVENT_TIME_START_SELECTOR)?.text()?.trim() ?: ""
                val endTimeText = element.selectFirst(EVENT_TIME_END_SELECTOR)?.text()?.trim() ?: ""

                val startInstant = localDate?.let { combineDateTime(it, startTimeText) }
                val endInstant = localDate?.let { combineDateTime(it, endTimeText) }

                // Image: lazy-loaded, use data-src
                val imageUrl = element.selectFirst(EVENT_IMAGE_SELECTOR)?.let {
                    it.attr("data-src").takeIf { s -> s.isNotBlank() } ?: it.attr("src").takeIf { s -> s.isNotBlank() }
                }

                // Price and ticket URL from excerpt free text
                val excerptEl = element.selectFirst(EVENT_EXCERPT_SELECTOR)
                val excerptText = excerptEl?.text() ?: ""
                val (minPrice, maxPrice) = parsePriceRange(excerptText)
                val ticketUrl = excerptEl?.selectFirst("a[href]")?.attr("href")
                    ?.takeIf { it.isNotBlank() && !it.contains("rhizomedc.org") }

                events.add(RawEventDto(
                    sourceType = SourceType.VENUE_SCRAPER,
                    sourceIdentifier = generateSourceIdentifier(title, dateAttr),
                    sourceUrl = eventUrl,
                    title = title,
                    venueName = VENUE_NAME,
                    venueAddress = VENUE_ADDRESS,
                    startTime = startInstant,
                    endTime = endInstant,
                    minPrice = minPrice,
                    maxPrice = maxPrice,
                    ticketUrl = ticketUrl,
                    imageUrl = imageUrl,
                    confidenceScore = CONFIDENCE_SCORE
                ))
            } catch (e: Exception) {
                logger.warn("Failed to parse Rhizome DC event: ${e.message}")
            }
        }

        logger.debug("Extracted ${events.size} events from Rhizome DC")
        return events
    }

    private fun parseDateAttr(dateAttr: String): LocalDate? {
        if (dateAttr.isBlank()) return null
        return try {
            LocalDate.parse(dateAttr.take(10)) // "2026-02-20" — take first 10 chars
        } catch (_: DateTimeParseException) {
            logger.debug("Could not parse Rhizome date attribute: '$dateAttr'")
            null
        }
    }

    private fun combineDateTime(date: LocalDate, timeText: String): Instant? {
        if (timeText.isBlank()) return date.atStartOfDay(EASTERN).toInstant()
        return try {
            val localTime = LocalTime.parse(timeText.uppercase(), TIME_12HR_FORMATTER)
            date.atTime(localTime).atZone(EASTERN).toInstant()
        } catch (_: DateTimeParseException) {
            date.atStartOfDay(EASTERN).toInstant()
        }
    }

    private fun parsePriceRange(text: String): Pair<BigDecimal?, BigDecimal?> {
        val match = PRICE_REGEX.find(text) ?: return Pair(null, null)
        val min = match.groupValues[1].toBigDecimalOrNull()
        val max = match.groupValues[2].takeIf { it.isNotBlank() }?.toBigDecimalOrNull()
        return Pair(min, max ?: min)
    }
}
