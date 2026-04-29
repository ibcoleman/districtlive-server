package com.memetoclasm.districtlive.integration

import arrow.core.Either
import arrow.core.left
import arrow.core.right
import com.memetoclasm.districtlive.event.*
import com.memetoclasm.districtlive.event.jpa.*
import com.memetoclasm.districtlive.ingestion.IngestionError
import com.memetoclasm.districtlive.ingestion.NotificationPort
import com.memetoclasm.districtlive.ingestion.RawEventDto
import com.memetoclasm.districtlive.ingestion.SourceConnector
import com.memetoclasm.districtlive.ingestion.jpa.IngestionRunEntity
import com.memetoclasm.districtlive.ingestion.jpa.IngestionRunRepository
import com.memetoclasm.districtlive.ingestion.jpa.IngestionRunStatus
import com.memetoclasm.districtlive.ingestion.service.*
import kotlinx.coroutines.test.runTest
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.assertThrows
import org.mockito.kotlin.*
import java.math.BigDecimal
import java.time.Instant
import java.util.*
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

/**
 * Integration tests for error handling and source health tracking.
 * Verifies: health tracking lifecycle, malformed response handling,
 * connection failures, and graceful degradation.
 */
class ErrorHandlingIntegrationTest {

    private val sourceRepository: JpaSourceRepository = mock()
    private val notificationPort: NotificationPort = mock()
    private lateinit var healthService: SourceHealthService

    @BeforeEach
    fun setUp() {
        healthService = SourceHealthService(sourceRepository, notificationPort)
    }

    // AC4.1: Successful ingestion resets consecutive failure count to 0
    @Test
    fun `AC4_1 - success resets failure count`() {
        val sourceId = UUID.randomUUID()
        val source = SourceEntity(
            id = sourceId,
            name = "test-source",
            sourceType = SourceType.TICKETMASTER_API,
            consecutiveFailures = 2,
            healthy = true
        )
        whenever(sourceRepository.findById(sourceId)).thenReturn(Optional.of(source))
        whenever(sourceRepository.save(any())).thenAnswer { it.arguments[0] }

        healthService.recordSuccess(sourceId)

        verify(sourceRepository).save(argThat<SourceEntity> {
            consecutiveFailures == 0 && healthy
        })
    }

    // AC4.2: Failed ingestion increments consecutive failure count
    @Test
    fun `AC4_2 - failure increments count`() {
        val sourceId = UUID.randomUUID()
        val source = SourceEntity(
            id = sourceId,
            name = "test-source",
            sourceType = SourceType.TICKETMASTER_API,
            consecutiveFailures = 0,
            healthy = true
        )
        whenever(sourceRepository.findById(sourceId)).thenReturn(Optional.of(source))
        whenever(sourceRepository.save(any())).thenAnswer { it.arguments[0] }

        healthService.recordFailure(sourceId, "Timeout")

        verify(sourceRepository).save(argThat<SourceEntity> {
            consecutiveFailures == 1 && healthy
        })
    }

    // AC4.3: Source marked unhealthy after 3 consecutive failures
    @Test
    fun `AC4_3 - unhealthy after 3 consecutive failures`() {
        val sourceId = UUID.randomUUID()
        val source = SourceEntity(
            id = sourceId,
            name = "test-source",
            sourceType = SourceType.TICKETMASTER_API,
            consecutiveFailures = 2,
            healthy = true
        )
        whenever(sourceRepository.findById(sourceId)).thenReturn(Optional.of(source))
        whenever(sourceRepository.save(any())).thenAnswer { it.arguments[0] }

        healthService.recordFailure(sourceId, "Connection refused")

        verify(sourceRepository).save(argThat<SourceEntity> {
            consecutiveFailures == 3 && !healthy
        })
    }

    // Full health lifecycle: healthy -> 3 failures -> unhealthy -> success -> healthy
    @Test
    fun `health lifecycle - failure accumulation and success recovery`() {
        val sourceId = UUID.randomUUID()
        var currentSource = SourceEntity(
            id = sourceId,
            name = "test-source",
            sourceType = SourceType.TICKETMASTER_API,
            consecutiveFailures = 0,
            healthy = true
        )

        whenever(sourceRepository.findById(sourceId)).thenAnswer { Optional.of(currentSource) }
        whenever(sourceRepository.save(any())).thenAnswer {
            currentSource = it.arguments[0] as SourceEntity
            currentSource
        }

        // 3 failures
        healthService.recordFailure(sourceId, "Error 1")
        assertEquals(1, currentSource.consecutiveFailures)
        assertTrue(currentSource.healthy)

        healthService.recordFailure(sourceId, "Error 2")
        assertEquals(2, currentSource.consecutiveFailures)
        assertTrue(currentSource.healthy)

        healthService.recordFailure(sourceId, "Error 3")
        assertEquals(3, currentSource.consecutiveFailures)
        assertFalse(currentSource.healthy)

        // Success recovery
        healthService.recordSuccess(sourceId)
        assertEquals(0, currentSource.consecutiveFailures)
        assertTrue(currentSource.healthy)
    }

