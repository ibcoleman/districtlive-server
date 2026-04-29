package com.memetoclasm.districtlive.ingestion.service

import com.memetoclasm.districtlive.event.*
import com.memetoclasm.districtlive.ingestion.IngestionError
import com.memetoclasm.districtlive.ingestion.SourceConnector
import com.memetoclasm.districtlive.ingestion.jpa.IngestionRunEntity
import com.memetoclasm.districtlive.ingestion.jpa.IngestionRunRepository
import com.memetoclasm.districtlive.ingestion.jpa.IngestionRunStatus
import org.slf4j.LoggerFactory
import org.springframework.stereotype.Service
import java.time.Instant
import java.util.UUID

data class IngestionStats(
    val eventsFetched: Int = 0,
    val eventsCreated: Int = 0,
    val eventsUpdated: Int = 0,
    val eventsDeduplicated: Int = 0
)

@Service
class IngestionOrchestrator(
    private val normalizationService: NormalizationService,
    private val deduplicationService: DeduplicationService,
    private val sourceHealthService: SourceHealthService,
    private val eventRepositoryPort: EventRepositoryPort,
    private val runRepository: IngestionRunRepository
) {

    private val logger = LoggerFactory.getLogger(IngestionOrchestrator::class.java)

    /**
     * Executes the full ingestion pipeline for a given connector:
     * 1. Create ingestion run record
     * 2. Fetch raw events from connector
     * 3. Normalize raw events
     * 4. Deduplicate normalized events
     * 5. Persist deduplicated events (upsert)
     * 6. Update source health and ingestion run record
     */
    suspend fun runIngestion(connector: SourceConnector): IngestionStats {
        val source = sourceHealthService.findSourceByName(connector.sourceId)
        val sourceDbId = source?.id ?: run {
            logger.warn("No source record found for connector '{}', skipping run tracking", connector.sourceId)
            return runIngestionWithoutTracking(connector)
        }

        val run = runRepository.save(
            IngestionRunEntity(
                sourceId = sourceDbId,
                status = IngestionRunStatus.RUNNING,
                startedAt = Instant.now()
            )
        )

        val runId = run.id

        return try {
            val stats = executeIngestionPipeline(connector, sourceDbId)

            completeRun(runId, stats)
            sourceHealthService.recordSuccess(sourceDbId)
            logger.info(
                "Ingestion complete for '{}': fetched={}, created={}, updated={}, deduped={}",
                connector.sourceId, stats.eventsFetched, stats.eventsCreated,
                stats.eventsUpdated, stats.eventsDeduplicated
            )
            stats
        } catch (e: Exception) {
            val errorMsg = e.message ?: "Unknown error"
            failRun(runId, errorMsg)
            sourceHealthService.recordFailure(sourceDbId, errorMsg)
            logger.error("Ingestion failed for '{}': {}", connector.sourceId, errorMsg, e)
            throw e
        }
    }

    fun completeRun(runId: UUID, stats: IngestionStats) {
        runRepository.markSuccess(
            id = runId,
            status = IngestionRunStatus.SUCCESS,
            eventsFetched = stats.eventsFetched,
            eventsCreated = stats.eventsCreated,
            eventsUpdated = stats.eventsUpdated,
            eventsDeduplicated = stats.eventsDeduplicated,
            completedAt = Instant.now()
        )
    }

    fun failRun(runId: UUID, errorMsg: String) {
        runRepository.markFailed(
            id = runId,
            status = IngestionRunStatus.FAILED,
            errorMessage = errorMsg,
            completedAt = Instant.now()
        )
    }

    private fun isPlaceholderTitle(title: String): Boolean {
        val normalized = title.trim().lowercase()
        return normalized in setOf(
            "private event",
            "tba",
            "to be announced",
            "coming soon",
            "sold out"
        ) || normalized.startsWith("sold out:")
    }

    private suspend fun runIngestionWithoutTracking(connector: SourceConnector): IngestionStats {
        return executeIngestionPipeline(connector, sourceId = null)
    }

    private suspend fun executeIngestionPipeline(connector: SourceConnector, sourceId: java.util.UUID?): IngestionStats {
        // Step 1: Fetch
        val rawEvents = connector.fetch().fold(
            { error -> throw RuntimeException("Ingestion fetch failed for '${connector.sourceId}': $error") },
            { events -> events }
        )

        if (rawEvents.isEmpty()) {
            logger.info("Connector '{}' returned 0 events", connector.sourceId)
            return IngestionStats(eventsFetched = 0)
        }

        // Step 2: Normalize
        val normalizedEvents = normalizationService.normalize(rawEvents).fold(
            { error -> throw RuntimeException("Normalization failed for '${connector.sourceId}': $error") },
            { events -> events }
        )

        // Step 3: Filter placeholder titles
        val filtered = normalizedEvents.filterNot { isPlaceholderTitle(it.title) }
        val filteredCount = normalizedEvents.size - filtered.size
        if (filteredCount > 0) {
            logger.info("Filtered {} placeholder events for '{}'", filteredCount, connector.sourceId)
        }

        // Step 4: Deduplicate
        val deduplicated = deduplicationService.deduplicate(filtered)
        val deduplicatedCount = rawEvents.size - filteredCount - deduplicated.size

        // Step 5: Persist via port
        var created = 0
        var updated = 0
        for (deduped in deduplicated) {
            val command = EventUpsertCommand(
                slug = deduped.canonical.slug,
                title = deduped.canonical.title,
                description = deduped.canonical.description,
                startTime = deduped.canonical.startTime,
                endTime = deduped.canonical.endTime,
                doorsTime = deduped.canonical.doorsTime,
                venueName = deduped.canonical.venueName,
                venueAddress = deduped.canonical.venueAddress,
                artistNames = deduped.canonical.artistNames,
                minPrice = deduped.canonical.minPrice,
                maxPrice = deduped.canonical.maxPrice,
                priceTier = deduped.canonical.priceTier,
                ticketUrl = deduped.canonical.ticketUrl,
                imageUrl = deduped.canonical.imageUrl,
                ageRestriction = deduped.canonical.ageRestriction,
                sourceAttributions = deduped.sources.map {
                    EventSourceAttribution(
                        sourceType = it.sourceType,
                        sourceIdentifier = it.sourceIdentifier,
                        sourceUrl = it.sourceUrl,
                        confidenceScore = it.confidenceScore,
                        sourceId = sourceId
                    )
                }
            )

            eventRepositoryPort.upsertEvent(command).fold(
                { error ->
                    logger.error("Failed to persist event '{}': {}", deduped.canonical.slug, error)
                },
                { result ->
                    when (result) {
                        is UpsertResult.Created -> created++
                        is UpsertResult.Updated -> updated++
                    }
                }
            )
        }

        return IngestionStats(
            eventsFetched = rawEvents.size,
            eventsCreated = created,
            eventsUpdated = updated,
            eventsDeduplicated = deduplicatedCount
        )
    }
}
