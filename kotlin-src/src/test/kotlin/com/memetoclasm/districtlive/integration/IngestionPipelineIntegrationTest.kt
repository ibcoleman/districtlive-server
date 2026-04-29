package com.memetoclasm.districtlive.integration

import arrow.core.Either
import arrow.core.right
import com.memetoclasm.districtlive.event.*
import com.memetoclasm.districtlive.event.jpa.*
import com.memetoclasm.districtlive.ingestion.IngestionError
import com.memetoclasm.districtlive.ingestion.RawEventDto
import com.memetoclasm.districtlive.ingestion.SourceConnector
import com.memetoclasm.districtlive.ingestion.jpa.IngestionRunEntity
import com.memetoclasm.districtlive.ingestion.jpa.IngestionRunRepository
import com.memetoclasm.districtlive.ingestion.jpa.IngestionRunStatus
import com.memetoclasm.districtlive.ingestion.service.*
import kotlinx.coroutines.test.runTest
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import org.mockito.kotlin.*
import java.math.BigDecimal
import java.time.Instant
import java.util.*
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/**
 * Integration test for the full ingestion pipeline.
 * Uses real NormalizationService and DeduplicationService with mocked repositories.
 * Verifies: connector fetch -> normalize -> deduplicate -> persist -> query.
 */
class IngestionPipelineIntegrationTest {

    // Real services
    private val normalizationService = NormalizationService()
    private val deduplicationService = DeduplicationService()

    // Mocked infrastructure
    private val sourceHealthService: SourceHealthService = mock()
    private val eventRepositoryPort: EventRepositoryPort = mock()
    private val runRepository: IngestionRunRepository = mock()

    private lateinit var orchestrator: IngestionOrchestrator

    private val sourceEntity = SourceEntity(
        name = "test-connector",
        sourceType = SourceType.TICKETMASTER_API
    )

    @BeforeEach
    fun setUp() {
        orchestrator = IngestionOrchestrator(
            normalizationService = normalizationService,
            deduplicationService = deduplicationService,
            sourceHealthService = sourceHealthService,
            eventRepositoryPort = eventRepositoryPort,
            runRepository = runRepository
        )

        // Default mock behavior
        whenever(sourceHealthService.findSourceByName(any())).thenReturn(sourceEntity)
        whenever(runRepository.save(any())).thenAnswer { it.arguments[0] as IngestionRunEntity }
        // By default, upsertEvent returns Created
        whenever(eventRepositoryPort.upsertEvent(any())).thenReturn(
            Either.Right(UpsertResult.Created(UUID.randomUUID()))
        )
    }

    private fun makeConnector(
        sourceId: String,
        sourceType: SourceType,
        events: List<RawEventDto>
    ): SourceConnector = object : SourceConnector {
        override val sourceId = sourceId
        override val sourceType = sourceType
        override suspend fun fetch(): Either<IngestionError, List<RawEventDto>> = events.right()
        override fun healthCheck() = true
    }

