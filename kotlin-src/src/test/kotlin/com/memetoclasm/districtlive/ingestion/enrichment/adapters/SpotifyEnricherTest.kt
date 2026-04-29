package com.memetoclasm.districtlive.ingestion.enrichment.adapters

import com.fasterxml.jackson.databind.ObjectMapper
import com.memetoclasm.districtlive.ingestion.enrichment.EnrichmentConfig
import okhttp3.mockwebserver.MockResponse
import okhttp3.mockwebserver.MockWebServer
import org.junit.jupiter.api.AfterEach
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import org.springframework.web.reactive.function.client.WebClient
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull
import kotlinx.coroutines.test.runTest
import java.time.Instant
import java.util.Base64

class SpotifyEnricherTest {

    private lateinit var mockWebServer: MockWebServer
    private lateinit var enricher: SpotifyEnricher
    private lateinit var config: EnrichmentConfig

    @BeforeEach
    fun setUp() {
        mockWebServer = MockWebServer()
        mockWebServer.start()
        val baseUrl = mockWebServer.url("/").toString().trimEnd('/')
        config = EnrichmentConfig(
            spotify = EnrichmentConfig.SpotifyConfig(
                enabled = true,
                clientId = "test-client-id",
                clientSecret = "test-client-secret",
                tokenBaseUrl = baseUrl,
                searchBaseUrl = baseUrl,
                maxRetries = 2,
                confidenceThreshold = 0.90
            )
        )
        enricher = SpotifyEnricher(WebClient.builder(), config, ObjectMapper())
    }

    @AfterEach
    fun tearDown() {
        mockWebServer.shutdown()
    }

    private fun enqueueTokenResponse() {
        mockWebServer.enqueue(
            MockResponse()
                .setBody("""{"access_token":"test-token","token_type":"Bearer","expires_in":3600}""")
                .addHeader("Content-Type", "application/json")
        )
    }

    @Test
    fun `successful enrichment returns result with externalId tags and imageUrl`() = runTest {
        enqueueTokenResponse()
        val searchResponse = """{
            "artists": {
                "items": [
                    {
                        "id": "spotify-abc123",
                        "name": "Test Artist",
                        "genres": ["indie rock", "alternative"],
                        "images": [
                            {"url": "https://i.scdn.co/image/test.jpg", "height": 640, "width": 640}
                        ]
                    }
                ]
            }
        }"""
        mockWebServer.enqueue(
            MockResponse()
                .setBody(searchResponse)
                .addHeader("Content-Type", "application/json")
        )

        val result = enricher.enrich("Test Artist")

        assertNotNull(result)
        assertEquals("spotify-abc123", result.externalId)
        assertEquals(listOf("indie rock", "alternative"), result.tags)
        assertEquals("https://i.scdn.co/image/test.jpg", result.imageUrl)
        assertNull(result.canonicalName, "Spotify does not rename artists")
        assertEquals(1.0, result.confidence)
    }

    @Test
    fun `token refresh when cached token is expired`() = runTest {
        enqueueTokenResponse()
        val searchResponse = """{
            "artists": {
                "items": [
                    {
                        "id": "spotify-abc123",
                        "name": "Test Artist",
                        "genres": ["indie rock"],
                        "images": []
                    }
                ]
            }
        }"""
        mockWebServer.enqueue(
            MockResponse()
                .setBody(searchResponse)
                .addHeader("Content-Type", "application/json")
        )

        // First enrichment to warm the cache
        enricher.enrich("Test Artist")

        // Force token expiry
        enricher.tokenExpiresAt = Instant.EPOCH

        // Enqueue second token + second search response
        enqueueTokenResponse()
        mockWebServer.enqueue(
            MockResponse()
                .setBody(searchResponse)
                .addHeader("Content-Type", "application/json")
        )

        // Second enrichment should fetch a new token
        enricher.enrich("Test Artist")

        // Assert 4 requests: token, search, token, search
        assertEquals(4, mockWebServer.requestCount)
    }

    @Test
    fun `429 exhausted returns null`() = runTest {
        enqueueTokenResponse()

        // Enqueue maxRetries + 1 = 3 x 429 responses (attempts 0, 1, 2)
        repeat(config.spotify.maxRetries + 1) {
            mockWebServer.enqueue(
                MockResponse().setResponseCode(429).addHeader("Retry-After", "0")
            )
        }

        val result = enricher.enrich("Test Artist")

        assertNull(result)
    }

    @Test
    fun `disabled returns null immediately with 0 network requests`() = runTest {
        val disabledEnricher = SpotifyEnricher(
            WebClient.builder(),
            EnrichmentConfig(
                spotify = EnrichmentConfig.SpotifyConfig(
                    enabled = false,
                    clientId = "test",
                    clientSecret = "test",
                    tokenBaseUrl = mockWebServer.url("/").toString().trimEnd('/'),
                    searchBaseUrl = mockWebServer.url("/").toString().trimEnd('/')
                )
            ),
            ObjectMapper()
        )

        val result = disabledEnricher.enrich("Test Artist")

        assertNull(result)
        assertEquals(0, mockWebServer.requestCount)
    }

    @Test
    fun `empty Spotify result returns null`() = runTest {
        enqueueTokenResponse()
        mockWebServer.enqueue(
            MockResponse()
                .setBody("""{"artists": {"items": []}}""")
                .addHeader("Content-Type", "application/json")
        )

        val result = enricher.enrich("Nonexistent Artist")

        assertNull(result)
    }

    @Test
    fun `low-confidence rejection returns null`() = runTest {
        enqueueTokenResponse()
        val searchResponse = """{
            "artists": {
                "items": [
                    {
                        "id": "spotify-xyz789",
                        "name": "Completely Different Name",
                        "genres": ["rock"],
                        "images": []
                    }
                ]
            }
        }"""
        mockWebServer.enqueue(
            MockResponse()
                .setBody(searchResponse)
                .addHeader("Content-Type", "application/json")
        )

        val result = enricher.enrich("Test Artist")

        assertNull(result, "Confidence should be below threshold 0.90")
    }

    @Test
    fun `Authorization header on token request is correctly sent`() = runTest {
        enqueueTokenResponse()
        val searchResponse = """{
            "artists": {
                "items": [
                    {
                        "id": "spotify-abc123",
                        "name": "Test Artist",
                        "genres": [],
                        "images": []
                    }
                ]
            }
        }"""
        mockWebServer.enqueue(
            MockResponse()
                .setBody(searchResponse)
                .addHeader("Content-Type", "application/json")
        )

        enricher.enrich("Test Artist")

        val tokenRequest = mockWebServer.takeRequest()
        val expectedAuth = "Basic " + Base64.getEncoder().encodeToString("test-client-id:test-client-secret".toByteArray())
        assertEquals(expectedAuth, tokenRequest.getHeader("Authorization"), "Authorization header not correctly set on token request")
    }
}
