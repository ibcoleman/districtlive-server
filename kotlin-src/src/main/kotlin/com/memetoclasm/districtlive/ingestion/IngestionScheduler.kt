package com.memetoclasm.districtlive.ingestion

import com.memetoclasm.districtlive.event.SourceType
import com.memetoclasm.districtlive.ingestion.service.IngestionOrchestrator
import com.memetoclasm.districtlive.ingestion.service.SourceHealthService
import kotlinx.coroutines.runBlocking
import org.slf4j.LoggerFactory
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty
import org.springframework.scheduling.annotation.EnableScheduling
import org.springframework.scheduling.annotation.Scheduled
import org.springframework.stereotype.Component

@Component
@EnableScheduling
@ConditionalOnProperty(name = ["districtlive.ingestion.enabled"], havingValue = "true")
class IngestionScheduler(
    private val connectors: List<SourceConnector>,
    private val orchestrator: IngestionOrchestrator,
    private val sourceHealthService: SourceHealthService,
    private val ingestionConfig: IngestionConfig
) {

    private val logger = LoggerFactory.getLogger(IngestionScheduler::class.java)

    /**
     * Runs API connectors (Ticketmaster, Bandsintown) every 6 hours.
     */
    @Scheduled(cron = "\${districtlive.ingestion.api-cron}")
    fun runApiConnectors() {
        val apiConnectors = connectors.filter { it.sourceType in API_SOURCE_TYPES }
        logger.info("Scheduled API ingestion triggered for {} connectors", apiConnectors.size)
        runConnectors(apiConnectors)
    }

    /**
     * Runs HTML scrapers and ticketing platform connectors daily at 3 AM.
     * Includes venue website scrapers (VENUE_SCRAPER) and Dice.fm (DICE_FM).
     */
    @Scheduled(cron = "\${districtlive.ingestion.scraper-cron}")
    fun runScraperConnectors() {
        val scraperConnectors = connectors.filter { it.sourceType in SCRAPER_SOURCE_TYPES }
        logger.info("Scheduled scraper ingestion triggered for {} connectors", scraperConnectors.size)
        runConnectors(scraperConnectors)
    }

    /**
     * Runs all connectors. Used for manual/admin triggers.
     * Bypasses health check so admins can retry after fixing issues.
     */
    fun runAllConnectors() {
        logger.info("Manual ingestion triggered for all {} connectors (bypassing health check)", connectors.size)
        for (connector in connectors) {
            try {
                runBlocking {
                    orchestrator.runIngestion(connector)
                }
            } catch (e: Exception) {
                logger.error("Connector '{}' failed during manual run: {}", connector.sourceId, e.message)
            }
        }
    }

    /**
     * Runs a single connector by sourceId. Used for manual/admin triggers.
     * Bypasses health check so admins can retry after fixing issues.
     */
    fun runSingleConnector(sourceId: String) {
        val connector = connectors.find { it.sourceId == sourceId }
            ?: throw IllegalArgumentException("No connector found with sourceId '$sourceId'")

        logger.info("Manual ingestion triggered for connector '{}' (bypassing health check)", sourceId)
        try {
            runBlocking {
                orchestrator.runIngestion(connector)
            }
        } catch (e: Exception) {
            logger.error("Connector '{}' failed during manual run: {}", connector.sourceId, e.message)
        }
    }

    private fun runConnectors(connectorsToRun: List<SourceConnector>) {
        for (connector in connectorsToRun) {
            val source = sourceHealthService.findSourceByName(connector.sourceId)
            if (source != null && !source.healthy) {
                logger.warn("Skipping unhealthy connector '{}'", connector.sourceId)
                continue
            }

            try {
                runBlocking {
                    orchestrator.runIngestion(connector)
                }
            } catch (e: Exception) {
                logger.error("Connector '{}' failed during scheduled run: {}", connector.sourceId, e.message)
            }
        }
    }

    companion object {
        private val API_SOURCE_TYPES = setOf(
            SourceType.TICKETMASTER_API,
            SourceType.BANDSINTOWN_API
        )
        private val SCRAPER_SOURCE_TYPES = setOf(
            SourceType.VENUE_SCRAPER,
            SourceType.DICE_FM
        )
    }
}
