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

class BandsintownConnectorTest {

    private lateinit var mockWebServer: MockWebServer
    private lateinit var connector: BandsintownConnector

    @BeforeEach
    fun setUp() {
        mockWebServer = MockWebServer()
        mockWebServer.start()

        val config = ConnectorConfig(
            bandsintown = ConnectorConfig.BandsintownConfig(
                appId = "test-app-id",
                baseUrl = mockWebServer.url("/").toString().removeSuffix("/"),
                seedArtists = listOf("Fugazi", "Bad Brains")
            )
        )

        val webClientBuilder = WebClient.builder()
        val objectMapper = ObjectMapper()
        connector = BandsintownConnector(webClientBuilder, config, objectMapper)
    }

    @AfterEach
    fun tearDown() {
        mockWebServer.shutdown()
    }

    @Test
    fun `fetch with valid API response returns Right with list of DC-area events`() = runTest {
        // Fugazi events
        val fugaziResponse = """
            [
              {
                "id": "event-1",
                "datetime": "2026-03-15T19:00:00Z",
                "venue": {
                  "name": "The Anthem",
                  "city": "Washington",
                  "region": "DC",
                  "country": "United States",
                  "latitude": 38.8,
                  "longitude": -77.05
                },
                "lineup": ["Fugazi"],
                "offers": [
                  {
                    "type": "Tickets",
                    "url": "https://bandsintown.com/tickets"
                  }
                ],
                "url": "https://bandsintown.com/event"
              }
            ]
        """.trimIndent()

        // Bad Brains events
        val badBrainsResponse = """
            [
              {
                "id": "event-2",
                "datetime": "2026-03-20T20:00:00Z",
                "venue": {
                  "name": "The 930 Club",
                  "city": "Washington",
                  "region": "DC",
                  "country": "United States"
                },
                "lineup": ["Bad Brains"],
                "offers": [
                  {
                    "type": "Tickets",
                    "url": "https://bandsintown.com/tickets"
                  }
                ],
                "url": "https://bandsintown.com/event"
              }
            ]
        """.trimIndent()

        mockWebServer.enqueue(MockResponse().setBody(fugaziResponse).setResponseCode(200))
        mockWebServer.enqueue(MockResponse().setBody(badBrainsResponse).setResponseCode(200))

        val result = connector.fetch()

        assertTrue(result.isRight(), "Expected Right, got Left: ${result.mapLeft { it }}")
        result.onRight { events ->
            assertEquals(2, events.size)
            val event1 = events[0]
            assertEquals("Fugazi", event1.title)
            assertEquals("The Anthem", event1.venueName)
            assertEquals("Washington, DC, United States", event1.venueAddress)
            assertEquals(SourceType.BANDSINTOWN_API, event1.sourceType)
            assertEquals(BigDecimal("0.85"), event1.confidenceScore)
        }
    }

    @Test
    fun `fetch with zero events returns Right with empty list`() = runTest {
        val emptyResponse = "[]"

        mockWebServer.enqueue(MockResponse().setBody(emptyResponse).setResponseCode(200))
        mockWebServer.enqueue(MockResponse().setBody(emptyResponse).setResponseCode(200))

        val result = connector.fetch()

        assertTrue(result.isRight(), "Expected Right")
        result.onRight { events ->
            assertEquals(0, events.size)
        }
    }

    @Test
    fun `fetch with 429 response for one artist logs failure and continues with other artists`() = runTest {
        // First artist (Fugazi) gets 429
        mockWebServer.enqueue(
            MockResponse()
                .setResponseCode(429)
                .addHeader("Retry-After", "60")
        )
        // Second artist (Bad Brains) succeeds with empty list
        mockWebServer.enqueue(MockResponse().setBody("[]").setResponseCode(200))

        val result = connector.fetch()

        // Individual artist failures are logged but fetch() still returns Right with collected events
        assertTrue(result.isRight(), "Expected Right despite first artist's 429")
        result.onRight { events ->
            assertEquals(0, events.size, "Should have empty list when all artists fail or return no results")
        }
    }

