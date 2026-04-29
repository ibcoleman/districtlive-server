package com.memetoclasm.districtlive.ingestion.enrichment

/**
 * Port interface implemented by each external enrichment adapter.
 * Accepts a cleaned artist name; returns an EnrichmentResult or null if no
 * confident match was found. Null is a normal result (not an error).
 */
interface ArtistEnricher {
    val source: EnrichmentSource
    suspend fun enrich(cleanedName: String): EnrichmentResult?
}

/**
 * Identifies which external system produced an EnrichmentResult.
 */
enum class EnrichmentSource {
    MUSIC_BRAINZ,
    SPOTIFY,
    OLLAMA
}

/**
 * Data returned by an ArtistEnricher adapter.
 * Fields not populated by the adapter are null / empty.
 *
 * @param canonicalName Better-spelled name from the external source, or null if no improvement found.
 * @param externalId    Stable external identifier (MB UUID or Spotify artist ID).
 * @param tags          Genre/tag list from the source (mb_tags OR spotify_genres — never mixed).
 * @param imageUrl      Artist image URL from the source.
 * @param confidence    Match confidence: Jaro-Winkler score for MusicBrainz, 1.0 for Spotify.
 */
data class EnrichmentResult(
    val canonicalName: String?,
    val externalId: String?,
    val tags: List<String>,
    val imageUrl: String?,
    val confidence: Double
)
