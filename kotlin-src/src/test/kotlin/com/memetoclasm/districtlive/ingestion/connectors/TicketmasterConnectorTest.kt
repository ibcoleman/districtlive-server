package com.memetoclasm.districtlive.ingestion.connectors

import com.fasterxml.jackson.databind.ObjectMapper
import com.memetoclasm.districtlive.ingestion.ConnectorConfig
import com.memetoclasm.districtlive.ingestion.IngestionError
import com.memetoclasm.districtlive.ingestion.RawEventDto
import com.memetoclasm.districtlive.event.SourceType
import okhttp3.mockwebserver.MockResponse
import okhttp3.mockwebserver.MockWebServer
import org.junit.jupiter.api.AfterEach
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import org.springframework.web.reactive.function.client.WebClient
import java.math.BigDecimal
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertTrue
import kotlinx.coroutines.test.runTest

/** A minimal DC venue block reused across test fixtures. */
private const val DC_VENUE = """
  {
    "name": "9:30 Club",
    "address": { "line1": "815 V St NW" },
    "city": { "name": "Washington" },
    "state": { "stateCode": "DC" },
    "country": { "countryCode": "US" }
  }
"""

class TicketmasterConnectorTest {

    private lateinit var mockWebServer: MockWebServer
    private lateinit var connector: TicketmasterConnector

    @BeforeEach
    fun setUp() {
        mockWebServer = MockWebServer()
        mockWebServer.start()

        val config = ConnectorConfig(
            ticketmaster = ConnectorConfig.TicketmasterConfig(
                apiKey = "test-key",
                baseUrl = mockWebServer.url("/").toString().removeSuffix("/"),
                pageSize = 200
            )
        )

        connector = TicketmasterConnector(WebClient.builder(), config, ObjectMapper())
    }

    @AfterEach
    fun tearDown() {
        mockWebServer.shutdown()
    }

    // ─── basic fetch behaviour ──────────────────────────────────────

    @Test
    fun `fetch with valid API response returns Right with list of RawEventDto`() = runTest {
        val response = """
            {
              "_embedded": {
                "events": [{
                  "id": "Z698xZXzRV_Hv",
                  "name": "The Beatles Experience",
                  "dates": { "start": { "dateTime": "2026-03-15T19:00:00Z" } },
                  "_embedded": { "venues": [$DC_VENUE] },
                  "priceRanges": [{ "min": 50.0, "max": 150.0 }],
                  "images": [{ "url": "https://example.com/image.jpg" }],
                  "url": "https://www.ticketmaster.com/event"
                }]
              }
            }
        """.trimIndent()

        mockWebServer.enqueue(MockResponse().setBody(response).setResponseCode(200))

        val result = connector.fetch()

        assertTrue(result.isRight(), "Expected Right, got Left: ${result.mapLeft { it }}")
        result.onRight { events ->
            assertEquals(1, events.size)
            val event = events[0]
            assertEquals("The Beatles Experience", event.title)
            assertEquals("9:30 Club", event.venueName)
            assertEquals("Z698xZXzRV_Hv", event.sourceIdentifier)
            assertEquals(BigDecimal("50.0"), event.minPrice)
            assertEquals(BigDecimal("150.0"), event.maxPrice)
            assertEquals("https://www.ticketmaster.com/event", event.ticketUrl)
            assertEquals(SourceType.TICKETMASTER_API, event.sourceType)
            assertEquals(BigDecimal("0.90"), event.confidenceScore)
        }
    }

    @Test
    fun `fetch with zero events returns Right with empty list`() = runTest {
        mockWebServer.enqueue(MockResponse().setBody("""{"page":{"totalElements":0}}""").setResponseCode(200))

        val result = connector.fetch()

        assertTrue(result.isRight())
        result.onRight { events -> assertEquals(0, events.size) }
    }

    @Test
    fun `fetch maps startTime correctly`() = runTest {
        val response = """
            {
              "_embedded": {
                "events": [{
                  "id": "event-123",
                  "name": "Concert",
                  "dates": { "start": { "dateTime": "2026-04-10T20:00:00Z" } },
                  "_embedded": { "venues": [$DC_VENUE] },
                  "priceRanges": [{ "min": 25.0, "max": 75.0 }],
                  "images": [{ "url": "https://example.com/img.jpg" }],
                  "url": "https://ticket.url"
                }]
              }
            }
        """.trimIndent()

        mockWebServer.enqueue(MockResponse().setBody(response).setResponseCode(200))

        val result = connector.fetch()

        assertTrue(result.isRight())
        result.onRight { events ->
            assertNotNull(events[0].startTime)
            assertEquals("2026-04-10T20:00:00Z", events[0].startTime.toString())
        }
    }