    @Test
    fun `fetch with all artists failing returns Left with first error`() = runTest {
        // Both artists get 429
        mockWebServer.enqueue(
            MockResponse()
                .setResponseCode(429)
                .addHeader("Retry-After", "60")
        )
        mockWebServer.enqueue(
            MockResponse()
                .setResponseCode(429)
                .addHeader("Retry-After", "60")
        )

        val result = connector.fetch()

        // When ALL artists fail, fetch() propagates the error instead of masking it
        assertTrue(result.isLeft(), "Expected Left when all artists fail")
        result.onLeft { error ->
            assertTrue(error is IngestionError.RateLimited)
        }
    }

    @Test
    fun `fetch with 4xx response logs failure and continues with next artist`() = runTest {
        // First artist (Fugazi) gets 401
        mockWebServer.enqueue(MockResponse().setResponseCode(401))
        // Second artist (Bad Brains) succeeds with empty list
        mockWebServer.enqueue(MockResponse().setBody("[]").setResponseCode(200))

        val result = connector.fetch()

        // Individual failures are logged but fetch() returns Right with collected events
        assertTrue(result.isRight(), "Expected Right despite first artist's 401")
        result.onRight { events ->
            assertEquals(0, events.size)
        }
    }

    @Test
    fun `fetch with 5xx response logs failure and continues with next artist`() = runTest {
        // First artist (Fugazi) gets 500
        mockWebServer.enqueue(MockResponse().setResponseCode(500))
        // Second artist (Bad Brains) succeeds with empty list
        mockWebServer.enqueue(MockResponse().setBody("[]").setResponseCode(200))

        val result = connector.fetch()

        // Individual failures are logged but fetch() returns Right with collected events
        assertTrue(result.isRight(), "Expected Right despite first artist's 500")
        result.onRight { events ->
            assertEquals(0, events.size)
        }
    }

    @Test
    fun `fetch with malformed JSON logs failure and continues with next artist`() = runTest {
        // First artist (Fugazi) gets malformed JSON
        mockWebServer.enqueue(
            MockResponse()
                .setBody("{ invalid json")
                .setResponseCode(200)
        )
        // Second artist (Bad Brains) succeeds with empty list
        mockWebServer.enqueue(MockResponse().setBody("[]").setResponseCode(200))

        val result = connector.fetch()

        // Individual failures are logged but fetch() returns Right with collected events
        assertTrue(result.isRight(), "Expected Right despite first artist's malformed JSON")
        result.onRight { events ->
            assertEquals(0, events.size)
        }
    }

    @Test
    fun `fetch filters out non-DC events`() = runTest {
        // Mix of DC and non-DC events
        val response = """
            [
              {
                "id": "event-dc",
                "datetime": "2026-03-15T19:00:00Z",
                "venue": {
                  "name": "The Anthem",
                  "city": "Washington",
                  "region": "DC",
                  "country": "United States"
                },
                "lineup": ["Fugazi"],
                "offers": [
                  {"type": "Tickets", "url": "https://bandsintown.com/tickets"}
                ],
                "url": "https://bandsintown.com/event"
              },
              {
                "id": "event-ny",
                "datetime": "2026-03-16T20:00:00Z",
                "venue": {
                  "name": "Madison Square Garden",
                  "city": "New York",
                  "region": "NY",
                  "country": "United States"
                },
                "lineup": ["Fugazi"],
                "offers": [
                  {"type": "Tickets", "url": "https://bandsintown.com/tickets"}
                ],
                "url": "https://bandsintown.com/event"
              }
            ]
        """.trimIndent()

        mockWebServer.enqueue(MockResponse().setBody(response).setResponseCode(200))
        mockWebServer.enqueue(MockResponse().setBody("[]").setResponseCode(200))

        val result = connector.fetch()

        assertTrue(result.isRight(), "Expected Right")
        result.onRight { events ->
            assertEquals(1, events.size, "Should only have DC-area events")
            assertEquals("The Anthem", events[0].venueName)
        }
    }

