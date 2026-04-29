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
import java.time.LocalDate
import java.time.ZoneId

@Component
class TicketmasterConnector(
    private val webClientBuilder: WebClient.Builder,
    private val connectorConfig: ConnectorConfig,
    private val objectMapper: ObjectMapper
) : SourceConnector {

    private val logger = LoggerFactory.getLogger(TicketmasterConnector::class.java)
    private val config = connectorConfig.ticketmaster
    private val webClient = webClientBuilder.baseUrl(config.baseUrl).build()

    init {
        require(config.baseUrl.isNotBlank()) { "Ticketmaster base URL must not be blank" }
    }

    override val sourceId: String = "ticketmaster"
    override val sourceType: SourceType = SourceType.TICKETMASTER_API

    override suspend fun fetch(): Either<IngestionError, List<RawEventDto>> = try {
        val response = webClient
            .get()
            .uri { uri ->
                uri.path("/events.json")
                    .queryParam("apikey", config.apiKey)
                    .queryParam("classificationName", "music")
                    .queryParam("city", "Washington")
                    .queryParam("stateCode", "DC")
                    .queryParam("countryCode", "US")
                    .queryParam("size", config.pageSize)
                    .queryParam("sort", "date,asc")
                    .build()
            }
            .retrieve()
            .awaitBody<String>()

        parseResponse(response)
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
                IngestionError.ParseError("ticketmaster", e.message ?: "JSON parse failed").left()
            }
            else -> IngestionError.ConnectionError("ticketmaster", e.message ?: "Connection failed").left()
        }
    }

    override fun healthCheck(): Boolean = try {
        val response = webClient
            .head()
            .uri { uri ->
                uri.path("/events.json")
                    .queryParam("apikey", config.apiKey)
                    .queryParam("size", "1")
                    .build()
            }
            .retrieve()
            .toBodilessEntity()
            .block()

        response?.statusCode?.is2xxSuccessful ?: false
    } catch (e: Exception) {
        logger.warn("Health check failed for Ticketmaster: ${e.message}")
        false
    }

    private fun parseResponse(jsonString: String): Either<IngestionError, List<RawEventDto>> {
      return try {
        val rootNode = objectMapper.readTree(jsonString)
        val embeddedNode = rootNode.path("_embedded")
        val eventsNode = embeddedNode.path("events")

        // If _embedded is missing or events array is missing, return empty list (not an error)
        if (embeddedNode.isMissingNode || eventsNode.isMissingNode || !eventsNode.isArray) {
            return emptyList<RawEventDto>().right()
        }

        val events = mutableListOf<RawEventDto>()
        for (eventNode in eventsNode) {
            try {
                if (!isDcEvent(eventNode)) {
                    val name = eventNode.path("name").asText()
                    val venueNode = eventNode.path("_embedded").path("venues").firstOrNull()
                    val city = venueNode?.path("city")?.path("name")?.asText()
                    val state = venueNode?.path("state")?.path("stateCode")?.asText()
                    logger.debug("Skipping non-DC event '{}' at {}, {}", name, city, state)
                    continue
                }
                events.add(mapEventNode(eventNode))
            } catch (e: Exception) {
                logger.warn("Failed to map event: ${e.message}")
            }
        }
        events.right()
      } catch (e: Exception) {
        IngestionError.ParseError("ticketmaster", e.message ?: "Failed to parse response").left()
      }
    }

    private fun mapEventNode(node: JsonNode): RawEventDto {
        val id = node.path("id").asText()
        val name = node.path("name").asText()

        val startNode = node.path("dates").path("start")
        val startTime = startNode.path("dateTime").asText()
            .let { if (it.isNotEmpty()) Instant.parse(it) else null }
            ?: startNode.path("localDate").asText()
                .let { if (it.isNotEmpty()) LocalDate.parse(it).atStartOfDay(ZoneId.of("America/New_York")).toInstant() else null }

        val venue = node.path("_embedded").path("venues").firstOrNull()
        val venueName = venue?.path("name")?.asText()
        val venueAddress = buildVenueAddress(venue)

        val priceRange = node.path("priceRanges").firstOrNull()
        val minPrice = priceRange?.path("min")?.asText()?.let { it.toBigDecimalOrNull() }
        val maxPrice = priceRange?.path("max")?.asText()?.let { it.toBigDecimalOrNull() }

        val ticketUrl = node.path("url").asText().takeIf { it.isNotEmpty() }
        val imageUrl = node.path("images").firstOrNull()?.path("url")?.asText()
            ?.takeIf { it.isNotEmpty() }

        val attractions = node.path("_embedded").path("attractions")
        val artistNames = attractions
            .map { it.path("name").asText() }
            .filter { it.isNotBlank() }
        val genres = attractions
            .flatMap { attraction ->
                attraction.path("classifications")
                    .map { it.path("genre").path("name").asText() }
            }
            .filter { it.isNotBlank() && it != "Undefined" }
            .distinct()

        return RawEventDto(
            sourceType = SourceType.TICKETMASTER_API,
            sourceIdentifier = id,
            sourceUrl = ticketUrl,
            title = name,
            venueName = venueName,
            venueAddress = venueAddress,
            artistNames = artistNames,
            genres = genres,
            startTime = startTime,
            minPrice = minPrice,
            maxPrice = maxPrice,
            ticketUrl = ticketUrl,
            imageUrl = imageUrl,
            confidenceScore = BigDecimal("0.90")
        )
    }

    private fun isDcEvent(eventNode: JsonNode): Boolean {
        val venueNode = eventNode.path("_embedded").path("venues").firstOrNull() ?: return false
        val city = venueNode.path("city").path("name").asText()
        val stateCode = venueNode.path("state").path("stateCode").asText()
        return city.equals("Washington", ignoreCase = true) && stateCode.equals("DC", ignoreCase = true)
    }

    private fun buildVenueAddress(venueNode: JsonNode?): String? {
        if (venueNode == null) return null

        val parts = mutableListOf<String>()

        venueNode.path("address").path("line1").asText().takeIf { it.isNotEmpty() }?.let {
            parts.add(it)
        }
        venueNode.path("address").path("line2").asText().takeIf { it.isNotEmpty() }?.let {
            parts.add(it)
        }
        venueNode.path("city").asText().takeIf { it.isNotEmpty() }?.let {
            parts.add(it)
        }
        venueNode.path("state").path("stateCode").asText().takeIf { it.isNotEmpty() }?.let {
            parts.add(it)
        }
        venueNode.path("postalCode").asText().takeIf { it.isNotEmpty() }?.let {
            parts.add(it)
        }

        return if (parts.isEmpty()) null else parts.joinToString(", ")
    }
}
