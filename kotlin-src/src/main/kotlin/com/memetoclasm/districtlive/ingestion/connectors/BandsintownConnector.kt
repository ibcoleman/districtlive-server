package com.memetoclasm.districtlive.ingestion.connectors

import arrow.core.Either
import arrow.core.left
import arrow.core.right
import com.fasterxml.jackson.databind.JsonNode
import com.fasterxml.jackson.databind.ObjectMapper
import com.memetoclasm.districtlive.ingestion.ConnectorConfig
import com.memetoclasm.districtlive.ingestion.IngestionError
import com.memetoclasm.districtlive.ingestion.RawEventDto
import com.memetoclasm.districtlive.ingestion.SourceConnector
import com.memetoclasm.districtlive.event.SourceType
import org.slf4j.LoggerFactory
import org.springframework.stereotype.Component
import org.springframework.web.reactive.function.client.WebClient
import org.springframework.web.reactive.function.client.WebClientResponseException
import org.springframework.web.reactive.function.client.awaitBody
import java.math.BigDecimal
import java.time.Instant

@Component
class BandsintownConnector(
    private val webClientBuilder: WebClient.Builder,
    private val connectorConfig: ConnectorConfig,
    private val objectMapper: ObjectMapper
) : SourceConnector {

    private val logger = LoggerFactory.getLogger(BandsintownConnector::class.java)
    private val config = connectorConfig.bandsintown
    private val webClient = webClientBuilder.baseUrl(config.baseUrl).build()

    init {
        require(config.baseUrl.isNotBlank()) { "Bandsintown base URL must not be blank" }
        if (config.appId.isBlank()) {
            logger.warn("Bandsintown app_id is blank — connector will return ConfigurationError until BANDSINTOWN_APP_ID is set")
        }
    }

    override val sourceId: String = "bandsintown"
    override val sourceType: SourceType = SourceType.BANDSINTOWN_API

    override suspend fun fetch(): Either<IngestionError, List<RawEventDto>> {
      return try {
        if (config.appId.isBlank()) {
            return IngestionError.ConfigurationError("bandsintown", "No app_id configured — set BANDSINTOWN_APP_ID env var").left()
        }
        if (config.seedArtists.isEmpty()) {
            return IngestionError.ConfigurationError("bandsintown", "No seed artists configured").left()
        }

        val allEvents = mutableListOf<RawEventDto>()
        val errors = mutableListOf<IngestionError>()
        var successCount = 0

        for (artistName in config.seedArtists) {
            when (val result = fetchArtistEvents(artistName)) {
                is Either.Right -> {
                    successCount++
                    allEvents.addAll(result.value)
                }
                is Either.Left -> {
                    errors.add(result.value)
                    logger.warn("Failed to fetch events for artist '$artistName': ${result.value}")
                }
            }
        }

        // If every artist failed, propagate the error — don't mask total failure as success
        if (successCount == 0 && errors.isNotEmpty()) {
            return errors.first().left()
        }

        allEvents.right()
      } catch (e: Exception) {
        IngestionError.ConnectionError("bandsintown", e.message ?: "Connection failed").left()
      }
    }

    override fun healthCheck(): Boolean = try {
        val testArtist = config.seedArtists.firstOrNull() ?: "test"
        val response = webClient
            .head()
            .uri { uri ->
                uri.path("/artists/{artistName}/events")
                    .queryParam("app_id", config.appId)
                    .queryParam("date", "upcoming")
                    .build(testArtist)
            }
            .retrieve()
            .toBodilessEntity()
            .block()

        response?.statusCode?.is2xxSuccessful ?: false
    } catch (e: Exception) {
        logger.warn("Health check failed for Bandsintown: ${e.message}")
        false
    }

    private suspend fun fetchArtistEvents(artistName: String): Either<IngestionError, List<RawEventDto>> = try {
        val response = webClient
            .get()
            .uri { uri ->
                uri.path("/artists/{artistName}/events")
                    .queryParam("app_id", config.appId)
                    .queryParam("date", "upcoming")
                    .build(artistName)
            }
            .retrieve()
            .awaitBody<String>()

        parseResponse(response, artistName)
    } catch (e: WebClientResponseException) {
        when (e.statusCode.value()) {
            429 -> {
                val retryAfter = e.headers?.getFirst("Retry-After")?.toLongOrNull()
                IngestionError.RateLimited(retryAfter).left()
            }
            in 400..499 -> IngestionError.HttpError(e.statusCode.value(), e.message ?: "Client error").left()
            in 500..599 -> IngestionError.HttpError(e.statusCode.value(), e.message ?: "Server error").left()
            else -> IngestionError.HttpError(e.statusCode.value(), e.message ?: "HTTP error").left()
        }
    } catch (e: Exception) {
        when (e) {
            is com.fasterxml.jackson.core.JsonParseException,
            is com.fasterxml.jackson.databind.JsonMappingException -> {
                IngestionError.ParseError("bandsintown", e.message ?: "JSON parse failed").left()
            }
            else -> IngestionError.ConnectionError("bandsintown", e.message ?: "Connection failed").left()
        }
    }

    private fun parseResponse(jsonString: String, artistName: String): Either<IngestionError, List<RawEventDto>> = try {
        val rootNode = objectMapper.readTree(jsonString)

        if (!rootNode.isArray) {
            IngestionError.ParseError("bandsintown", "Expected array response but got object").left()
        } else {
            val events = mutableListOf<RawEventDto>()
            for (eventNode in rootNode) {
                try {
                    val event = mapEventNode(eventNode, artistName)
                    if (isInDcArea(eventNode)) {
                        events.add(event)
                    }
                } catch (e: Exception) {
                    logger.warn("Failed to map event for artist $artistName: ${e.message}")
                }
            }
            events.right()
        }
    } catch (e: Exception) {
        IngestionError.ParseError("bandsintown", e.message ?: "Failed to parse response").left()
    }

    private fun isInDcArea(eventNode: JsonNode): Boolean {
        val venue = eventNode.path("venue")
        val city = venue.path("city").asText().lowercase()
        val region = venue.path("region").asText().uppercase()

        return city.contains("washington") ||
                region == "DC" ||
                region.contains("DISTRICT OF COLUMBIA")
    }

    private fun mapEventNode(node: JsonNode, artistName: String): RawEventDto {
        val venue = node.path("venue")
        val venueName = venue.path("name").asText()

        val startTime = node.path("datetime").asText()
            .let { if (it.isNotEmpty()) Instant.parse(it) else null }

        val lineupArray = node.path("lineup")
        val artistNames = mutableListOf<String>()
        if (lineupArray.isArray) {
            for (item in lineupArray) {
                item.asText().takeIf { it.isNotEmpty() }?.let { artistNames.add(it) }
            }
        }

        val venueAddress = buildVenueAddress(venue)

        val ticketUrl = node.path("offers").firstOrNull()?.path("url")?.asText()
            ?.takeIf { it.isNotEmpty() }

        val sourceUrl = node.path("url").asText().takeIf { it.isNotEmpty() }

        val eventId = node.path("id").asText().takeIf { it.isNotEmpty() }
            ?: "${artistName}:${node.path("datetime").asText()}:${node.path("venue").path("name").asText()}".hashCode().toString()

        val title = if (artistNames.isNotEmpty()) {
            artistNames.joinToString(" / ")
        } else {
            artistName
        }

        return RawEventDto(
            sourceType = SourceType.BANDSINTOWN_API,
            sourceIdentifier = "$artistName:$eventId",
            sourceUrl = sourceUrl,
            title = title,
            venueName = venueName,
            venueAddress = venueAddress,
            artistNames = artistNames,
            startTime = startTime,
            ticketUrl = ticketUrl,
            confidenceScore = BigDecimal("0.85")
        )
    }

    private fun buildVenueAddress(venueNode: JsonNode?): String? {
        if (venueNode == null) return null

        val parts = mutableListOf<String>()

        venueNode.path("city").asText().takeIf { it.isNotEmpty() }?.let {
            parts.add(it)
        }
        venueNode.path("region").asText().takeIf { it.isNotEmpty() }?.let {
            parts.add(it)
        }
        venueNode.path("country").asText().takeIf { it.isNotEmpty() }?.let {
            parts.add(it)
        }

        return if (parts.isEmpty()) null else parts.joinToString(", ")
    }
}
