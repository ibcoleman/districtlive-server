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

class MusicBrainzEnricherTest {

    private lateinit var mockWebServer: MockWebServer
    private lateinit var enricher: MusicBrainzEnricher

    @BeforeEach
    fun setUp() {
        mockWebServer = MockWebServer()
        mockWebServer.start()

        val config = EnrichmentConfig(
            musicbrainz = EnrichmentConfig.MusicBrainzConfig(
                enabled = true,
                rateLimitMs = 1100L,
                confidenceThreshold = 0.90,
                userAgent = "TestAgent/1.0",
                baseUrl = mockWebServer.url("/").toString().removeSuffix("/")
            )
        )

        val webClientBuilder = WebClient.builder()
        val objectMapper = ObjectMapper()
        enricher = MusicBrainzEnricher(webClientBuilder, config, objectMapper)
    }

    @AfterEach
    fun tearDown() {
        mockWebServer.shutdown()
    }

    @Test
    fun `high confidence match returns result with canonical name ID and tags`() = runTest {
        val response = """
            {
              "artists": [
                {
                  "id": "00000000-0000-0000-0000-000000000001",
                  "score": "95",
                  "name": "The Beatles",
                  "tags": [
                    {"name": "rock", "count": 100},
                    {"name": "pop", "count": 50}
                  ]
                }
              ]
            }
        """.trimIndent()

        mockWebServer.enqueue(MockResponse().setBody(response).setResponseCode(200))

        val result = enricher.enrich("The Beatles")

        assertNotNull(result)
        assertEquals("The Beatles", result.canonicalName)
        assertEquals("00000000-0000-0000-0000-000000000001", result.externalId)
        assertEquals(listOf("rock", "pop"), result.tags)
        assertEquals(true, result.confidence >= 0.90)
    }

    @Test
    fun `low Jaro-Winkler score returns null`() = runTest {
        val response = """
            {
              "artists": [
                {
                  "id": "00000000-0000-0000-0000-000000000002",
                  "score": "95",
                  "name": "xyzsomethingverydifferent",
                  "tags": []
                }
              ]
            }
        """.trimIndent()

        mockWebServer.enqueue(MockResponse().setBody(response).setResponseCode(200))

        val result = enricher.enrich("Metallica")

        assertNull(result, "Expected null when Jaro-Winkler score < 0.90")
    }

    @Test
    fun `MB score below 80 returns null`() = runTest {
        val response = """
            {
              "artists": [
                {
                  "id": "00000000-0000-0000-0000-000000000003",
                  "score": "75",
                  "name": "The Beatles",
                  "tags": []
                }
              ]
            }
        """.trimIndent()

        mockWebServer.enqueue(MockResponse().setBody(response).setResponseCode(200))

        val result = enricher.enrich("The Beatles")

        assertNull(result, "Expected null when MB score < 80")
    }

    @Test
    fun `API error returns null and does not propagate exception`() = runTest {
        mockWebServer.enqueue(MockResponse().setResponseCode(500))

        val result = enricher.enrich("Some Artist")

        assertNull(result, "Expected null on API error")
    }

    @Test
    fun `empty artist array returns null`() = runTest {
        val response = """
            {
              "artists": []
            }
        """.trimIndent()

        mockWebServer.enqueue(MockResponse().setBody(response).setResponseCode(200))

        val result = enricher.enrich("Nonexistent Artist")

        assertNull(result, "Expected null when artists array is empty")
    }

    @Test
    fun `User-Agent header is correctly sent`() = runTest {
        val response = """
            {
              "artists": [
                {
                  "id": "00000000-0000-0000-0000-000000000004",
                  "score": "90",
                  "name": "Test Artist",
                  "tags": []
                }
              ]
            }
        """.trimIndent()

        mockWebServer.enqueue(MockResponse().setBody(response).setResponseCode(200))

        enricher.enrich("Test Artist")

        val request = mockWebServer.takeRequest()
        assertEquals("TestAgent/1.0", request.getHeader("User-Agent"), "User-Agent header not correctly set")
    }
}
