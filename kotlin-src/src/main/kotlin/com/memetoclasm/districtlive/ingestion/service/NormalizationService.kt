package com.memetoclasm.districtlive.ingestion.service

import arrow.core.Either
import arrow.core.raise.either
import com.memetoclasm.districtlive.event.AgeRestriction
import com.memetoclasm.districtlive.event.PriceTier
import com.memetoclasm.districtlive.event.SlugUtils.slugify
import com.memetoclasm.districtlive.event.SourceType
import com.memetoclasm.districtlive.ingestion.IngestionError
import com.memetoclasm.districtlive.ingestion.IngestionResult
import com.memetoclasm.districtlive.ingestion.RawEventDto
import org.slf4j.LoggerFactory
import java.math.BigDecimal
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import org.apache.commons.text.similarity.JaroWinklerSimilarity
import org.springframework.stereotype.Service

data class VenueMatchCandidate(
    val slug: String,
    val name: String,
    val address: String?
)

data class VenueMatch(
    val matched: Boolean,
    val venueSlug: String?
)

data class NormalizedEvent(
    val title: String,
    val slug: String,
    val description: String?,
    val startTime: Instant,
    val endTime: Instant?,
    val doorsTime: Instant?,
    val venueName: String?,
    val venueAddress: String? = null,  // threaded from RawEventDto
    val artistNames: List<String>,
    val minPrice: BigDecimal?,
    val maxPrice: BigDecimal?,
    val priceTier: PriceTier?,
    val ticketUrl: String?,
    val imageUrl: String?,
    val ageRestriction: AgeRestriction,
    val sourceType: SourceType,
    val sourceIdentifier: String,
    val sourceUrl: String?,
    val confidenceScore: BigDecimal
)

@Service
class NormalizationService {

    private val logger = LoggerFactory.getLogger(NormalizationService::class.java)
    private val jws = JaroWinklerSimilarity()
    private val dateFormatter = DateTimeFormatter.ofPattern("yyyy-MM-dd")

    /**
     * Orchestrates the full normalization pipeline.
     * Skips individual events that fail normalization (e.g., missing startTime)
     * rather than aborting the entire batch.
     */
    fun normalize(rawEvents: List<RawEventDto>): IngestionResult<List<NormalizedEvent>> {
        val results = rawEvents.map { raw -> normalizeEvent(raw) }
        val normalized = mutableListOf<NormalizedEvent>()
        var skipped = 0

        for ((index, result) in results.withIndex()) {
            when (result) {
                is Either.Right -> normalized.add(result.value)
                is Either.Left -> {
                    skipped++
                    logger.warn("Skipping event {}: {}", rawEvents[index].sourceIdentifier, result.value)
                }
            }
        }

        if (skipped > 0) {
            logger.info("Normalization complete: {} normalized, {} skipped", normalized.size, skipped)
        }

        return Either.Right(normalized)
    }

    /**
     * Strips common heading prefixes from event titles emitted by venue scrapers.
     * Returns the original title unchanged if stripping would produce a blank result.
     *
     * Prefixes stripped (case-insensitive, longest match first):
     *   "An Evening with ", "A Evening with ", "Evening with ", "Evening: ",
     *   "with ", "am "
     *
     * Consistent titles across sources (e.g. Ticketmaster vs venue scraper) ensure
     * slug-based cross-source deduplication works at the upsert layer.
     */
    internal fun cleanEventTitle(title: String): String {
        val prefixPatterns = listOf(
            Regex("""^an?\s+evening\s+with\s+""", RegexOption.IGNORE_CASE),
            Regex("""^evening\s+with\s+""", RegexOption.IGNORE_CASE),
            Regex("""^evening:\s+""", RegexOption.IGNORE_CASE),
            Regex("""^with\s+""", RegexOption.IGNORE_CASE),
            Regex("""^am\s+""", RegexOption.IGNORE_CASE),
        )

        for (pattern in prefixPatterns) {
            if (pattern.containsMatchIn(title)) {
                val stripped = pattern.replace(title, "").trimStart()
                if (stripped.isNotBlank()) {
                    return stripped
                }
            }
        }

        return title
    }

    /**
     * Normalize a single raw event.
     */
    private fun normalizeEvent(raw: RawEventDto): IngestionResult<NormalizedEvent> = either {
        val startTime = raw.startTime ?: raise(
            IngestionError.ParseError("event", "Event missing required startTime")
        )

        val title = cleanEventTitle(raw.title.trim()).ifEmpty {
            raise(IngestionError.ParseError("event", "Event missing required title"))
        }

        val slug = generateSlug(title, raw.venueName ?: "unknown", startTime.toLocalDate())
        val ageRestriction = parseAgeRestriction(raw.ageRestriction)
        val priceTier = normalizePriceTier(raw.minPrice, raw.maxPrice)
        val artists = extractArtists(title, raw.artistNames)
        val normalizedEnd = normalizeTimezone(raw.endTime)
        val normalizedDoors = normalizeTimezone(raw.doorsTime)

        NormalizedEvent(
            title = title,
            slug = slug,
            description = raw.description,
            startTime = startTime,
            endTime = normalizedEnd,
            doorsTime = normalizedDoors,
            venueName = raw.venueName?.let { normalizeVenueName(it) },
            venueAddress = raw.venueAddress,  // pass through from RawEventDto
            artistNames = artists,
            minPrice = raw.minPrice,
            maxPrice = raw.maxPrice,
            priceTier = priceTier,
            ticketUrl = raw.ticketUrl,
            imageUrl = raw.imageUrl,
            ageRestriction = ageRestriction,
            sourceType = raw.sourceType,
            sourceIdentifier = raw.sourceIdentifier,
            sourceUrl = raw.sourceUrl,
            confidenceScore = raw.confidenceScore
        )
    }