    @Test
    fun `fetch skips individual artist failures and continues processing`() = runTest {
        // First artist (Fugazi) fails with 500
        mockWebServer.enqueue(MockResponse().setResponseCode(500))

        // Second artist (Bad Brains) succeeds
        val badBrainsResponse = """
            [
              {
                "id": "event-2",
                "datetime": "2026-03-20T20:00:00Z",
                "venue": {
                  "name": "The 930 Club",
                  "city": "Washington",
                  "region": "DC",
                  "country": "United States"
                },
                "lineup": ["Bad Brains"],
                "offers": [
                  {"type": "Tickets", "url": "https://bandsintown.com/tickets"}
                ],
                "url": "https://bandsintown.com/event"
              }
            ]
        """.trimIndent()

        mockWebServer.enqueue(MockResponse().setBody(badBrainsResponse).setResponseCode(200))

        val result = connector.fetch()

        assertTrue(result.isRight(), "fetch() should succeed despite individual artist failure")
        result.onRight { events ->
            assertEquals(1, events.size, "Should have events from Bad Brains despite Fugazi failure")
            assertEquals("Bad Brains", events[0].title)
        }
    }

    @Test
    fun `fetch maps all required event fields`() = runTest {
        val response = """
            [
              {
                "id": "event-123",
                "datetime": "2026-04-10T20:00:00Z",
                "venue": {
                  "name": "Kennedy Center",
                  "city": "Washington",
                  "region": "DC",
                  "country": "United States"
                },
                "lineup": ["Fugazi", "Minor Threat"],
                "offers": [
                  {
                    "type": "Tickets",
                    "url": "https://bandsintown.com/tickets"
                  }
                ],
                "url": "https://bandsintown.com/event123"
              }
            ]
        """.trimIndent()

        mockWebServer.enqueue(MockResponse().setBody(response).setResponseCode(200))
        mockWebServer.enqueue(MockResponse().setBody("[]").setResponseCode(200))

        val result = connector.fetch()

        assertTrue(result.isRight(), "Expected Right")
        result.onRight { events ->
            assertNotNull(events[0].startTime)
            assertEquals("Fugazi / Minor Threat", events[0].title)
            assertEquals("Kennedy Center", events[0].venueName)
            assertNotNull(events[0].artistNames)
            assertEquals(2, events[0].artistNames.size)
            assertEquals("Fugazi", events[0].artistNames[0])
            assertEquals("Minor Threat", events[0].artistNames[1])
            assertEquals("https://bandsintown.com/event123", events[0].sourceUrl)
            assertEquals("https://bandsintown.com/tickets", events[0].ticketUrl)
            assertTrue(events[0].sourceIdentifier.startsWith("Fugazi:"))
        }
    }

    @Test
    fun `fetch with missing optional fields does not crash`() = runTest {
        val response = """
            [
              {
                "id": "event-minimal",
                "datetime": "2026-05-15T20:00:00Z",
                "venue": {
                  "name": "Small Venue",
                  "city": "Washington",
                  "region": "DC"
                },
                "lineup": [],
                "offers": [],
                "url": ""
              }
            ]
        """.trimIndent()

        mockWebServer.enqueue(MockResponse().setBody(response).setResponseCode(200))
        mockWebServer.enqueue(MockResponse().setBody("[]").setResponseCode(200))

        val result = connector.fetch()

        assertTrue(result.isRight(), "Expected Right, got Left: ${result.mapLeft { it }}")
        result.onRight { events ->
            assertEquals(1, events.size)
            val event = events[0]
            assertEquals("Fugazi", event.title) // Falls back to artist name
            assertEquals("Small Venue", event.venueName)
        }
    }

    @Test
    fun `fetch sends correct query parameters to API`() = runTest {
        mockWebServer.enqueue(MockResponse().setBody("[]").setResponseCode(200))
        mockWebServer.enqueue(MockResponse().setBody("[]").setResponseCode(200))

        connector.fetch()

        val request = mockWebServer.takeRequest()
        assertTrue(request.path?.contains("app_id=test-app-id") ?: false, "App ID not in query params")
        assertTrue(request.path?.contains("date=upcoming") ?: false, "Date not in query params")
        assertTrue(request.path?.contains("artists") ?: false, "Artist path not present")
    }

