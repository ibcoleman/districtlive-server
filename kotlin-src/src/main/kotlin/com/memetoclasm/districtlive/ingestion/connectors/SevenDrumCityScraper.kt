package com.memetoclasm.districtlive.ingestion.connectors

import com.fasterxml.jackson.databind.ObjectMapper
import com.memetoclasm.districtlive.ingestion.RawEventDto
import com.memetoclasm.districtlive.event.SourceType
import org.jsoup.nodes.Document
import org.slf4j.LoggerFactory
import org.springframework.stereotype.Component
import java.math.BigDecimal
import java.time.LocalDate
import java.time.LocalTime
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.time.format.DateTimeParseException

@Component
class SevenDrumCityScraper(objectMapper: ObjectMapper) : AbstractHtmlScraper(objectMapper) {

    private val logger = LoggerFactory.getLogger(SevenDrumCityScraper::class.java)

    override val sourceId: String = "7-drum-city"
    override val url: String = "https://thepocket.7drumcity.com"

    companion object {
        private const val BASE_URL = "https://thepocket.7drumcity.com"
        // Webflow CMS grid tab — the visible, active listing (not the hidden calendar tab)
        private const val EVENT_CONTAINER_SELECTOR = "div.uui-layout88_item-2.w-dyn-item"
        private const val EVENT_LINK_SELECTOR = "a.link-block-2"
        private const val EVENT_TITLE_SELECTOR = "h3.uui-heading-xxsmall-4:not(.w-condition-invisible)"
        private const val EVENT_SUPPORT_SELECTOR = "h4.supports-line:not(.w-condition-invisible)"
        private const val EVENT_MONTH_SELECTOR = "div.event-month-2"
        private const val EVENT_DAY_SELECTOR = "div.event-day-2"
        private const val EVENT_TIME_SELECTOR = "div.event-time-new-2"
        private const val EVENT_IMAGE_SELECTOR = "img.image-43"

        private const val VENUE_NAME = "The Pocket (7 Drum City)"
        private const val VENUE_ADDRESS = "2611 Bladensburg Rd NE, Washington, DC 20018"
        private val CONFIDENCE_SCORE = BigDecimal("0.65")

        private val TIME_FORMATTER = DateTimeFormatter.ofPattern("h:mm a")
        private val EASTERN = ZoneId.of("America/New_York")
        // Month abbreviation to number — sticker shows "Feb", "Mar", etc.
        private val MONTH_FORMATTER = DateTimeFormatter.ofPattern("MMM d yyyy")
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
                // Webflow conditional rendering: one h3 per event lacks w-condition-invisible
                val titleEl = element.select(EVENT_TITLE_SELECTOR)
                    .firstOrNull { it.text().isNotBlank() } ?: continue
                val title = titleEl.text().trim()

                val relativeUrl = element.selectFirst(EVENT_LINK_SELECTOR)?.attr("href") ?: ""
                val eventUrl = if (relativeUrl.isNotBlank()) "$BASE_URL$relativeUrl" else null

                val imageUrl = element.selectFirst(EVENT_IMAGE_SELECTOR)?.attr("src")
                    ?.takeIf { it.isNotBlank() }

                // Date from sticker divs
                val monthText = element.selectFirst(EVENT_MONTH_SELECTOR)?.text()?.trim() ?: ""
                val dayText = element.selectFirst(EVENT_DAY_SELECTOR)?.text()?.trim() ?: ""
                val timeText = element.selectFirst(EVENT_TIME_SELECTOR)?.text()?.trim() ?: ""

                val startInstant = parseEventDateTime(monthText, dayText, timeText, currentYear)

                // Support acts
                val supportText = element.select(EVENT_SUPPORT_SELECTOR)
                    .map { it.text().trim() }
                    .filter { it.isNotBlank() }
                    .joinToString(", ")

                val artistNames = if (supportText.isNotBlank()) {
                    supportText.split(",").map { it.trim() }.filter { it.isNotBlank() }
                } else emptyList()

                val dateKey = "$monthText $dayText"
                events.add(RawEventDto(
                    sourceType = SourceType.VENUE_SCRAPER,
                    sourceIdentifier = generateSourceIdentifier(title, dateKey),
                    sourceUrl = eventUrl,
                    title = title,
                    artistNames = artistNames,
                    venueName = VENUE_NAME,
                    venueAddress = VENUE_ADDRESS,
                    startTime = startInstant,
                    imageUrl = imageUrl,
                    confidenceScore = CONFIDENCE_SCORE
                ))
            } catch (e: Exception) {
                logger.warn("Failed to parse 7 Drum City event: ${e.message}")
            }
        }

        logger.debug("Extracted ${events.size} events from 7 Drum City")
        return events
    }

    private fun parseEventDateTime(month: String, day: String, timeText: String, year: Int): java.time.Instant? {
        if (month.isBlank() || day.isBlank()) return null
        return try {
            val localDate = LocalDate.parse("$month $day $year", MONTH_FORMATTER)
            val localTime = parseTime(timeText)
            localDate.atTime(localTime).atZone(EASTERN).toInstant()
        } catch (_: DateTimeParseException) {
            logger.debug("Could not parse 7 Drum City date: '$month $day $year'")
            null
        }
    }

    private fun parseTime(timeText: String): LocalTime {
        if (timeText.isBlank()) return LocalTime.of(20, 0) // default 8pm
        return try {
            LocalTime.parse(timeText.uppercase(), TIME_FORMATTER)
        } catch (_: DateTimeParseException) {
            LocalTime.of(20, 0)
        }
    }
}
