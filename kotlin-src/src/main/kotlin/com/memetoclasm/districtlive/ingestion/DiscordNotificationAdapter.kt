package com.memetoclasm.districtlive.ingestion

import org.slf4j.LoggerFactory
import org.springframework.stereotype.Component
import org.springframework.web.reactive.function.client.WebClient

@Component
class DiscordNotificationAdapter(
    webClientBuilder: WebClient.Builder,
    private val config: NotificationConfig
) : NotificationPort {

    private val logger = LoggerFactory.getLogger(DiscordNotificationAdapter::class.java)
    private val webClient = webClientBuilder.build()

    override fun notifySourceUnhealthy(sourceName: String, consecutiveFailures: Int, errorMessage: String?) {
        if (!shouldNotify()) return

        val message = "[ALERT] Ingestion source '$sourceName' is UNHEALTHY after $consecutiveFailures consecutive failures. Last error: ${errorMessage ?: "unknown"}"
        sendDiscordMessage(message)
    }

    override fun notifySourceRecovered(sourceName: String) {
        if (!shouldNotify()) return

        val message = "[RECOVERED] Ingestion source '$sourceName' has recovered and is healthy again."
        sendDiscordMessage(message)
    }

    private fun shouldNotify(): Boolean {
        return config.enabled && config.webhookUrl.isNotBlank()
    }

    private fun sendDiscordMessage(message: String) {
        webClient.post()
            .uri(config.webhookUrl)
            .bodyValue(mapOf("content" to message))
            .retrieve()
            .toBodilessEntity()
            .subscribe({}, { e ->
                logger.error("Discord notification failed: {}", e.message)
            })
    }
}