    /**
     * Fuzzy-matches raw venue name against provided known venues.
     * Returns a match result (matched venue slug or "unknown").
     * The knownVenues list is passed IN by the caller (kept pure - no I/O).
     */
    fun matchVenue(
        venueName: String?,
        venueAddress: String?,
        knownVenues: List<VenueMatchCandidate>
    ): VenueMatch {
        if (venueName == null || venueName.isBlank() || knownVenues.isEmpty()) {
            return VenueMatch(matched = false, venueSlug = null)
        }

        val normalizedInput = venueName.trim().lowercase()

        // Try exact match first
        knownVenues.forEach { candidate ->
            if (candidate.name.trim().lowercase() == normalizedInput) {
                return VenueMatch(matched = true, venueSlug = candidate.slug)
            }
        }

        // Try fuzzy match using Jaro-Winkler similarity
        val threshold = 0.85
        var bestMatch: VenueMatchCandidate? = null
        var bestScore = 0.0

        knownVenues.forEach { candidate ->
            val score = jws.apply(
                normalizedInput,
                candidate.name.trim().lowercase()
            )
            if (score > bestScore && score >= threshold) {
                bestScore = score
                bestMatch = candidate
            }
        }

        return bestMatch?.let { VenueMatch(matched = true, venueSlug = it.slug) }
            ?: VenueMatch(matched = false, venueSlug = null)
    }

    /**
     * Extracts and deduplicates artists from title strings.
     *
     * Recognised multi-act separators (title-level split):
     *   " w/ ", " with ", " / ", " & ", " - " (spaced dash), ","
     *
     * Tour/subtitle suffixes are stripped before splitting so that
     * "Artist: The Big Tour" does not produce "The Big Tour" as an artist.
     *
     * A standalone event title with no separator (e.g. "2026 Fun-A-Day Showcase")
     * produces no artist records; the caller should supply explicit artistNames.
     */
    fun extractArtists(title: String, artistNames: List<String>): List<String> {
        val separatorRegex = Regex("""\s+(?:w/|with|/|&|-)\s+|,\s*""")

        val strippedTitle = stripTourSuffix(title)
        val titleArtists = if (strippedTitle.isNotBlank() && separatorRegex.containsMatchIn(strippedTitle)) {
            strippedTitle.split(separatorRegex).map { it.trim() }.filter { it.isNotEmpty() }
        } else {
            emptyList()
        }

        // Combine with explicit artist names and deduplicate while preserving order
        val combined = titleArtists + artistNames
        val seen = mutableSetOf<String>()
        val result = mutableListOf<String>()

        for (artist in combined) {
            val cleaned = cleanArtistName(artist.trim())
            if (cleaned.isNotEmpty() && !seen.contains(cleaned)) {
                seen.add(cleaned)
                result.add(cleaned)
            }
        }

        return result
    }

    /**
     * Strips common tour/subtitle suffixes that follow a colon in event titles.
     * Patterns like "Artist: The Big Tour" → "Artist".
     *
     * Does NOT strip when the suffix itself contains a multi-act separator
     * (e.g. "ACE HOOD: The Born Rebel Tour with DUKE DEUCE & DIZZY WRIGHT") —
     * those suffixes embed artist names and must be parsed, not discarded.
     */
    internal fun stripTourSuffix(title: String): String {
        val colonIdx = title.indexOf(':')
        if (colonIdx <= 0) return title

        val beforeColon = title.substring(0, colonIdx).trim()
        val afterColon = title.substring(colonIdx + 1).trim()

        // If the suffix contains multi-act separators, it likely has artist names — keep it
        val separatorInSuffix = Regex("""\s+(?:w/|with|/|&|-)\s+|,\s*""")
        if (separatorInSuffix.containsMatchIn(afterColon)) return title

        val tourKeywords = Regex("""(?i)\b(tour|live|experience|show|showcase|presents|performing)\b""")
        return if (tourKeywords.containsMatchIn(afterColon)) beforeColon else title
    }