    @Test
    fun `fetch with multiple events from single artist returns all DC-area events`() = runTest {
        val response = """
            [
              {
                "id": "event-1",
                "datetime": "2026-03-01T18:00:00Z",
                "venue": {
                  "name": "Venue One",
                  "city": "Washington",
                  "region": "DC",
                  "country": "United States"
                },
                "lineup": ["Fugazi"],
                "offers": [],
                "url": "https://bandsintown.com/event-1"
              },
              {
                "id": "event-2",
                "datetime": "2026-03-02T19:00:00Z",
                "venue": {
                  "name": "Venue Two",
                  "city": "Washington",
                  "region": "DC",
                  "country": "United States"
                },
                "lineup": ["Fugazi"],
                "offers": [],
                "url": "https://bandsintown.com/event-2"
              }
            ]
        """.trimIndent()

        mockWebServer.enqueue(MockResponse().setBody(response).setResponseCode(200))
        mockWebServer.enqueue(MockResponse().setBody("[]").setResponseCode(200))

        val result = connector.fetch()

        assertTrue(result.isRight(), "Expected Right")
        result.onRight { events ->
            assertEquals(2, events.size)
            assertEquals("Venue One", events[0].venueName)
            assertEquals("Venue Two", events[1].venueName)
        }
    }

    @Test
    fun `fetch with no seed artists configured returns error`() = runTest {
        val config = ConnectorConfig(
            bandsintown = ConnectorConfig.BandsintownConfig(
                appId = "test-app-id",
                baseUrl = mockWebServer.url("/").toString().removeSuffix("/"),
                seedArtists = emptyList()
            )
        )

        val webClientBuilder = WebClient.builder()
        val connectorNoArtists = BandsintownConnector(webClientBuilder, config, ObjectMapper())

        val result = connectorNoArtists.fetch()

        assertTrue(result.isLeft(), "Expected Left for no seed artists")
        result.onLeft { error ->
            assertTrue(error is IngestionError.ConfigurationError)
        }
    }

    @Test
    fun `fetch normalizes DC region names`() = runTest {
        val response = """
            [
              {
                "id": "event-1",
                "datetime": "2026-03-15T19:00:00Z",
                "venue": {
                  "name": "Venue",
                  "city": "Washington",
                  "region": "District of Columbia",
                  "country": "United States"
                },
                "lineup": ["Fugazi"],
                "offers": [],
                "url": "https://bandsintown.com/event"
              }
            ]
        """.trimIndent()

        mockWebServer.enqueue(MockResponse().setBody(response).setResponseCode(200))
        mockWebServer.enqueue(MockResponse().setBody("[]").setResponseCode(200))

        val result = connector.fetch()

        assertTrue(result.isRight(), "Expected Right")
        result.onRight { events ->
            assertEquals(1, events.size, "Should include 'District of Columbia' as DC-area")
        }
    }

    @Test
    fun `fetch with blank appId returns ConfigurationError`() = runTest {
        val config = ConnectorConfig(
            bandsintown = ConnectorConfig.BandsintownConfig(
                appId = "",
                baseUrl = mockWebServer.url("/").toString().removeSuffix("/"),
                seedArtists = listOf("Fugazi")
            )
        )

        val connectorNoKey = BandsintownConnector(WebClient.builder(), config, ObjectMapper())
        val result = connectorNoKey.fetch()

        assertTrue(result.isLeft(), "Expected Left for blank appId")
        result.onLeft { error ->
            assertTrue(error is IngestionError.ConfigurationError)
            assertTrue((error as IngestionError.ConfigurationError).message.contains("app_id"))
        }
    }

    @Test
    fun `healthCheck returns true on successful head request`() {
        mockWebServer.enqueue(MockResponse().setResponseCode(200))

        val result = connector.healthCheck()

        assertTrue(result)
    }

    @Test
    fun `healthCheck returns false on failed request`() {
        mockWebServer.enqueue(MockResponse().setResponseCode(500))

        val result = connector.healthCheck()

        assertTrue(!result)
    }

    @Test
    fun `fetch with non-array response for artist logs parse error and continues`() = runTest {
        mockWebServer.enqueue(MockResponse().setBody("""{"error": "Not an array"}""").setResponseCode(200))
        mockWebServer.enqueue(MockResponse().setBody("[]").setResponseCode(200))

        val result = connector.fetch()

        assertTrue(result.isRight(), "Expected Right - parse errors logged, not propagated")
        result.onRight { events -> assertEquals(0, events.size) }
    }
}
