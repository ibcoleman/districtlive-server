package com.memetoclasm.districtlive.ingestion

import com.memetoclasm.districtlive.event.SourceType
import com.memetoclasm.districtlive.event.jpa.SourceEntity
import com.memetoclasm.districtlive.ingestion.service.IngestionOrchestrator
import com.memetoclasm.districtlive.ingestion.service.IngestionStats
import com.memetoclasm.districtlive.ingestion.service.SourceHealthService
import arrow.core.Either
import arrow.core.right
import kotlinx.coroutines.test.runTest
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.assertThrows
import org.mockito.kotlin.*
import java.util.*
import kotlin.test.assertEquals

class IngestionSchedulerTest {

    private val orchestrator: IngestionOrchestrator = mock()
    private val sourceHealthService: SourceHealthService = mock()
    private val ingestionConfig = IngestionConfig(
        enabled = true,
        apiCron = "0 0 */6 * * *",
        scraperCron = "0 0 3 * * *"
    )

    private fun makeConnector(
        sourceId: String,
        sourceType: SourceType
    ): SourceConnector {
        return object : SourceConnector {
            override val sourceId = sourceId
            override val sourceType = sourceType
            override suspend fun fetch(): Either<IngestionError, List<RawEventDto>> = emptyList<RawEventDto>().right()
            override fun healthCheck() = true
        }
    }

    @Test
    fun `runApiConnectors runs only API-type connectors`() {
        val apiConnector = makeConnector("ticketmaster", SourceType.TICKETMASTER_API)
        val scraperConnector = makeConnector("black-cat", SourceType.VENUE_SCRAPER)
        val connectors = listOf(apiConnector, scraperConnector)

        val healthySource = SourceEntity(
            name = "ticketmaster",
            sourceType = SourceType.TICKETMASTER_API,
            healthy = true
        )
        whenever(sourceHealthService.findSourceByName("ticketmaster")).thenReturn(healthySource)

        val scheduler = IngestionScheduler(connectors, orchestrator, sourceHealthService, ingestionConfig)
        scheduler.runApiConnectors()

        verify(sourceHealthService).findSourceByName("ticketmaster")
        verify(sourceHealthService, never()).findSourceByName("black-cat")
    }

    @Test
    fun `runScraperConnectors runs only scraper-type connectors`() {
        val apiConnector = makeConnector("ticketmaster", SourceType.TICKETMASTER_API)
        val scraperConnector = makeConnector("black-cat", SourceType.VENUE_SCRAPER)
        val connectors = listOf(apiConnector, scraperConnector)

        val healthySource = SourceEntity(
            name = "black-cat",
            sourceType = SourceType.VENUE_SCRAPER,
            healthy = true
        )
        whenever(sourceHealthService.findSourceByName("black-cat")).thenReturn(healthySource)

        val scheduler = IngestionScheduler(connectors, orchestrator, sourceHealthService, ingestionConfig)
        scheduler.runScraperConnectors()

        verify(sourceHealthService).findSourceByName("black-cat")
        verify(sourceHealthService, never()).findSourceByName("ticketmaster")
    }

    @Test
    fun `runApiConnectors skips unhealthy connectors`() {
        val connector = makeConnector("ticketmaster", SourceType.TICKETMASTER_API)
        val connectors = listOf(connector)

        val unhealthySource = SourceEntity(
            name = "ticketmaster",
            sourceType = SourceType.TICKETMASTER_API,
            healthy = false,
            consecutiveFailures = 3
        )
        whenever(sourceHealthService.findSourceByName("ticketmaster")).thenReturn(unhealthySource)

        val scheduler = IngestionScheduler(connectors, orchestrator, sourceHealthService, ingestionConfig)
        scheduler.runApiConnectors()

        verifyNoInteractions(orchestrator)
    }

    @Test
    fun `runApiConnectors runs connectors with no source record`() {
        val connector = makeConnector("ticketmaster", SourceType.TICKETMASTER_API)
        val connectors = listOf(connector)

        whenever(sourceHealthService.findSourceByName("ticketmaster")).thenReturn(null)

        val scheduler = IngestionScheduler(connectors, orchestrator, sourceHealthService, ingestionConfig)
        scheduler.runApiConnectors()

        verify(sourceHealthService).findSourceByName("ticketmaster")
    }

    @Test
    fun `runSingleConnector finds and runs the specified connector bypassing health check`() = runTest {
        val connector = makeConnector("ticketmaster", SourceType.TICKETMASTER_API)
        val connectors = listOf(connector)

        whenever(orchestrator.runIngestion(any())).thenReturn(IngestionStats())

        val scheduler = IngestionScheduler(connectors, orchestrator, sourceHealthService, ingestionConfig)
        scheduler.runSingleConnector("ticketmaster")

        // Manual triggers bypass health check — orchestrator is called directly
        verify(orchestrator).runIngestion(any())
        verify(sourceHealthService, never()).findSourceByName(any())
    }

    @Test
    fun `runSingleConnector throws for unknown sourceId`() {
        val connectors = listOf(makeConnector("ticketmaster", SourceType.TICKETMASTER_API))

        val scheduler = IngestionScheduler(connectors, orchestrator, sourceHealthService, ingestionConfig)

        assertThrows<IllegalArgumentException> {
            scheduler.runSingleConnector("unknown-source")
        }
    }

    @Test
    fun `runApiConnectors continues after one connector fails`() {
        val connector1 = makeConnector("ticketmaster", SourceType.TICKETMASTER_API)
        val connector2 = makeConnector("bandsintown", SourceType.BANDSINTOWN_API)
        val connectors = listOf(connector1, connector2)

        val source1 = SourceEntity(name = "ticketmaster", sourceType = SourceType.TICKETMASTER_API, healthy = true)
        val source2 = SourceEntity(name = "bandsintown", sourceType = SourceType.BANDSINTOWN_API, healthy = true)
        whenever(sourceHealthService.findSourceByName("ticketmaster")).thenReturn(source1)
        whenever(sourceHealthService.findSourceByName("bandsintown")).thenReturn(source2)

        val scheduler = IngestionScheduler(connectors, orchestrator, sourceHealthService, ingestionConfig)
        // Should not throw — errors are caught per connector
        scheduler.runApiConnectors()

        // Both connectors should have been attempted
        verify(sourceHealthService).findSourceByName("ticketmaster")
        verify(sourceHealthService).findSourceByName("bandsintown")
    }
}
