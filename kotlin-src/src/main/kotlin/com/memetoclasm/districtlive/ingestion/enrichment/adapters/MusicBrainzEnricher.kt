package com.memetoclasm.districtlive.ingestion.enrichment.adapters

import com.fasterxml.jackson.databind.ObjectMapper
import com.memetoclasm.districtlive.ingestion.enrichment.ArtistEnricher
import com.memetoclasm.districtlive.ingestion.enrichment.EnrichmentConfig
import com.memetoclasm.districtlive.ingestion.enrichment.EnrichmentResult
import com.memetoclasm.districtlive.ingestion.enrichment.EnrichmentSource
import org.apache.commons.text.similarity.JaroWinklerSimilarity
import org.slf4j.LoggerFactory
import org.springframework.stereotype.Component
import org.springframework.web.reactive.function.client.WebClient
import org.springframework.web.reactive.function.client.awaitBody

@Component
class MusicBrainzEnricher(
    webClientBuilder: WebClient.Builder,
    private val config: EnrichmentConfig,
    private val objectMapper: ObjectMapper
) : ArtistEnricher {

    override val source: EnrichmentSource = EnrichmentSource.MUSIC_BRAINZ

    private val logger = LoggerFactory.getLogger(MusicBrainzEnricher::class.java)
    private val jws = JaroWinklerSimilarity()
    private val webClient = webClientBuilder
        .baseUrl(config.musicbrainz.baseUrl)
        .defaultHeader("User-Agent", config.musicbrainz.userAgent)
        .build()

    override suspend fun enrich(cleanedName: String): EnrichmentResult? = runCatching {
        val responseJson = webClient
            .get()
            .uri { uri ->
                uri.path("/ws/2/artist/")
                    .queryParam("query", cleanedName)
                    .queryParam("fmt", "json")
                    .build()
            }
            .retrieve()
            .awaitBody<String>()

        parseResponse(cleanedName, responseJson)
    }.onFailure { ex ->
        logger.warn("MusicBrainz enrichment failed for '{}': {}", cleanedName, ex.message)
    }.getOrNull()

    private fun parseResponse(cleanedName: String, json: String): EnrichmentResult? {
        val root = objectMapper.readTree(json)
        val artists = root.path("artists")

        if (artists.isEmpty || !artists.isArray || artists.size() == 0) {
            return null
        }

        val topArtist = artists[0]
        val score = topArtist.path("score").asText().toIntOrNull() ?: return null

        if (score < MB_SCORE_THRESHOLD) {
            logger.debug("MusicBrainz score {} < {} for '{}', skipping", score, MB_SCORE_THRESHOLD, cleanedName)
            return null
        }

        val mbName = topArtist.path("name").asText()
        val confidence = jws.apply(cleanedName.lowercase(), mbName.lowercase())

        if (confidence < config.musicbrainz.confidenceThreshold) {
            logger.debug(
                "Jaro-Winkler {} < {} for '{}' vs '{}', skipping",
                confidence, config.musicbrainz.confidenceThreshold, cleanedName, mbName
            )
            return null
        }

        val mbId = topArtist.path("id").asText().takeIf { it.isNotBlank() }
        val tags = topArtist.path("tags")
            .filter { it.has("name") }
            .map { it.path("name").asText() }

        return EnrichmentResult(
            canonicalName = mbName,
            externalId = mbId,
            tags = tags,
            imageUrl = null,
            confidence = confidence
        )
    }

    companion object {
        private const val MB_SCORE_THRESHOLD = 80
    }
}
