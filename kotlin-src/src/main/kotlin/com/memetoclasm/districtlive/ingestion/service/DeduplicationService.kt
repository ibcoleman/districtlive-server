package com.memetoclasm.districtlive.ingestion.service

import com.memetoclasm.districtlive.event.SourceType
import java.math.BigDecimal
import java.time.Instant
import java.time.ZoneId
import org.apache.commons.text.similarity.JaroWinklerSimilarity
import org.springframework.stereotype.Service

data class DeduplicatedEvent(
    val canonical: NormalizedEvent,
    val sources: List<SourceAttribution>
)

data class SourceAttribution(
    val sourceType: SourceType,
    val sourceIdentifier: String,
    val sourceUrl: String?,
    val confidenceScore: BigDecimal
)

@Service
class DeduplicationService {

    private val jws = JaroWinklerSimilarity()
    private val nyTimeZone = ZoneId.of("America/New_York")

    companion object {
        private const val TITLE_SIMILARITY_THRESHOLD = 0.85
    }

    /**
     * Deduplicates a list of NormalizedEvents, grouping duplicate events and merging
     * their source attributions while selecting the best field values from highest confidence sources.
     */
    fun deduplicate(events: List<NormalizedEvent>): List<DeduplicatedEvent> {
        if (events.isEmpty()) {
            return emptyList()
        }

        val processed = mutableSetOf<NormalizedEvent>()
        val result = mutableListOf<DeduplicatedEvent>()

        for (event in events) {
            if (event in processed) {
                continue
            }

            val duplicates = findDuplicates(event, events.filter { it !in processed })
            duplicates.forEach { processed.add(it) }
            processed.add(event)

            val merged = mergeEvents(duplicates + event)
            result.add(merged)
        }

        return result
    }

    /**
     * Finds all events from the candidates list that are duplicates of the given event.
     * Uses primary match (same venue + same date + title Jaro-Winkler > 0.85)
     * and secondary match (same artist(s) + same date).
     */
    fun findDuplicates(event: NormalizedEvent, candidates: List<NormalizedEvent>): List<NormalizedEvent> {
        return candidates.filter { candidate ->
            candidate != event && (
                isPrimaryMatch(event, candidate) ||
                isSecondaryMatch(event, candidate)
            )
        }
    }

    /**
     * Primary matching strategy: same venue + same date + title Jaro-Winkler similarity > 0.85
     * "Same date" means same calendar date in America/New_York timezone.
     */
    fun isPrimaryMatch(a: NormalizedEvent, b: NormalizedEvent): Boolean {
        // Check if same venue
        if (!sameVenue(a.venueName, b.venueName)) {
            return false
        }

        // Check if same calendar date in NY timezone
        if (!sameDateInNyTimezone(a.startTime, b.startTime)) {
            return false
        }

        // Check if title similarity > 0.85
        val similarity = jws.apply(a.title.lowercase(), b.title.lowercase())
        return similarity > TITLE_SIMILARITY_THRESHOLD
    }

    /**
     * Secondary matching strategy: same artist(s) + same date
     * Catches events with venue name variations.
     */
    fun isSecondaryMatch(a: NormalizedEvent, b: NormalizedEvent): Boolean {
        // Check if same calendar date in NY timezone
        if (!sameDateInNyTimezone(a.startTime, b.startTime)) {
            return false
        }

        // Check if they share at least one artist
        val sharedArtists = a.artistNames.intersect(b.artistNames.toSet())
        return sharedArtists.isNotEmpty()
    }