    /**
     * Strips common conjunction prefixes and trailing punctuation artifacts from raw artist names.
     * Falls back to the original string if cleanup produces an empty result.
     *
     * Prefixes stripped (case-insensitive): "and ", "& ", "with ", "feat. ", "ft. ",
     *   "special guest ", "special guests "
     * Trailing characters stripped: ',', ';', '.'
     */
    internal fun cleanArtistName(raw: String): String {
        if (raw.isBlank()) return raw

        // Reject standalone placeholder values that are not artist names
        val standalone = raw.trim().lowercase()
        if (standalone in setOf("special guest", "special guests", "tba", "to be announced")) {
            return ""
        }

        // Strip "SOLD OUT: " prefix emitted by some venue scrapers when an event sells out
        var cleaned = raw
        if (cleaned.startsWith("SOLD OUT:", ignoreCase = true)) {
            cleaned = cleaned.substring("SOLD OUT:".length).trimStart()
        }

        // "and " matches case-sensitively (lowercase only) to avoid mangling band names
        // like "And Justice For All". Real conjunctions in event copy are always lowercase.
        // Other prefixes use ignoreCase because "With Someone" / "Feat. Guest" appear
        // title-cased in event listings.
        val caseInsensitivePrefixes = listOf(
            "& ", "with ", "feat. ", "ft. ",
            "special guests ", "special guest "
        )
        if (cleaned.startsWith("and ")) {
            cleaned = cleaned.substring(4).trimStart()
        } else {
            for (prefix in caseInsensitivePrefixes) {
                if (cleaned.startsWith(prefix, ignoreCase = true)) {
                    cleaned = cleaned.substring(prefix.length).trimStart()
                    break
                }
            }
        }

        cleaned = cleaned.trimEnd { it == ',' || it == ';' || it == '.' }.trimEnd()

        return if (cleaned.isBlank()) raw else cleaned
    }

    /**
     * Basic genre tagging - for Phase 5, passes through existing genres.
     * Genre enrichment can be added later.
     */
    fun tagGenre(artistName: String, existingGenres: List<String>): List<String> {
        return existingGenres
    }

    /**
     * Maps price range to PriceTier enum.
     * FREE if 0, UNDER_15, PRICE_15_TO_30, OVER_30
     */
    fun normalizePriceTier(minPrice: BigDecimal?, maxPrice: BigDecimal?): PriceTier? {
        if (minPrice == null && maxPrice == null) {
            return null
        }

        // Use max price if available, otherwise min price
        val price = maxPrice ?: minPrice ?: return null

        return when {
            price.compareTo(BigDecimal.ZERO) == 0 -> PriceTier.FREE
            price < BigDecimal("15") -> PriceTier.UNDER_15
            price <= BigDecimal("30") -> PriceTier.PRICE_15_TO_30
            else -> PriceTier.OVER_30
        }
    }

    /**
     * Ensures all timestamps are in UTC.
     * Raw events may come in various timezones.
     */
    fun normalizeTimezone(instant: Instant?): Instant? {
        // Instants are already in UTC by definition
        return instant
    }

    /**
     * Creates URL-friendly slug from title + venue + date.
     */
    fun generateSlug(title: String, venueName: String, date: LocalDate): String {
        val dateStr = dateFormatter.format(date)
        val combined = "$title $venueName $dateStr"

        // Convert to lowercase, replace special characters with hyphens
        return slugify(combined)
    }

    /**
     * Normalizes venue names to canonical forms, stripping known political renamings
     * and sub-venue qualifiers so that API variants resolve to existing venue records.
     *
     * Examples:
     *   "Trump Kennedy Center - Concert Hall"  → "Kennedy Center"
     *   "Trump Kennedy Center - Opera House"   → "Kennedy Center"
     */
    internal fun normalizeVenueName(venueName: String): String {
        var normalized = venueName.trim()

        // Strip "Trump " prefix (Ticketmaster reflects the political renaming of Kennedy Center)
        normalized = normalized.replaceFirst(Regex("^Trump ", RegexOption.IGNORE_CASE), "").trimStart()

        // Strip sub-venue qualifier (e.g. " - Concert Hall", " - Opera House")
        val subVenueSeparator = normalized.indexOf(" - ")
        if (subVenueSeparator > 0) {
            normalized = normalized.substring(0, subVenueSeparator).trim()
        }

        return normalized
    }

    /**
     * Parse age restriction from string or default to ALL_AGES.
     */
    private fun parseAgeRestriction(restriction: String?): AgeRestriction {
        if (restriction == null || restriction.isBlank()) {
            return AgeRestriction.ALL_AGES
        }

        return when {
            restriction.contains("18", ignoreCase = true) -> AgeRestriction.EIGHTEEN_PLUS
            restriction.contains("21", ignoreCase = true) -> AgeRestriction.TWENTY_ONE_PLUS
            else -> AgeRestriction.ALL_AGES
        }
    }
}

/**
 * Extension function to convert Instant to LocalDate in America/New_York timezone
 */
private fun Instant.toLocalDate(): LocalDate {
    return this.atZone(ZoneId.of("America/New_York")).toLocalDate()
}
