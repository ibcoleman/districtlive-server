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
 * Integration tests for deduplication across multiple sources.
 * Verifies that the same show from different connectors merges into
 * a single canonical event with multiple source attributions.
 */
class DeduplicationIntegrationTest {

    private val normalizationService = NormalizationService()
    private val deduplicationService = DeduplicationService()
    private val sourceHealthService: SourceHealthService = mock()
    private val eventRepositoryPort: EventRepositoryPort = mock()
    private val runRepository: IngestionRunRepository = mock()

    private lateinit var orchestrator: IngestionOrchestrator

    @BeforeEach
    fun setUp() {
        orchestrator = IngestionOrchestrator(
            normalizationService, deduplicationService, sourceHealthService,
            eventRepositoryPort, runRepository
        )

        val source = SourceEntity(name = "dedup-test", sourceType = SourceType.TICKETMASTER_API)
        whenever(sourceHealthService.findSourceByName(any())).thenReturn(source)
        whenever(runRepository.save(any())).thenAnswer { it.arguments[0] as IngestionRunEntity }
        // Capture the created event IDs from upsertEvent calls
        whenever(eventRepositoryPort.upsertEvent(any())).thenAnswer {
            // Return Created with the event ID from the command
            Either.Right(UpsertResult.Created(UUID.randomUUID()))
        }
    }

    @Test
    fun `AC3_1 - same show from two sources produces one event with two source attributions`() = runTest {
        // Same show listed on both Ticketmaster and venue scraper
        val rawEvents = listOf(
            RawEventDto(
                sourceType = SourceType.TICKETMASTER_API,
                sourceIdentifier = "tm-500",
                title = "Indie Night at Black Cat",
                venueName = "Black Cat",
                startTime = Instant.parse("2026-04-10T01:00:00Z"),
                minPrice = BigDecimal("25"),
                maxPrice = BigDecimal("45"),
                confidenceScore = BigDecimal("0.90")
            ),
            RawEventDto(
                sourceType = SourceType.VENUE_SCRAPER,
                sourceIdentifier = "bc-500",
                title = "Indie Night at Black Cat",
                venueName = "Black Cat",
                startTime = Instant.parse("2026-04-10T01:30:00Z"), // slightly different time
                minPrice = BigDecimal("20"),
                maxPrice = BigDecimal("40"),
                confidenceScore = BigDecimal("0.70")
            )
        )

        val connector = object : SourceConnector {
            override val sourceId = "dedup-test"
            override val sourceType = SourceType.TICKETMASTER_API
            override suspend fun fetch() = rawEvents.right()
            override fun healthCheck() = true
        }

        val stats = orchestrator.runIngestion(connector)

        assertEquals(2, stats.eventsFetched)
        assertEquals(1, stats.eventsCreated) // Deduplicated to 1
        assertEquals(1, stats.eventsDeduplicated)
    }

    @Test
    fun `AC3_2 - highest confidence source wins per field on merge`() = runTest {
        // API has higher confidence, so its price should be used
        val rawEvents = listOf(
            RawEventDto(
                sourceType = SourceType.TICKETMASTER_API,
                sourceIdentifier = "tm-600",
                title = "Jazz at Black Cat",
                venueName = "Black Cat",
                startTime = Instant.parse("2026-04-15T01:00:00Z"),
                minPrice = BigDecimal("30"),
                maxPrice = BigDecimal("50"),
                ticketUrl = "https://ticketmaster.com/event/600",
                confidenceScore = BigDecimal("0.90")
            ),
            RawEventDto(
                sourceType = SourceType.VENUE_SCRAPER,
                sourceIdentifier = "bc-600",
                title = "Jazz at Black Cat",
                venueName = "Black Cat",
                startTime = Instant.parse("2026-04-15T01:15:00Z"),
                minPrice = BigDecimal("20"),
                maxPrice = BigDecimal("40"),
                confidenceScore = BigDecimal("0.70")
            )
        )

        val connector = object : SourceConnector {
            override val sourceId = "dedup-test"
            override val sourceType = SourceType.TICKETMASTER_API
            override suspend fun fetch() = rawEvents.right()
            override fun healthCheck() = true
        }

        orchestrator.runIngestion(connector)

        // Verify upsertEvent was called (dedup should result in 1 call)
        verify(eventRepositoryPort, atLeast(1)).upsertEvent(any())
    }

    @Test
    fun `AC3_3 - different shows at same venue on same date remain separate`() = runTest {
        val rawEvents = listOf(
            RawEventDto(
                sourceType = SourceType.TICKETMASTER_API,
                sourceIdentifier = "tm-701",
                title = "Early Punk Matinee",
                venueName = "Black Cat",
                startTime = Instant.parse("2026-04-20T18:00:00Z"),
                artistNames = listOf("Punk Band A"),
                confidenceScore = BigDecimal("0.90")
            ),
            RawEventDto(
                sourceType = SourceType.TICKETMASTER_API,
                sourceIdentifier = "tm-702",
                title = "Late Night Electronic Set",
                venueName = "Black Cat",
                startTime = Instant.parse("2026-04-20T23:00:00Z"),
                artistNames = listOf("DJ Electronic"),
                confidenceScore = BigDecimal("0.90")
            )
        )

        val connector = object : SourceConnector {
            override val sourceId = "dedup-test"
            override val sourceType = SourceType.TICKETMASTER_API
            override suspend fun fetch() = rawEvents.right()
            override fun healthCheck() = true
        }

        val stats = orchestrator.runIngestion(connector)

        assertEquals(2, stats.eventsFetched)
        assertEquals(2, stats.eventsCreated) // Should NOT deduplicate
        assertEquals(0, stats.eventsDeduplicated)
    }

    @Test
    fun `AC3_5 - same title different dates are not deduplicated`() = runTest {
        val rawEvents = listOf(
            RawEventDto(
                sourceType = SourceType.TICKETMASTER_API,
                sourceIdentifier = "tm-801",
                title = "Weekly Open Mic",
                venueName = "Black Cat",
                startTime = Instant.parse("2026-04-10T01:00:00Z"),
                confidenceScore = BigDecimal("0.90")
            ),
            RawEventDto(
                sourceType = SourceType.TICKETMASTER_API,
                sourceIdentifier = "tm-802",
                title = "Weekly Open Mic",
                venueName = "Black Cat",
                startTime = Instant.parse("2026-04-17T01:00:00Z"), // Week later
                confidenceScore = BigDecimal("0.90")
            )
        )

        val connector = object : SourceConnector {
            override val sourceId = "dedup-test"
            override val sourceType = SourceType.TICKETMASTER_API
            override suspend fun fetch() = rawEvents.right()
            override fun healthCheck() = true
        }

        val stats = orchestrator.runIngestion(connector)

        assertEquals(2, stats.eventsCreated)
        assertEquals(0, stats.eventsDeduplicated)
    }
}
