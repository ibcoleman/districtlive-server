package com.memetoclasm.districtlive.admin

import com.memetoclasm.districtlive.event.jpa.SourceEntity
import com.memetoclasm.districtlive.featured.handleFeaturedEventError
import com.memetoclasm.districtlive.featured.service.FeaturedEventService
import com.memetoclasm.districtlive.ingestion.IngestionScheduler
import com.memetoclasm.districtlive.ingestion.jpa.IngestionRunEntity
import com.memetoclasm.districtlive.ingestion.jpa.IngestionRunRepository
import com.memetoclasm.districtlive.ingestion.service.SourceHealthService
import jakarta.validation.Valid
import jakarta.validation.constraints.NotBlank
import jakarta.validation.constraints.Size
import org.slf4j.LoggerFactory
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.*
import java.util.UUID

@RestController
@RequestMapping(value = ["/api/admin"])
class AdminApiService(
    private val sourceHealthService: SourceHealthService,
    private val ingestionScheduler: IngestionScheduler?,
    private val ingestionRunRepository: IngestionRunRepository,
    private val featuredEventService: FeaturedEventService
) {

    private val logger = LoggerFactory.getLogger(AdminApiService::class.java)

    @GetMapping(value = ["/sources"])
    fun getSources(): ResponseEntity<List<SourceHealthDto>> {
        val sources = sourceHealthService.getAllSourceHealth()
        val dtos = sources.map { it.toDto() }
        return ResponseEntity.ok(dtos)
    }

    @GetMapping(value = ["/sources/{id}"])
    fun getSource(@PathVariable id: UUID): ResponseEntity<Any> {
        val source = sourceHealthService.getAllSourceHealth().find { it.id == id }
            ?: return ResponseEntity.notFound().build()
        return ResponseEntity.ok(source.toDto())
    }

    @GetMapping(value = ["/sources/{id}/history"])
    fun getSourceHistory(@PathVariable id: UUID): ResponseEntity<List<IngestionRunDto>> {
        val runs = ingestionRunRepository.findBySourceIdOrderByStartedAtDesc(id)
        val dtos = runs.map { it.toDto() }
        return ResponseEntity.ok(dtos)
    }

    @PostMapping(value = ["/featured"])
    fun createFeatured(@Valid @RequestBody request: CreateFeaturedRequest): ResponseEntity<Any> {
        return featuredEventService.createFeatured(request.eventId, request.blurb).fold(
            ifLeft = { handleFeaturedEventError(it) },
            ifRight = { ResponseEntity.ok(it) }
        )
    }

    @GetMapping(value = ["/featured/history"])
    fun getFeaturedHistory(): ResponseEntity<Any> {
        val history = featuredEventService.getHistory()
        return ResponseEntity.ok(history)
    }

    @PostMapping(value = ["/ingest/trigger"])
    fun triggerAllIngestion(): ResponseEntity<Any> {
        if (ingestionScheduler == null) {
            return ResponseEntity.badRequest().body(
                mapOf("error" to "Ingestion is not enabled. Set INGESTION_ENABLED=true.")
            )
        }
        return try {
            ingestionScheduler.runAllConnectors()
            ResponseEntity.ok(mapOf("status" to "triggered", "sourceId" to "all"))
        } catch (e: Exception) {
            logger.error("Manual ingestion trigger failed for all sources", e)
            ResponseEntity.internalServerError().body(
                mapOf("error" to "Ingestion failed: ${e.message}")
            )
        }
    }

    @PostMapping(value = ["/ingest/trigger/{sourceId}"])
    fun triggerIngestion(@PathVariable sourceId: String): ResponseEntity<Any> {
        if (ingestionScheduler == null) {
            return ResponseEntity.badRequest().body(
                mapOf("error" to "Ingestion is not enabled. Set INGESTION_ENABLED=true.")
            )
        }
        return try {
            ingestionScheduler.runSingleConnector(sourceId)
            ResponseEntity.ok(mapOf("status" to "triggered", "sourceId" to sourceId))
        } catch (e: IllegalArgumentException) {
            ResponseEntity.badRequest().body(mapOf("error" to e.message))
        } catch (e: Exception) {
            logger.error("Manual ingestion trigger failed for source '{}'", sourceId, e)
            ResponseEntity.internalServerError().body(
                mapOf("error" to "Ingestion failed: ${e.message}")
            )
        }
    }
}

data class CreateFeaturedRequest(
    val eventId: UUID,
    @field:NotBlank(message = "Blurb is required")
    @field:Size(max = 500, message = "Blurb must be 500 characters or fewer")
    val blurb: String
)

data class SourceHealthDto(
    val id: UUID,
    val name: String,
    val sourceType: String,
    val scrapeSchedule: String?,
    val lastSuccessAt: java.time.Instant?,
    val lastFailureAt: java.time.Instant?,
    val consecutiveFailures: Int,
    val healthy: Boolean
)

data class IngestionRunDto(
    val id: UUID,
    val sourceId: UUID,
    val status: String,
    val eventsFetched: Int,
    val eventsCreated: Int,
    val eventsUpdated: Int,
    val eventsDeduplicated: Int,
    val errorMessage: String?,
    val startedAt: java.time.Instant,
    val completedAt: java.time.Instant?
)

private fun SourceEntity.toDto() = SourceHealthDto(
    id = id,
    name = name,
    sourceType = sourceType.name,
    scrapeSchedule = scrapeSchedule,
    lastSuccessAt = lastSuccessAt,
    lastFailureAt = lastFailureAt,
    consecutiveFailures = consecutiveFailures,
    healthy = healthy
)

private fun IngestionRunEntity.toDto() = IngestionRunDto(
    id = id,
    sourceId = sourceId,
    status = status.name,
    eventsFetched = eventsFetched,
    eventsCreated = eventsCreated,
    eventsUpdated = eventsUpdated,
    eventsDeduplicated = eventsDeduplicated,
    errorMessage = errorMessage,
    startedAt = startedAt,
    completedAt = completedAt
)
