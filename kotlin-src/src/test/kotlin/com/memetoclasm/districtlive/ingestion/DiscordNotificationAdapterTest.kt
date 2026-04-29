package com.memetoclasm.districtlive.ingestion

import okhttp3.mockwebserver.MockResponse
import okhttp3.mockwebserver.MockWebServer
import org.junit.jupiter.api.AfterEach
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import org.springframework.web.reactive.function.client.WebClient
import java.util.concurrent.TimeUnit
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertTrue

class DiscordNotificationAdapterTest {

    private lateinit var mockWebServer: MockWebServer
    private lateinit var adapter: DiscordNotificationAdapter

    @BeforeEach
    fun setUp() {
        mockWebServer = MockWebServer()
        mockWebServer.start()
    }

    @AfterEach
    fun tearDown() {
        mockWebServer.shutdown()
    }

    // ─── AC3.3: Empty webhook URL - no HTTP request made ──────────────────────────────────────

    @Test
    fun `when webhook URL is empty, notifySourceUnhealthy makes no HTTP request`() {
        val config = NotificationConfig(enabled = true, webhookUrl = "")
        adapter = DiscordNotificationAdapter(WebClient.builder(), config)

        adapter.notifySourceUnhealthy("ticketmaster", 3, "Connection refused")

        assertEquals(0, mockWebServer.requestCount, "Expected no HTTP requests when webhook URL is empty")
    }

    @Test
    fun `when webhook URL is empty, notifySourceRecovered makes no HTTP request`() {
        val config = NotificationConfig(enabled = true, webhookUrl = "")
        adapter = DiscordNotificationAdapter(WebClient.builder(), config)

        adapter.notifySourceRecovered("ticketmaster")

        assertEquals(0, mockWebServer.requestCount, "Expected no HTTP requests when webhook URL is empty")
    }

    // ─── AC3.3: Notifications disabled - no HTTP request made ──────────────────────────────────────

    @Test
    fun `when notifications disabled, notifySourceUnhealthy makes no HTTP request`() {
        val config = NotificationConfig(enabled = false, webhookUrl = mockWebServer.url("/webhook").toString())
        adapter = DiscordNotificationAdapter(WebClient.builder(), config)

        adapter.notifySourceUnhealthy("ticketmaster", 3, "Connection refused")

        assertEquals(0, mockWebServer.requestCount, "Expected no HTTP requests when notifications disabled")
    }

    @Test
    fun `when notifications disabled, notifySourceRecovered makes no HTTP request`() {
        val config = NotificationConfig(enabled = false, webhookUrl = mockWebServer.url("/webhook").toString())
        adapter = DiscordNotificationAdapter(WebClient.builder(), config)

        adapter.notifySourceRecovered("ticketmaster")

        assertEquals(0, mockWebServer.requestCount, "Expected no HTTP requests when notifications disabled")
    }

    // ─── AC3.4: Webhook failure logged but no exception thrown ──────────────────────────────────────

    @Test
    fun `when webhook returns 500, no exception is thrown and error is logged`() {
        val config = NotificationConfig(enabled = true, webhookUrl = mockWebServer.url("/webhook").toString())
        adapter = DiscordNotificationAdapter(WebClient.builder(), config)

        mockWebServer.enqueue(MockResponse().setResponseCode(500))

        // Should not throw
        adapter.notifySourceUnhealthy("ticketmaster", 3, "Connection refused")

        // Give the async request time to complete
        Thread.sleep(500)

        assertEquals(1, mockWebServer.requestCount, "Expected 1 HTTP request despite 500 error")
    }

    @Test
    fun `when webhook returns 4xx, no exception is thrown`() {
        val config = NotificationConfig(enabled = true, webhookUrl = mockWebServer.url("/webhook").toString())
        adapter = DiscordNotificationAdapter(WebClient.builder(), config)

        mockWebServer.enqueue(MockResponse().setResponseCode(404))

        // Should not throw
        adapter.notifySourceRecovered("ticketmaster")

        // Give the async request time to complete
        Thread.sleep(500)

        assertEquals(1, mockWebServer.requestCount, "Expected 1 HTTP request despite 404 error")
    }

    // ─── Success cases ──────────────────────────────────────────────────────────────

    @Test
    fun `successful unhealthy notification sends POST with correct payload`() {
        val config = NotificationConfig(enabled = true, webhookUrl = mockWebServer.url("/webhook").toString())
        adapter = DiscordNotificationAdapter(WebClient.builder(), config)

        mockWebServer.enqueue(MockResponse().setResponseCode(204))

        adapter.notifySourceUnhealthy("ticketmaster", 3, "Connection refused")

        // Give the async request time to complete
        val request = mockWebServer.takeRequest(1, TimeUnit.SECONDS)
        assertNotNull(request, "Expected a POST request")

        assertEquals("POST", request.method)
        assertEquals("/webhook", request.path)

        val body = request.body.readUtf8()
        assertTrue(body.contains("\"content\""), "Expected 'content' key in JSON body")
        assertTrue(body.contains("ticketmaster"), "Expected source name in message")
        assertTrue(body.contains("UNHEALTHY"), "Expected 'UNHEALTHY' in message")
        assertTrue(body.contains("Connection refused"), "Expected error message in payload")
    }

    @Test
    fun `successful recovery notification sends POST with correct payload`() {
        val config = NotificationConfig(enabled = true, webhookUrl = mockWebServer.url("/webhook").toString())
        adapter = DiscordNotificationAdapter(WebClient.builder(), config)

        mockWebServer.enqueue(MockResponse().setResponseCode(204))

        adapter.notifySourceRecovered("ticketmaster")

        // Give the async request time to complete
        val request = mockWebServer.takeRequest(1, TimeUnit.SECONDS)
        assertNotNull(request, "Expected a POST request")

        assertEquals("POST", request.method)
        assertEquals("/webhook", request.path)

        val body = request.body.readUtf8()
        assertTrue(body.contains("\"content\""), "Expected 'content' key in JSON body")
        assertTrue(body.contains("ticketmaster"), "Expected source name in message")
        assertTrue(body.contains("recovered"), "Expected 'recovered' in message")
    }

    @Test
    fun `unhealthy notification with null error message includes 'unknown'`() {
        val config = NotificationConfig(enabled = true, webhookUrl = mockWebServer.url("/webhook").toString())
        adapter = DiscordNotificationAdapter(WebClient.builder(), config)

        mockWebServer.enqueue(MockResponse().setResponseCode(204))

        adapter.notifySourceUnhealthy("bandsintown", 3, null)

        // Give the async request time to complete
        val request = mockWebServer.takeRequest(1, TimeUnit.SECONDS)
        assertNotNull(request, "Expected a POST request")

        val body = request.body.readUtf8()
        assertTrue(body.contains("unknown"), "Expected 'unknown' when error message is null")
    }
}