    @Test
    fun `fetch with multiple DC events returns all events`() = runTest {
        val response = """
            {
              "_embedded": {
                "events": [
                  {
                    "id": "event-1", "name": "Event One",
                    "dates": { "start": { "dateTime": "2026-03-01T18:00:00Z" } },
                    "_embedded": { "venues": [$DC_VENUE] },
                    "priceRanges": [{ "min": 20.0, "max": 60.0 }],
                    "images": [{ "url": "https://example.com/1.jpg" }],
                    "url": "https://ticket.url/1"
                  },
                  {
                    "id": "event-2", "name": "Event Two",
                    "dates": { "start": { "dateTime": "2026-03-02T19:00:00Z" } },
                    "_embedded": { "venues": [$DC_VENUE] },
                    "priceRanges": [{ "min": 30.0, "max": 80.0 }],
                    "images": [{ "url": "https://example.com/2.jpg" }],
                    "url": "https://ticket.url/2"
                  }
                ]
              }
            }
        """.trimIndent()

        mockWebServer.enqueue(MockResponse().setBody(response).setResponseCode(200))

        val result = connector.fetch()

        assertTrue(result.isRight())
        result.onRight { events ->
            assertEquals(2, events.size)
            assertEquals("Event One", events[0].title)
            assertEquals("Event Two", events[1].title)
        }
    }

    @Test
    fun `fetch skips non-DC events`() = runTest {
        val response = """
            {
              "_embedded": {
                "events": [
                  {
                    "id": "dc-event", "name": "DC Show",
                    "dates": { "start": { "dateTime": "2026-03-01T18:00:00Z" } },
                    "_embedded": { "venues": [$DC_VENUE] },
                    "url": "https://ticket.url/dc"
                  },
                  {
                    "id": "ny-event", "name": "NY Show",
                    "dates": { "start": { "dateTime": "2026-03-01T20:00:00Z" } },
                    "_embedded": { "venues": [{
                      "name": "Madison Square Garden",
                      "city": { "name": "New York" },
                      "state": { "stateCode": "NY" }
                    }] },
                    "url": "https://ticket.url/ny"
                  }
                ]
              }
            }
        """.trimIndent()

        mockWebServer.enqueue(MockResponse().setBody(response).setResponseCode(200))

        val result = connector.fetch()

        assertTrue(result.isRight())
        result.onRight { events ->
            assertEquals(1, events.size)
            assertEquals("dc-event", events[0].sourceIdentifier)
        }
    }

    @Test
    fun `fetch with missing optional fields does not crash`() = runTest {
        val response = """
            {
              "_embedded": {
                "events": [{
                  "id": "event-minimal",
                  "name": "Minimal Event",
                  "dates": { "start": { "dateTime": "2026-05-15T20:00:00Z" } },
                  "_embedded": { "venues": [$DC_VENUE] },
                  "priceRanges": [],
                  "images": [],
                  "url": ""
                }]
              }
            }
        """.trimIndent()

        mockWebServer.enqueue(MockResponse().setBody(response).setResponseCode(200))

        val result = connector.fetch()

        assertTrue(result.isRight(), "Expected Right")
        result.onRight { events ->
            assertEquals(1, events.size)
            assertEquals("Minimal Event", events[0].title)
            assertEquals("event-minimal", events[0].sourceIdentifier)
        }
    }

    // ─── attractions → artistNames + genres ────────────────────────

    @Test
    fun `fetch maps attractions to artistNames`() = runTest {
        val response = """
            {
              "_embedded": {
                "events": [{
                  "id": "ev-1", "name": "Hanumankind",
                  "dates": { "start": { "dateTime": "2026-06-01T20:00:00Z" } },
                  "_embedded": {
                    "venues": [$DC_VENUE],
                    "attractions": [
                      { "name": "Hanumankind" }
                    ]
                  }
                }]
              }
            }
        """.trimIndent()

        mockWebServer.enqueue(MockResponse().setBody(response).setResponseCode(200))

        val result = connector.fetch()

        assertTrue(result.isRight())
        result.onRight { events ->
            assertEquals(listOf("Hanumankind"), events[0].artistNames)
        }
    }

    @Test
    fun `fetch maps multiple attractions to artistNames`() = runTest {
        val response = """
            {
              "_embedded": {
                "events": [{
                  "id": "ev-2", "name": "Peaches w/ Model/Actriz",
                  "dates": { "start": { "dateTime": "2026-06-02T20:00:00Z" } },
                  "_embedded": {
                    "venues": [$DC_VENUE],
                    "attractions": [
                      { "name": "Peaches" },
                      { "name": "Model/Actriz" }
                    ]
                  }
                }]
              }
            }
        """.trimIndent()

        mockWebServer.enqueue(MockResponse().setBody(response).setResponseCode(200))

        val result = connector.fetch()

        assertTrue(result.isRight())
        result.onRight { events ->
            assertEquals(listOf("Peaches", "Model/Actriz"), events[0].artistNames)
        }
    }

