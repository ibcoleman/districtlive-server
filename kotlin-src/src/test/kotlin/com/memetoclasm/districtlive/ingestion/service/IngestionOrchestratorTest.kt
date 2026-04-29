package com.memetoclasm.districtlive.ingestion.service

import arrow.core.Either
import arrow.core.left
import arrow.core.right
import com.memetoclasm.districtlive.event.*
import com.memetoclasm.districtlive.event.jpa.*
import com.memetoclasm.districtlive.ingestion.IngestionError
import com.memetoclasm.districtlive.ingestion.RawEventDto
import com.memetoclasm.districtlive.ingestion.SourceConnector
import com.memetoclasm.districtlive.ingestion.jpa.IngestionRunEntity
import com.memetoclasm.districtlive.ingestion.jpa.IngestionRunRepository
import com.memetoclasm.districtlive.ingestion.jpa.IngestionRunStatus
import kotlinx.coroutines.test.runTest
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.assertThrows
import org.mockito.kotlin.*
import java.math.BigDecimal
import java.time.Instant
import java.util.*
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class IngestionOrchestratorTest {

    private val normalizationService = NormalizationService()
    private val deduplicationService = DeduplicationService()
    private val sourceHealthService: SourceHealthService = mock()
    private val eventRepositoryPort: EventRepositoryPort = mock()
    private val runRepository: IngestionRunRepository = mock()

    private val orchestrator = IngestionOrchestrator(
        normalizationService = normalizationService,
        deduplicationService = deduplicationService,
        sourceHealthService = sourceHealthService,
        eventRepositoryPort = eventRepositoryPort,
        runRepository = runRepository
    )

    private val sourceDbId = UUID.randomUUID()
    private val sourceEntity = SourceEntity(
        id = sourceDbId,
        name = "test-connector",
        sourceType = SourceType.TICKETMASTER_API
    )

    private fun makeConnector(
        sourceId: String = "test-connector",
        sourceType: SourceType = SourceType.TICKETMASTER_API,
        fetchResult: () -> arrow.core.Either<IngestionError, List<RawEventDto>>
    ): SourceConnector {
        return object : SourceConnector {
            override val sourceId = sourceId
            override val sourceType = sourceType
            override suspend fun fetch() = fetchResult()
            override fun healthCheck() = true
        }
    }

    private fun setupRunTracking() {
        whenever(sourceHealthService.findSourceByName("test-connector")).thenReturn(sourceEntity)
        whenever(runRepository.save(any())).thenAnswer { it.arguments[0] as IngestionRunEntity }
    }

    @Test
    fun `runIngestion with empty result returns zero stats`() = runTest {
        setupRunTracking()
        val connector = makeConnector { emptyList<RawEventDto>().right() }

        val stats = orchestrator.runIngestion(connector)

        assertEquals(0, stats.eventsFetched)
        assertEquals(0, stats.eventsCreated)
        verify(sourceHealthService).recordSuccess(sourceDbId)
        verify(eventRepositoryPort, never()).upsertEvent(any())
    }

    @Test
    fun `runIngestion creates new events when none exist`() = runTest {
        setupRunTracking()
        val rawEvents = listOf(
            RawEventDto(
                sourceType = SourceType.TICKETMASTER_API,
                sourceIdentifier = "tm-001",
                title = "Test Show",
                venueName = "Black Cat",
                startTime = Instant.parse("2026-03-15T21:00:00Z"),
                minPrice = BigDecimal("15"),
                maxPrice = BigDecimal("20"),
                confidenceScore = BigDecimal("0.90")
            )
        )
        val connector = makeConnector { rawEvents.right() }

        whenever(eventRepositoryPort.upsertEvent(any())).thenReturn(
            Either.Right(UpsertResult.Created(UUID.randomUUID()))
        )

        val stats = orchestrator.runIngestion(connector)

        assertEquals(1, stats.eventsFetched)
        assertEquals(1, stats.eventsCreated)
        assertEquals(0, stats.eventsUpdated)
        verify(sourceHealthService).recordSuccess(sourceDbId)
        verify(eventRepositoryPort).upsertEvent(any())
    }

    @Test
    fun `runIngestion updates existing events`() = runTest {
        setupRunTracking()
        val rawEvents = listOf(
            RawEventDto(
                sourceType = SourceType.TICKETMASTER_API,
                sourceIdentifier = "tm-001",
                title = "Test Show",
                venueName = "Black Cat",
                startTime = Instant.parse("2026-03-15T21:00:00Z"),
                confidenceScore = BigDecimal("0.90")
            )
        )
        val connector = makeConnector { rawEvents.right() }

        whenever(eventRepositoryPort.upsertEvent(any())).thenReturn(
            Either.Right(UpsertResult.Updated(UUID.randomUUID()))
        )

        val stats = orchestrator.runIngestion(connector)

        assertEquals(1, stats.eventsFetched)
        assertEquals(0, stats.eventsCreated)
        assertEquals(1, stats.eventsUpdated)
        verify(eventRepositoryPort).upsertEvent(any())
    }

    @Test
    fun `runIngestion records failure on connector error`() = runTest {
        setupRunTracking()
        val connector = makeConnector {
            IngestionError.ConnectionError("test", "Connection refused").left()
        }

        assertThrows<RuntimeException> {
            orchestrator.runIngestion(connector)
        }

        verify(sourceHealthService).recordFailure(eq(sourceDbId), any())
    }

    @Test
    fun `runIngestion skips events with normalization errors and succeeds`() = runTest {
        setupRunTracking()
        // RawEventDto with missing startTime will be skipped during normalization
        val rawEvents = listOf(
            RawEventDto(
                sourceType = SourceType.TICKETMASTER_API,
                sourceIdentifier = "tm-001",
                title = "Test Show",
                startTime = null, // Missing required startTime — will be skipped
                confidenceScore = BigDecimal("0.90")
            )
        )
        val connector = makeConnector { rawEvents.right() }

        val stats = orchestrator.runIngestion(connector)

        assertEquals(1, stats.eventsFetched)
        assertEquals(0, stats.eventsCreated)
        assertEquals(0, stats.eventsUpdated)
        verify(sourceHealthService).recordSuccess(sourceDbId)
        verify(eventRepositoryPort, never()).upsertEvent(any())
    }

    @Test
    fun `runIngestion without source record still completes pipeline`() = runTest {
        // No source record in DB
        whenever(sourceHealthService.findSourceByName("test-connector")).thenReturn(null)
        val connector = makeConnector { emptyList<RawEventDto>().right() }

        val stats = orchestrator.runIngestion(connector)

        assertEquals(0, stats.eventsFetched)
        // No run tracking calls since no source record
        verify(runRepository, never()).save(any())
        verify(eventRepositoryPort, never()).upsertEvent(any())
    }

    @Test
    fun `runIngestion deduplicates events from same source`() = runTest {
        setupRunTracking()
        // Two raw events that will match as duplicates (same venue, same date, similar title)
        val rawEvents = listOf(
            RawEventDto(
                sourceType = SourceType.TICKETMASTER_API,
                sourceIdentifier = "tm-001",
                title = "Artist Name at Black Cat",
                venueName = "Black Cat",
                startTime = Instant.parse("2026-03-15T21:00:00Z"),
                confidenceScore = BigDecimal("0.90")
            ),
            RawEventDto(
                sourceType = SourceType.TICKETMASTER_API,
                sourceIdentifier = "tm-002",
                title = "Artist Name at Black Cat",
                venueName = "Black Cat",
                startTime = Instant.parse("2026-03-15T21:30:00Z"),
                confidenceScore = BigDecimal("0.80")
            )
        )
        val connector = makeConnector { rawEvents.right() }

        whenever(eventRepositoryPort.upsertEvent(any())).thenReturn(
            Either.Right(UpsertResult.Created(UUID.randomUUID()))
        )

        val stats = orchestrator.runIngestion(connector)

        assertEquals(2, stats.eventsFetched)
        // Should be deduplicated to 1
        assertEquals(1, stats.eventsDeduplicated)
        assertTrue(stats.eventsCreated + stats.eventsUpdated == 1)
        verify(eventRepositoryPort).upsertEvent(any())
    }


    @Test
    fun `runIngestion saves ingestion run on success`() = runTest {
        setupRunTracking()
        val connector = makeConnector { emptyList<RawEventDto>().right() }

        orchestrator.runIngestion(connector)

        // Initial RUNNING save + markSuccess for completion
        verify(runRepository).save(any())
        verify(runRepository).markSuccess(
            id = any(),
            status = eq(IngestionRunStatus.SUCCESS),
            eventsFetched = any(),
            eventsCreated = any(),
            eventsUpdated = any(),
            eventsDeduplicated = any(),
            completedAt = any()
        )
    }

    @Test
    fun `runIngestion saves ingestion run on failure`() = runTest {
        setupRunTracking()
        val connector = makeConnector {
            IngestionError.ConnectionError("test", "timeout").left()
        }

        assertThrows<RuntimeException> {
            orchestrator.runIngestion(connector)
        }

        verify(runRepository).markFailed(
            id = any(),
            status = eq(IngestionRunStatus.FAILED),
            errorMessage = any(),
            completedAt = any()
        )
    }

    @Test
    fun `runIngestion continues batch when upsertEvent returns Left (AC1-3)`() = runTest {
        setupRunTracking()
        // Two raw events with distinct titles and different dates to ensure they survive deduplication
        val rawEvents = listOf(
            RawEventDto(
                sourceType = SourceType.TICKETMASTER_API,
                sourceIdentifier = "tm-001",
                title = "Show A",
                venueName = "Black Cat",
                startTime = Instant.parse("2026-03-15T21:00:00Z"),
                confidenceScore = BigDecimal("0.90")
            ),
            RawEventDto(
                sourceType = SourceType.TICKETMASTER_API,
                sourceIdentifier = "tm-002",
                title = "Show B",
                venueName = "Black Cat",
                startTime = Instant.parse("2026-03-16T21:00:00Z"),
                confidenceScore = BigDecimal("0.90")
            )
        )
        val connector = makeConnector { rawEvents.right() }

        // First upsert fails with persistence error, second succeeds
        whenever(eventRepositoryPort.upsertEvent(any())).thenReturn(
            Either.Left(EventError.PersistenceError("DB constraint violation")),
            Either.Right(UpsertResult.Created(UUID.randomUUID()))
        )

        val stats = orchestrator.runIngestion(connector)

        // Second event succeeded, run should have succeeded overall
        assertEquals(2, stats.eventsFetched)
        assertEquals(1, stats.eventsCreated)
        assertEquals(0, stats.eventsUpdated)
        // Both upsert calls should have happened
        verify(eventRepositoryPort, times(2)).upsertEvent(any())
        // Run should be marked successful despite first event failing
        verify(sourceHealthService).recordSuccess(sourceDbId)
    }
}
