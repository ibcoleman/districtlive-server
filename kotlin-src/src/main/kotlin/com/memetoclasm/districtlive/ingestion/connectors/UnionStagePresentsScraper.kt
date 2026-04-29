package com.memetoclasm.districtlive.ingestion.connectors

import arrow.core.Either
import arrow.core.raise.either
import com.fasterxml.jackson.databind.ObjectMapper
import com.memetoclasm.districtlive.event.SourceType
import com.memetoclasm.districtlive.ingestion.ConnectorConfig
import com.memetoclasm.districtlive.ingestion.IngestionError
import com.memetoclasm.districtlive.ingestion.RawEventDto
import org.jsoup.nodes.Document
import org.jsoup.nodes.Element
import org.slf4j.LoggerFactory
import org.springframework.stereotype.Component
import java.math.BigDecimal
import java.time.Instant
import java.time.LocalDate
import java.time.LocalTime
import java.time.Month
import java.time.ZonedDateTime
import java.time.format.TextStyle
import java.util.Locale

@Component
class UnionStagePresentsScraper(
    private val connectorConfig: ConnectorConfig,
    objectMapper: ObjectMapper
) : AbstractHtmlScraper(objectMapper) {

    private val logger = LoggerFactory.getLogger(UnionStagePresentsScraper::class.java)

    override val sourceId: String = "union-stage-presents"
    override val url: String = "https://unionstagepresents.com"

    companion object {
        private val VENUE_INFO = mapOf(
            "union-stage" to ("Union Stage" to "740 Water St SW, Washington, DC 20024"),
            "jammin-java" to ("Jammin Java" to "227 Maple Ave E, Vienna, VA 22180"),
            "pearl-street-warehouse" to ("Pearl Street Warehouse" to "33 Pearl St SW, Washington, DC 20024"),
            "howard-theatre" to ("The Howard Theatre" to "620 T St NW, Washington, DC 20001"),
            "miracle-theatre" to ("Miracle Theatre" to "535 8th St SE, Washington, DC 20003"),
            "capital-turnaround" to ("Capital Turnaround" to "70 N St SE, Washington, DC 20003"),
            "nationals-park" to ("Nationals Park" to "1500 S Capitol St SE, Washington, DC 20003")
        )

        private val MONTH_ABBREV_MAP: Map<String, Month> = Month.entries.associateBy {
            it.getDisplayName(TextStyle.SHORT, Locale.US)
        }
    }

    override suspend fun fetch(): Either<IngestionError, List<RawEventDto>> = either {
        val config = connectorConfig.unionStagePresents
        val results = mutableListOf<RawEventDto>()
        val failedVenues = mutableListOf<String>()

        for (venue in config.venues) {
            try {
                val listingUrl = url + venue.path
                val listingDoc = fetchListingDocument(listingUrl)
                if (listingDoc == null) {
                    logger.warn("Failed to fetch listing for venue slug '{}' at URL '{}'", venue.slug, listingUrl)
                    failedVenues.add(venue.slug)
                    continue
                }

                val venueEvents = extractEventsForVenue(listingDoc, venue.slug)
                results.addAll(venueEvents)
                logger.debug("Fetched {} events from Union Stage Presents venue '{}'", venueEvents.size, venue.slug)
            } catch (e: Exception) {
                logger.warn("Failed to process Union Stage Presents venue '{}': {}", venue.slug, e.message)
                failedVenues.add(venue.slug)
            }
        }

        if (failedVenues.size == config.venues.size && results.isEmpty()) {
            raise(
                IngestionError.ConnectionError(
                    sourceId,
                    "All ${failedVenues.size} Union Stage Presents venue fetches failed"
                )
            )
        }

        results
    }

    protected open fun fetchListingDocument(listingUrl: String): Document? {
        return try {
            org.jsoup.Jsoup.connect(listingUrl)
                .timeout(30_000)
                .userAgent("Mozilla/5.0 (compatible; DistrictLive/1.0)")
                .get()
        } catch (e: Exception) {
            logger.warn("Failed to fetch listing page: $listingUrl", e)
            null
        }
    }

    internal fun extractEventsForVenue(document: Document, venueSlug: String): List<RawEventDto> {
        val events = mutableListOf<RawEventDto>()
        val (venueName, venueAddress) = VENUE_INFO[venueSlug] ?: return emptyList()

        val items = document.select(".show-item")

        for (item in items) {
            try {
                val event = parseShowItem(item, venueName, venueAddress)
                if (event != null) {
                    events.add(event)
                }
            } catch (e: Exception) {
                logger.warn("Failed to parse Union Stage Presents event from venue '{}': {}", venueSlug, e.message)
            }
        }

        return events
    }

    private fun parseShowItem(item: Element, venueName: String, venueAddress: String): RawEventDto? {
        // Each .show-item has two a.show-card-link elements: one visible, one with
        // w-condition-invisible. Scope all extraction to the first (visible) link
        // to avoid doubled text from Jsoup concatenating both copies.
        val visibleCard = item.select("a.show-card-link").first() ?: return null

        val title = visibleCard.select("h3.show-card-header").text().trim()
        if (title.isBlank()) return null

        val detailLink = visibleCard.absUrl("href").ifBlank { null }
            ?.takeIf { it != "#" && it.isNotBlank() }

        // Date from .date-tag children (scoped to visible card)
        val eventDate = parseDateFromCard(visibleCard)

        // Doors and show times from .show-info divs (scoped to visible card)
        val (doorsTime, showTime) = parseTimesFromCard(visibleCard, eventDate)

        // Support act from .uui-text-size-medium.dark-caps (scoped to visible card)
        val supportText = visibleCard.select(".uui-text-size-medium.dark-caps").text().trim()

        // Support acts only — NormalizationService handles title-based artist extraction
        val artistNames = buildArtistNames(supportText)

        // Image from .show-image-wrapper img (scoped to visible card)
        val imageUrl = visibleCard.select(".show-image-wrapper img").attr("abs:src").ifBlank { null }

        // Defaults from listing
        var startTime = showTime
        var endTime: Instant? = null
        var finalDoorsTime = doorsTime
        var minPrice: BigDecimal? = null
        var description: String? = null
        var finalImageUrl = imageUrl
        var ticketUrl = detailLink

        // Enrich from detail page if available
        if (detailLink != null) {
            val detailDoc = fetchDetailDocument(detailLink)
            if (detailDoc != null) {
                val enriched = extractFromDetailPage(detailDoc)
                if (enriched != null) {
                    startTime = enriched.startTime ?: startTime
                    endTime = enriched.endTime
                    finalDoorsTime = enriched.doorsTime ?: finalDoorsTime
                    minPrice = enriched.minPrice
                    description = enriched.description
                    finalImageUrl = enriched.imageUrl ?: finalImageUrl
                    ticketUrl = enriched.ticketUrl ?: ticketUrl
                }
            }
        }

        // Fall back to default 8 PM if no time at all
        if (startTime == null && eventDate != null) {
            startTime = ZonedDateTime.of(
                eventDate, LocalTime.of(20, 0), DC_ZONE
            ).toInstant()
        }

        return RawEventDto(
            sourceType = SourceType.VENUE_SCRAPER,
            sourceIdentifier = generateSourceIdentifier(title, eventDate?.toString() ?: ""),
            sourceUrl = detailLink,
            title = title,
            description = description,
            venueName = venueName,
            venueAddress = venueAddress,
            artistNames = artistNames,
            startTime = startTime,
            endTime = endTime,
            doorsTime = finalDoorsTime,
            minPrice = minPrice,
            ticketUrl = ticketUrl,
            imageUrl = finalImageUrl,
            confidenceScore = CONFIDENCE_SCORE
        )
    }

    private fun parseDateFromCard(item: Element): LocalDate? {
        val monthText = item.select(".event-month").first()?.text()?.trim() ?: return null
        val dayText = item.select(".event-day").first()?.text()?.trim() ?: return null

        val month = MONTH_ABBREV_MAP[monthText] ?: return null
        val day = dayText.toIntOrNull() ?: return null

        // Assume current year; if month is in the past, use next year
        val now = LocalDate.now(DC_ZONE)
        val candidate = LocalDate.of(now.year, month, day)
        return if (candidate.isBefore(now.minusDays(30))) {
            candidate.plusYears(1)
        } else {
            candidate
        }
    }

    private fun parseTimesFromCard(item: Element, eventDate: LocalDate?): Pair<Instant?, Instant?> {
        if (eventDate == null) return null to null

        val showInfoDivs = item.select(".show-info")
        // The second .show-info div contains doors/show times
        val timeDiv = showInfoDivs.getOrNull(1) ?: return null to null

        val textParts = timeDiv.select(".base-text-size-caps").map { it.text().trim() }

        var doorsTime: Instant? = null
        var showTime: Instant? = null

        // Pattern: "DOORS", "7:00 pm", "|", "Show", "8:00 pm"
        for (i in textParts.indices) {
            if (textParts[i].equals("DOORS", ignoreCase = true) && i + 1 < textParts.size) {
                doorsTime = parseTimeWithDate(textParts[i + 1], eventDate)
            }
            if (textParts[i].equals("Show", ignoreCase = true) && i + 1 < textParts.size) {
                showTime = parseTimeWithDate(textParts[i + 1], eventDate)
            }
        }

        return doorsTime to showTime
    }

    private fun buildArtistNames(supportText: String): List<String> {
        // Don't include the event title here — NormalizationService.extractArtists()
        // already parses the title for artist names. We only pass explicit support acts
        // from the subtitle to avoid duplicating title-extracted artists.
        if (supportText.isBlank()) return emptyList()

        return supportText.split(",").map { it.trim() }.filter { it.isNotBlank() }
    }

    private data class DetailPageData(
        val startTime: Instant?,
        val endTime: Instant?,
        val doorsTime: Instant?,
        val minPrice: BigDecimal?,
        val description: String?,
        val imageUrl: String?,
        val ticketUrl: String?
    )

    private fun extractFromDetailPage(detailDoc: Document): DetailPageData? {
        val eventData = detailDoc.selectFirst("#event-data") ?: return null

        val startTime = eventData.attr("data-start").ifBlank { null }?.let { parseIsoInstant(it) }
        val endTime = eventData.attr("data-end").ifBlank { null }?.let { parseIsoInstant(it) }
        val doorsTime = eventData.attr("data-doors").ifBlank { null }?.let { parseIsoInstant(it) }
        val priceText = eventData.attr("data-price").ifBlank { null }
        val minPrice = priceText?.let { parsePriceFromText(it) }
        val imageUrl = eventData.attr("data-image").ifBlank { null }
        val ticketUrl = eventData.attr("data-ticket-url").ifBlank { null }

        // Description from rich text area
        val description = detailDoc.select(".about-copy.w-richtext").text().trim().ifBlank { null }

        return DetailPageData(
            startTime = startTime,
            endTime = endTime,
            doorsTime = doorsTime,
            minPrice = minPrice,
            description = description,
            imageUrl = imageUrl,
            ticketUrl = ticketUrl
        )
    }

    private fun parseIsoInstant(dateStr: String): Instant? = try {
        Instant.parse(dateStr)
    } catch (e: Exception) {
        logger.warn("Failed to parse ISO instant: {}", dateStr)
        null
    }

    override fun extractEvents(document: Document): List<RawEventDto> {
        throw UnsupportedOperationException("extractEvents() is not used in multi-venue scraper; use fetch() instead")
    }
}
