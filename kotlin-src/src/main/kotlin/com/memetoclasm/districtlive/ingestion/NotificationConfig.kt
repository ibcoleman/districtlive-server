package com.memetoclasm.districtlive.ingestion

import org.springframework.boot.context.properties.ConfigurationProperties

@ConfigurationProperties(prefix = "districtlive.notifications.discord")
data class NotificationConfig(
    var enabled: Boolean = false,
    var webhookUrl: String = ""
)