    @Test
    fun `fetch maps attraction classifications to genres, excluding Undefined`() = runTest {
        val response = """
            {
              "_embedded": {
                "events": [{
                  "id": "ev-3", "name": "Rock Show",
                  "dates": { "start": { "dateTime": "2026-06-03T20:00:00Z" } },
                  "_embedded": {
                    "venues": [$DC_VENUE],
                    "attractions": [{
                      "name": "The Artist",
                      "classifications": [
                        { "primary": true, "genre": { "name": "Rock" }, "subGenre": { "name": "Pop" } },
                        { "primary": false, "genre": { "name": "Undefined" } }
                      ]
                    }]
                  }
                }]
              }
            }
        """.trimIndent()

        mockWebServer.enqueue(MockResponse().setBody(response).setResponseCode(200))

        val result = connector.fetch()

        assertTrue(result.isRight())
        result.onRight { events ->
            assertEquals(listOf("Rock"), events[0].genres)
        }
    }

    @Test
    fun `fetch with no attractions returns empty artistNames`() = runTest {
        val response = """
            {
              "_embedded": {
                "events": [{
                  "id": "ev-4", "name": "Mystery Show",
                  "dates": { "start": { "dateTime": "2026-06-04T20:00:00Z" } },
                  "_embedded": { "venues": [$DC_VENUE] }
                }]
              }
            }
        """.trimIndent()

        mockWebServer.enqueue(MockResponse().setBody(response).setResponseCode(200))

        val result = connector.fetch()

        assertTrue(result.isRight())
        result.onRight { events ->
            assertEquals(emptyList(), events[0].artistNames)
            assertEquals(emptyList(), events[0].genres)
        }
    }

    // ─── HTTP error handling ────────────────────────────────────────

    @Test
    fun `fetch with 429 response returns Left with RateLimited`() = runTest {
        mockWebServer.enqueue(MockResponse().setResponseCode(429).addHeader("Retry-After", "60"))

        val result = connector.fetch()

        assertTrue(result.isLeft())
        result.onLeft { error ->
            assertTrue(error is IngestionError.RateLimited)
            assertEquals(60L, (error as IngestionError.RateLimited).retryAfterSeconds)
        }
    }

    @Test
    fun `fetch with 4xx response returns Left with HttpError`() = runTest {
        mockWebServer.enqueue(MockResponse().setResponseCode(401))

        val result = connector.fetch()

        assertTrue(result.isLeft())
        result.onLeft { error ->
            assertTrue(error is IngestionError.HttpError)
            assertEquals(401, (error as IngestionError.HttpError).statusCode)
        }
    }

    @Test
    fun `fetch with 5xx response returns Left with HttpError`() = runTest {
        mockWebServer.enqueue(MockResponse().setResponseCode(500))

        val result = connector.fetch()

        assertTrue(result.isLeft())
        result.onLeft { error ->
            assertTrue(error is IngestionError.HttpError)
            assertEquals(500, (error as IngestionError.HttpError).statusCode)
        }
    }

    @Test
    fun `fetch with malformed JSON returns Left with ParseError`() = runTest {
        mockWebServer.enqueue(MockResponse().setBody("{ invalid json").setResponseCode(200))

        val result = connector.fetch()

        assertTrue(result.isLeft())
        result.onLeft { error -> assertTrue(error is IngestionError.ParseError) }
    }

    // ─── query parameters ──────────────────────────────────────────

    @Test
    fun `fetch sends correct query parameters to API`() = runTest {
        mockWebServer.enqueue(MockResponse().setBody("""{"_embedded":{"events":[]}}""").setResponseCode(200))

        connector.fetch()

        val request = mockWebServer.takeRequest()
        assertTrue(request.path?.contains("apikey=test-key") == true, "API key not in query params")
        assertTrue(request.path?.contains("classificationName=music") == true, "classificationName not in query params")
        assertTrue(request.path?.contains("city=Washington") == true, "city not in query params")
        assertTrue(request.path?.contains("stateCode=DC") == true, "stateCode not in query params")
        assertTrue(request.path?.contains("size=200") == true, "size not in query params")
        assertTrue(request.path?.contains("sort=date") == true, "sort not in query params")
    }

    // ─── health check ──────────────────────────────────────────────

    @Test
    fun `healthCheck returns true on successful head request`() {
        mockWebServer.enqueue(MockResponse().setResponseCode(200))
        assertTrue(connector.healthCheck())
    }

    @Test
    fun `healthCheck returns false on failed request`() {
        mockWebServer.enqueue(MockResponse().setResponseCode(500))
        assertTrue(!connector.healthCheck())
    }
}
