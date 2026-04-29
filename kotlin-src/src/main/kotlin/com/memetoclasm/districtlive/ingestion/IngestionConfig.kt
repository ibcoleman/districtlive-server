package com.memetoclasm.districtlive.ingestion

import org.springframework.boot.context.properties.ConfigurationProperties

@ConfigurationProperties(prefix = "districtlive.ingestion")
data class IngestionConfig(
    var enabled: Boolean = false,
    var apiCron: String = "0 0 */6 * * *",
    var scraperCron: String = "0 0 3 * * *"
)
