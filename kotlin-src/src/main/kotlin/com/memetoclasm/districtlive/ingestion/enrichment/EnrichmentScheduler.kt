package com.memetoclasm.districtlive.ingestion.enrichment

import kotlinx.coroutines.runBlocking
import org.slf4j.LoggerFactory
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty
import org.springframework.scheduling.annotation.EnableScheduling
import org.springframework.scheduling.annotation.Scheduled
import org.springframework.stereotype.Component

@Component
@EnableScheduling
@ConditionalOnProperty(name = ["enrichment.enabled"], havingValue = "true")
class EnrichmentScheduler(
    private val enrichmentService: ArtistEnrichmentService
) {
    private val logger = LoggerFactory.getLogger(EnrichmentScheduler::class.java)

    @Scheduled(cron = "\${enrichment.schedule}")
    fun runEnrichmentBatch() {
        logger.info("Scheduled enrichment batch triggered")
        try {
            runBlocking {
                enrichmentService.enrichBatch()
            }
        } catch (e: Exception) {
            logger.error("Enrichment batch failed: {}", e.message)
        }
    }
}
