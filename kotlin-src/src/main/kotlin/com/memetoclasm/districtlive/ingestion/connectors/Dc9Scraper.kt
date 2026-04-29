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
import java.time.ZonedDateTime
import java.time.format.DateTimeFormatter
import java.time.format.DateTimeParseException

@Component
class Dc9Scraper(objectMapper: ObjectMapper) : AbstractHtmlScraper(objectMapper) {

    private val logger = LoggerFactory.getLogger(Dc9Scraper::class.java)

    override val sourceId: String = "dc9"
    override val url: String = "https://dc9.club/"

    companion object {
        private const val LISTING_SELECTOR = "div.listing.plotCard[data-listing-id]"
        private const val TITLE_SELECTOR = "div.listing__title h3"
        private const val TITLE_LINK_SELECTOR = "a.listing__titleLink"
        private const val DATE_SELECTOR = "div.listingDateTime span"
        private const val DOORS_SELECTOR = "p.listing-doors"
        private const val TICKET_LINK_SELECTOR = "a.listingsBuyTicketsButton"
        private const val IMAGE_SELECTOR = "picture source[media='(min-width: 1024px)']"

        private const val VENUE_NAME = "DC9"
        private const val VENUE_ADDRESS = "1940 9th St NW, Washington, DC 20001"
        private val CONFIDENCE_SCORE = BigDecimal("0.70")
        private val DC_ZONE = ZoneId.of("America/New_York")

        // Date format: "Fri, Apr 24" or "Wed, Mar 18"
        private val DATE_FORMATTER = DateTimeFormatter.ofPattern("EEE, MMM d yyyy")

        // Time patterns: "7pm", "11pm", "7:30pm", "10:30pm"
        private val TIME_REGEX = Regex("""(\d{1,2}(?::\d{2})?)(am|pm)""", RegexOption.IGNORE_CASE)
    }

    override fun extractEvents(document: Document): List<RawEventDto> {
        val listings = document.select(LISTING_SELECTOR)

        if (listings.isEmpty()) {
            logger.warn("No event listings found using selector: $LISTING_SELECTOR")
            return emptyList()
        }

        val events = mutableListOf<RawEventDto>()
        val currentYear = LocalDate.now().year
        val seenIds = mutableSetOf<String>()

        for (element in listings) {
            try {
                val listingId = element.attr("data-listing-id")
                if (listingId in seenIds) continue
                seenIds.add(listingId)

                val title = element.selectFirst(TITLE_SELECTOR)?.text()?.trim() ?: continue
                if (title.isBlank()) continue

                val detailUrl = element.selectFirst(TITLE_LINK_SELECTOR)?.attr("href")
                    ?.takeIf { it.isNotBlank() }

                val dateText = element.selectFirst(DATE_SELECTOR)?.text()?.trim() ?: ""
                val doorsText = element.selectFirst(DOORS_SELECTOR)?.text()?.trim() ?: ""

                val eventDate = parseEventDate(dateText, currentYear)
                val doorsTime = parseTimeFromDoorsText(doorsText, "Doors")
                val showTime = parseTimeFromDoorsText(doorsText, "Show")

                val startTime = resolveDateTime(eventDate, showTime ?: doorsTime)
                val doorsInstant = if (doorsTime != null && doorsTime != showTime) {
                    resolveDateTime(eventDate, doorsTime)
                } else null

                val ticketUrl = element.selectFirst(TICKET_LINK_SELECTOR)?.attr("href")
                    ?.takeIf { it.isNotBlank() }

                val imageUrl = element.selectFirst(IMAGE_SELECTOR)?.attr("srcset")
                    ?.takeIf { it.isNotBlank() }

                events.add(
                    RawEventDto(
                        sourceType = SourceType.VENUE_SCRAPER,
                        sourceIdentifier = generateSourceIdentifier(title, dateText),
                        sourceUrl = detailUrl ?: ticketUrl,
                        title = title,
                        venueName = VENUE_NAME,
                        venueAddress = VENUE_ADDRESS,
                        startTime = startTime,
                        doorsTime = doorsInstant,
                        ticketUrl = ticketUrl,
                        imageUrl = imageUrl,
                        confidenceScore = CONFIDENCE_SCORE
                    )
                )
            } catch (e: Exception) {
                logger.warn("Failed to parse DC9 event: ${e.message}")
            }
        }

        logger.debug("Extracted ${events.size} events from DC9")
        return events
    }

    private fun parseEventDate(dateText: String, currentYear: Int): LocalDate? {
        if (dateText.isBlank()) return null
        val withYear = "$dateText $currentYear"
        return try {
            val parsed = LocalDate.parse(withYear, DATE_FORMATTER)
            // If the date is more than 2 months in the past, assume next year
            if (parsed.isBefore(LocalDate.now().minusMonths(2))) {
                parsed.plusYears(1)
            } else {
                parsed
            }
        } catch (_: DateTimeParseException) {
            logger.debug("Could not parse DC9 date: '$dateText'")
            null
        }
    }

    private fun parseTimeFromDoorsText(doorsText: String, label: String): LocalTime? {
        // Format: "Doors: 7pm • Show: 8pm" or "Doors: 10:30pm • Show: 10:30pm"
        val labelIndex = doorsText.indexOf(label, ignoreCase = true)
        if (labelIndex < 0) return null

        val afterLabel = doorsText.substring(labelIndex + label.length)
        val match = TIME_REGEX.find(afterLabel) ?: return null

        return try {
            val timeStr = match.groupValues[1]
            val amPm = match.groupValues[2].uppercase()
            val parts = timeStr.split(":")
            var hour = parts[0].toInt()
            val minute = if (parts.size > 1) parts[1].toInt() else 0

            if (amPm == "PM" && hour != 12) hour += 12
            if (amPm == "AM" && hour == 12) hour = 0

            LocalTime.of(hour, minute)
        } catch (e: Exception) {
            logger.debug("Could not parse time from '$doorsText' for label '$label'")
            null
        }
    }

    private fun resolveDateTime(date: LocalDate?, time: LocalTime?): java.time.Instant? {
        if (date == null) return null
        val localTime = time ?: LocalTime.MIDNIGHT
        return ZonedDateTime.of(date, localTime, DC_ZONE).toInstant()
    }
}