    // Error handling: malformed events are skipped gracefully
    @Test
    fun `pipeline skips malformed events and succeeds`() = runTest {
        val normalizationService = NormalizationService()
        val deduplicationService = DeduplicationService()
        val sourceHealthService: SourceHealthService = mock()
        val eventRepositoryPort: EventRepositoryPort = mock()
        val runRepository: IngestionRunRepository = mock()

        whenever(eventRepositoryPort.upsertEvent(any())).thenReturn(
            Either.Right(UpsertResult.Created(UUID.randomUUID()))
        )

        val orchestrator = IngestionOrchestrator(
            normalizationService, deduplicationService, sourceHealthService,
            eventRepositoryPort, runRepository
        )

        val source = SourceEntity(name = "bad-source", sourceType = SourceType.VENUE_SCRAPER)
        whenever(sourceHealthService.findSourceByName(any())).thenReturn(source)
        whenever(runRepository.save(any())).thenAnswer { it.arguments[0] as IngestionRunEntity }

        // Event with missing startTime (required field) — will be skipped during normalization
        val malformedEvents = listOf(
            RawEventDto(
                sourceType = SourceType.VENUE_SCRAPER,
                sourceIdentifier = "bad-1",
                title = "Event With No Time",
                startTime = null, // Missing required field
                confidenceScore = BigDecimal("0.70")
            )
        )

        val connector = object : SourceConnector {
            override val sourceId = "bad-source"
            override val sourceType = SourceType.VENUE_SCRAPER
            override suspend fun fetch() = malformedEvents.right()
            override fun healthCheck() = true
        }

        // Should succeed — malformed events are skipped, not fatal
        val stats = orchestrator.runIngestion(connector)
        assertEquals(1, stats.eventsFetched)
        assertEquals(0, stats.eventsCreated)

        // Health should record success since the pipeline didn't fail
        verify(sourceHealthService).recordSuccess(source.id)
    }

    // Error handling: connection error from connector
    @Test
    fun `pipeline handles connection error from connector`() = runTest {
        val normalizationService = NormalizationService()
        val deduplicationService = DeduplicationService()
        val sourceHealthService: SourceHealthService = mock()
        val eventRepositoryPort: EventRepositoryPort = mock()
        val runRepository: IngestionRunRepository = mock()

        val orchestrator = IngestionOrchestrator(
            normalizationService, deduplicationService, sourceHealthService,
            eventRepositoryPort, runRepository
        )

        val source = SourceEntity(name = "unreachable", sourceType = SourceType.VENUE_SCRAPER)
        whenever(sourceHealthService.findSourceByName(any())).thenReturn(source)
        whenever(runRepository.save(any())).thenAnswer { it.arguments[0] as IngestionRunEntity }

        val connector = object : SourceConnector {
            override val sourceId = "unreachable"
            override val sourceType = SourceType.VENUE_SCRAPER
            override suspend fun fetch(): Either<IngestionError, List<RawEventDto>> =
                IngestionError.ConnectionError("unreachable", "DNS resolution failed").left()
            override fun healthCheck() = false
        }

        assertThrows<RuntimeException> {
            orchestrator.runIngestion(connector)
        }

        verify(sourceHealthService).recordFailure(eq(source.id), any())
        verify(runRepository).markFailed(
            id = any(),
            status = eq(IngestionRunStatus.FAILED),
            errorMessage = any(),
            completedAt = any()
        )
    }

    // Error handling: rate limited connector
    @Test
    fun `pipeline handles rate limited connector`() = runTest {
        val normalizationService = NormalizationService()
        val deduplicationService = DeduplicationService()
        val sourceHealthService: SourceHealthService = mock()
        val eventRepositoryPort: EventRepositoryPort = mock()
        val runRepository: IngestionRunRepository = mock()

        val orchestrator = IngestionOrchestrator(
            normalizationService, deduplicationService, sourceHealthService,
            eventRepositoryPort, runRepository
        )

        val source = SourceEntity(name = "rate-limited", sourceType = SourceType.TICKETMASTER_API)
        whenever(sourceHealthService.findSourceByName(any())).thenReturn(source)
        whenever(runRepository.save(any())).thenAnswer { it.arguments[0] as IngestionRunEntity }

        val connector = object : SourceConnector {
            override val sourceId = "rate-limited"
            override val sourceType = SourceType.TICKETMASTER_API
            override suspend fun fetch(): Either<IngestionError, List<RawEventDto>> =
                IngestionError.RateLimited(retryAfterSeconds = 60).left()
            override fun healthCheck() = true
        }

        assertThrows<RuntimeException> {
            orchestrator.runIngestion(connector)
        }
    }
}