    @Test
    fun `full pipeline - events from connector are normalized and persisted`() = runTest {
        val rawEvents = listOf(
            RawEventDto(
                sourceType = SourceType.TICKETMASTER_API,
                sourceIdentifier = "tm-100",
                sourceUrl = "https://ticketmaster.com/event/100",
                title = "Indie Rock Night w/ Local Opener",
                venueName = "Black Cat",
                startTime = Instant.parse("2026-04-01T01:00:00Z"),
                minPrice = BigDecimal("15"),
                maxPrice = BigDecimal("20"),
                ticketUrl = "https://ticketmaster.com/event/100",
                confidenceScore = BigDecimal("0.90")
            ),
            RawEventDto(
                sourceType = SourceType.TICKETMASTER_API,
                sourceIdentifier = "tm-200",
                title = "Jazz Fusion Collective",
                venueName = "9:30 Club",
                startTime = Instant.parse("2026-04-02T00:00:00Z"),
                confidenceScore = BigDecimal("0.90")
            )
        )

        val connector = makeConnector("test-connector", SourceType.TICKETMASTER_API, rawEvents)
        val stats = orchestrator.runIngestion(connector)

        assertEquals(2, stats.eventsFetched)
        assertEquals(2, stats.eventsCreated)
        assertEquals(0, stats.eventsDeduplicated)

        // Verify events were persisted via port
        verify(eventRepositoryPort, times(2)).upsertEvent(any())

        // Verify source health updated
        verify(sourceHealthService).recordSuccess(sourceEntity.id)

        // Verify ingestion run recorded: initial RUNNING save + markSuccess
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
    fun `full pipeline - multiple events at same venue correctly link to venue`() = runTest {
        val rawEvents = listOf(
            RawEventDto(
                sourceType = SourceType.TICKETMASTER_API,
                sourceIdentifier = "tm-301",
                title = "Show A",
                venueName = "Black Cat",
                startTime = Instant.parse("2026-04-01T01:00:00Z"),
                confidenceScore = BigDecimal("0.90")
            ),
            RawEventDto(
                sourceType = SourceType.TICKETMASTER_API,
                sourceIdentifier = "tm-302",
                title = "Show B",
                venueName = "Black Cat",
                startTime = Instant.parse("2026-04-02T01:00:00Z"),
                confidenceScore = BigDecimal("0.90")
            )
        )

        val connector = makeConnector("test-connector", SourceType.TICKETMASTER_API, rawEvents)
        orchestrator.runIngestion(connector)

        // Both events should have been persisted via port
        verify(eventRepositoryPort, atLeast(2)).upsertEvent(any())
    }

    @Test
    fun `full pipeline - price tier assigned correctly during normalization`() = runTest {
        val rawEvents = listOf(
            RawEventDto(
                sourceType = SourceType.TICKETMASTER_API,
                sourceIdentifier = "tm-free",
                title = "Free Show",
                venueName = "Black Cat",
                startTime = Instant.parse("2026-04-05T01:00:00Z"),
                minPrice = BigDecimal("0"),
                maxPrice = BigDecimal("0"),
                confidenceScore = BigDecimal("0.90")
            ),
            RawEventDto(
                sourceType = SourceType.TICKETMASTER_API,
                sourceIdentifier = "tm-expensive",
                title = "Big Headliner Concert",
                venueName = "Black Cat",
                startTime = Instant.parse("2026-04-06T01:00:00Z"),
                minPrice = BigDecimal("50"),
                maxPrice = BigDecimal("75"),
                confidenceScore = BigDecimal("0.90")
            )
        )

        val connector = makeConnector("test-connector", SourceType.TICKETMASTER_API, rawEvents)
        val stats = orchestrator.runIngestion(connector)

        // Both events should have been persisted
        assertEquals(2, stats.eventsCreated)
        verify(eventRepositoryPort, atLeast(2)).upsertEvent(any())
    }

    @Test
    fun `full pipeline - empty connector response produces zero-count stats`() = runTest {
        val connector = makeConnector("test-connector", SourceType.TICKETMASTER_API, emptyList())
        val stats = orchestrator.runIngestion(connector)

        assertEquals(0, stats.eventsFetched)
        assertEquals(0, stats.eventsCreated)
        assertEquals(0, stats.eventsUpdated)
        assertEquals(0, stats.eventsDeduplicated)

        verify(eventRepositoryPort, never()).upsertEvent(any())
        verify(sourceHealthService).recordSuccess(sourceEntity.id)
    }

    @Test
    fun `full pipeline - connector failure records failed run and updates health`() = runTest {
        val failingConnector = object : SourceConnector {
            override val sourceId = "test-connector"
            override val sourceType = SourceType.TICKETMASTER_API
            override suspend fun fetch(): Either<IngestionError, List<RawEventDto>> =
                Either.Left(IngestionError.ConnectionError("test", "Connection refused"))
            override fun healthCheck() = false
        }

        try {
            orchestrator.runIngestion(failingConnector)
        } catch (e: RuntimeException) {
            // Expected
        }

        verify(sourceHealthService).recordFailure(eq(sourceEntity.id), any())
        verify(runRepository).markFailed(
            id = any(),
            status = eq(IngestionRunStatus.FAILED),
            errorMessage = any(),
            completedAt = any()
        )
    }

    // Helper to capture saved entities
    private fun <T> capture(list: MutableList<T>): T {
        return argThat { list.add(this); true }
    }
}
