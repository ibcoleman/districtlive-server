package com.memetoclasm.districtlive.ingestion.enrichment

import arrow.core.right
import kotlinx.coroutines.runBlocking
import org.junit.jupiter.api.Test
import org.mockito.kotlin.mock
import org.mockito.kotlin.verify
import org.mockito.kotlin.whenever
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty
import kotlin.test.assertEquals
import kotlin.test.assertNotNull

class EnrichmentSchedulerTest {

    @Test
    fun `scheduler delegates to service`() {
        val enrichmentService: ArtistEnrichmentService = mock()
        runBlocking {
            whenever(enrichmentService.enrichBatch()).thenReturn(0.right())
        }

        val scheduler = EnrichmentScheduler(enrichmentService)
        scheduler.runEnrichmentBatch()

        runBlocking {
            verify(enrichmentService).enrichBatch()
        }
    }

    @Test
    fun `scheduler continues after enrichment service throws`() {
        val enrichmentService: ArtistEnrichmentService = mock()
        runBlocking {
            whenever(enrichmentService.enrichBatch()).thenThrow(RuntimeException("test error"))
        }

        val scheduler = EnrichmentScheduler(enrichmentService)
        // Should not throw — the catch block in runEnrichmentBatch swallows the exception
        scheduler.runEnrichmentBatch()

        runBlocking {
            verify(enrichmentService).enrichBatch()
        }
    }

    @Test
    fun `EnrichmentScheduler is gated by enrichment enabled property`() {
        val annotation = EnrichmentScheduler::class.annotations
            .filterIsInstance<ConditionalOnProperty>()
            .firstOrNull()
        assertNotNull(annotation)
        assertEquals(listOf("enrichment.enabled"), annotation!!.name.toList())
        assertEquals("true", annotation.havingValue)
    }
}

