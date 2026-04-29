package com.memetoclasm.districtlive.ingestion.enrichment.adapters

import com.fasterxml.jackson.databind.ObjectMapper
import com.memetoclasm.districtlive.ingestion.enrichment.ArtistEnricher
import com.memetoclasm.districtlive.ingestion.enrichment.EnrichmentConfig
import com.memetoclasm.districtlive.ingestion.enrichment.EnrichmentResult
import com.memetoclasm.districtlive.ingestion.enrichment.EnrichmentSource
import kotlinx.coroutines.delay
import kotlinx.coroutines.reactive.awaitSingle
import org.apache.commons.text.similarity.JaroWinklerSimilarity
import org.slf4j.LoggerFactory
import org.springframework.stereotype.Component
import org.springframework.web.reactive.function.client.WebClient
import org.springframework.web.reactive.function.client.awaitBody
import java.time.Instant
import java.util.Base64

@Component
class SpotifyEnricher(
    webClientBuilder: WebClient.Builder,
    private val config: EnrichmentConfig,
    private val objectMapper: ObjectMapper
) : ArtistEnricher {

    override val source: EnrichmentSource = EnrichmentSource.SPOTIFY

    private val logger = LoggerFactory.getLogger(SpotifyEnricher::class.java)

    @Volatile internal var cachedToken: String? = null
    @Volatile internal var tokenExpiresAt: Instant = Instant.EPOCH

    private val tokenClient = webClientBuilder
        .baseUrl(config.spotify.tokenBaseUrl)
        .build()

    private val searchClient = webClientBuilder
        .baseUrl(config.spotify.searchBaseUrl)
        .build()

    override suspend fun enrich(cleanedName: String): EnrichmentResult? {
        if (!config.spotify.enabled) return null
        return runCatching {
            val token = getOrRefreshToken() ?: return@runCatching null
            searchArtist(cleanedName, token)
        }.onFailure { ex ->
            logger.warn("Spotify enrichment failed for '{}': {}", cleanedName, ex.message)
        }.getOrNull()
    }

    private suspend fun getOrRefreshToken(): String? {
        val current = cachedToken
        if (current != null && Instant.now().isBefore(tokenExpiresAt)) return current
        return fetchNewToken()
    }

    private suspend fun fetchNewToken(): String? {
        val credentials = Base64.getEncoder().encodeToString(
            "${config.spotify.clientId}:${config.spotify.clientSecret}".toByteArray()
        )
        return runCatching {
            val responseJson = tokenClient.post()
                .uri("/api/token")
                .header("Authorization", "Basic $credentials")
                .header("Content-Type", "application/x-www-form-urlencoded")
                .bodyValue("grant_type=client_credentials")
                .retrieve()
                .awaitBody<String>()
            val root = objectMapper.readTree(responseJson)
            val accessToken = root.path("access_token").asText()
            val expiresIn = root.path("expires_in").asLong(3600L)
            cachedToken = accessToken
            tokenExpiresAt = Instant.now().plusSeconds(expiresIn - 60L)
            accessToken
        }.onFailure { ex ->
            logger.warn("Spotify token fetch failed: {}", ex.message)
        }.getOrNull()
    }

    private suspend fun searchArtist(cleanedName: String, token: String): EnrichmentResult? {
        for (attempt in 0..config.spotify.maxRetries) {
            val outcome = searchClient.get()
                .uri { uri ->
                    uri.path("/v1/search")
                        .queryParam("q", cleanedName)
                        .queryParam("type", "artist")
                        .queryParam("limit", "5")
                        .build()
                }
                .header("Authorization", "Bearer $token")
                .exchangeToMono<SearchOutcome> { response ->
                    when {
                        response.statusCode().is2xxSuccessful ->
                            response.bodyToMono(String::class.java)
                                .map { SearchOutcome.Found(it) }

                        response.statusCode().value() == 429 -> {
                            val retryAfterSec = response.headers().header("Retry-After")
                                .firstOrNull()?.toLongOrNull() ?: 1L
                            response.releaseBody().thenReturn(SearchOutcome.RateLimited(retryAfterSec))
                        }

                        else -> {
                            val code = response.statusCode().value()
                            response.releaseBody().thenReturn(SearchOutcome.Failed(code))
                        }
                    }
                }
                .awaitSingle()

            when (outcome) {
                is SearchOutcome.Found -> return parseSearchResponse(cleanedName, outcome.body)
                is SearchOutcome.RateLimited -> {
                    logger.debug(
                        "Spotify 429 for '{}', attempt {}/{}, waiting {}s",
                        cleanedName, attempt + 1, config.spotify.maxRetries, outcome.retryAfterSec
                    )
                    delay(outcome.retryAfterSec * 1000L)
                }
                is SearchOutcome.Failed -> {
                    logger.warn("Spotify search returned {} for '{}'", outcome.statusCode, cleanedName)
                    return null
                }
            }
        }
        logger.warn("Spotify search exhausted {} retries for '{}'", config.spotify.maxRetries, cleanedName)
        return null
    }

    private fun parseSearchResponse(cleanedName: String, json: String): EnrichmentResult? {
        val root = objectMapper.readTree(json)
        val items = root.path("artists").path("items")

        if (!items.isArray || items.size() == 0) {
            logger.debug("No Spotify results for '{}'", cleanedName)
            return null
        }

        val artist = items[0]
        val returnedName = artist.path("name").asText()
        val confidence = JaroWinklerSimilarity().apply(cleanedName.lowercase(), returnedName.lowercase())
        if (confidence < config.spotify.confidenceThreshold) {
            logger.debug(
                "Spotify result '{}' confidence {} below threshold {} for '{}'",
                returnedName, confidence, config.spotify.confidenceThreshold, cleanedName
            )
            return null
        }

        val spotifyId = artist.path("id").asText().takeIf { it.isNotBlank() }
        val genres = artist.path("genres")
            .filter { it.isTextual }
            .map { it.asText() }
        val imageUrl = artist.path("images")
            .takeIf { it.isArray && it.size() > 0 }
            ?.get(0)?.path("url")?.asText()?.takeIf { it.isNotBlank() }

        return EnrichmentResult(
            canonicalName = null,
            externalId = spotifyId,
            tags = genres,
            imageUrl = imageUrl,
            confidence = confidence
        )
    }

    private sealed class SearchOutcome {
        data class Found(val body: String) : SearchOutcome()
        data class RateLimited(val retryAfterSec: Long) : SearchOutcome()
        data class Failed(val statusCode: Int) : SearchOutcome()
    }
}