    /**
     * Merges multiple events into a single DeduplicatedEvent.
     * For each field, picks the value from the source with the highest confidence score.
     * Retains all source attributions.
     */
    fun mergeEvents(events: List<NormalizedEvent>): DeduplicatedEvent {
        require(events.isNotEmpty()) { "Cannot merge empty list of events" }

        // Sort by confidence score descending to pick highest confidence field values
        val sortedByConfidence = events.sortedByDescending { it.confidenceScore }
        val highest = sortedByConfidence.first()

        // Build source attributions
        val sources = events.map { event ->
            SourceAttribution(
                sourceType = event.sourceType,
                sourceIdentifier = event.sourceIdentifier,
                sourceUrl = event.sourceUrl,
                confidenceScore = event.confidenceScore
            )
        }

        // Merge using confidence-based field resolution:
        // For each field, pick the value from the highest-confidence source
        val canonical = NormalizedEvent(
            title = selectBestValue(events, { it.title }, { it.title.isNotEmpty() }),
            slug = highest.slug,
            description = selectBestValue(
                events,
                { it.description },
                { it.description != null && it.description.isNotEmpty() }
            ),
            startTime = selectBestValue(
                events,
                { it.startTime },
                { true }
            ),
            endTime = selectBestValue(
                events,
                { it.endTime },
                { it.endTime != null }
            ),
            doorsTime = selectBestValue(
                events,
                { it.doorsTime },
                { it.doorsTime != null }
            ),
            venueName = selectBestValue(
                events,
                { it.venueName },
                { it.venueName != null && it.venueName.isNotEmpty() }
            ),
            venueAddress = selectBestValue(
                events,
                { it.venueAddress },
                { it.venueAddress != null && it.venueAddress.isNotEmpty() }
            ),
            artistNames = mergeArtists(events),
            minPrice = selectBestValue(
                events,
                { it.minPrice },
                { it.minPrice != null }
            ),
            maxPrice = selectBestValue(
                events,
                { it.maxPrice },
                { it.maxPrice != null }
            ),
            priceTier = selectBestValue(
                events,
                { it.priceTier },
                { it.priceTier != null }
            ),
            ticketUrl = selectBestValue(
                events,
                { it.ticketUrl },
                { it.ticketUrl != null && it.ticketUrl.isNotEmpty() }
            ),
            imageUrl = selectBestValue(
                events,
                { it.imageUrl },
                { it.imageUrl != null && it.imageUrl.isNotEmpty() }
            ),
            ageRestriction = selectBestValue(
                events,
                { it.ageRestriction },
                { true }
            ),
            sourceType = highest.sourceType,
            sourceIdentifier = highest.sourceIdentifier,
            sourceUrl = highest.sourceUrl,
            confidenceScore = highest.confidenceScore
        )

        return DeduplicatedEvent(
            canonical = canonical,
            sources = sources
        )
    }

    /**
     * Selects the best value from events based on confidence and a validity predicate.
     */
    private fun <T> selectBestValue(
        events: List<NormalizedEvent>,
        extractor: (NormalizedEvent) -> T,
        isValid: (NormalizedEvent) -> Boolean
    ): T {
        val validEvents = events.filter(isValid)
        val sorted = validEvents.sortedByDescending { it.confidenceScore }
        return extractor(sorted.firstOrNull() ?: events.first())
    }

    /**
     * Merges artist lists from multiple events, deduplicating while preserving order.
     */
    private fun mergeArtists(events: List<NormalizedEvent>): List<String> {
        val seen = mutableSetOf<String>()
        val result = mutableListOf<String>()

        for (event in events) {
            for (artist in event.artistNames) {
                if (!seen.contains(artist)) {
                    seen.add(artist)
                    result.add(artist)
                }
            }
        }

        return result
    }

    /**
     * Checks if two venue names refer to the same venue.
     * Currently uses exact case-insensitive comparison.
     * Future: could implement fuzzy matching.
     */
    private fun sameVenue(venueName1: String?, venueName2: String?): Boolean {
        if (venueName1 == null || venueName2 == null) {
            return venueName1 == venueName2
        }
        return venueName1.trim().lowercase() == venueName2.trim().lowercase()
    }

    /**
     * Checks if two instants represent the same calendar date in America/New_York timezone.
     */
    private fun sameDateInNyTimezone(instant1: Instant, instant2: Instant): Boolean {
        val date1 = instant1.atZone(nyTimeZone).toLocalDate()
        val date2 = instant2.atZone(nyTimeZone).toLocalDate()
        return date1 == date2
    }
}
