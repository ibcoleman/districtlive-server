package com.memetoclasm.districtlive.ingestion.service

import com.memetoclasm.districtlive.event.SourceType
import com.memetoclasm.districtlive.event.jpa.JpaSourceRepository
import com.memetoclasm.districtlive.event.jpa.SourceEntity
import com.memetoclasm.districtlive.ingestion.NotificationPort
import org.junit.jupiter.api.Test
import org.mockito.kotlin.*
import java.time.Instant
import java.util.*
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class SourceHealthServiceTest {

    private val sourceRepository: JpaSourceRepository = mock()
    private val notificationPort: NotificationPort = mock()
    private val service = SourceHealthService(sourceRepository, notificationPort)

    private fun makeSource(
        id: UUID = UUID.randomUUID(),
        name: String = "test-source",
        consecutiveFailures: Int = 0,
        healthy: Boolean = true
    ) = SourceEntity(
        id = id,
        name = name,
        sourceType = SourceType.TICKETMASTER_API,
        consecutiveFailures = consecutiveFailures,
        healthy = healthy,
        lastSuccessAt = Instant.now()
    )

    @Test
    fun `recordSuccess resets consecutive failures to 0 and marks healthy`() {
        val sourceId = UUID.randomUUID()
        val source = makeSource(id = sourceId, consecutiveFailures = 2, healthy = false)
        whenever(sourceRepository.findById(sourceId)).thenReturn(Optional.of(source))
        whenever(sourceRepository.save(any())).thenAnswer { it.arguments[0] }

        service.recordSuccess(sourceId)

        verify(sourceRepository).save(argThat<SourceEntity> {
            consecutiveFailures == 0 && healthy
        })
    }

    @Test
    fun `recordFailure increments consecutive failure count`() {
        val sourceId = UUID.randomUUID()
        val source = makeSource(id = sourceId, consecutiveFailures = 0)
        whenever(sourceRepository.findById(sourceId)).thenReturn(Optional.of(source))
        whenever(sourceRepository.save(any())).thenAnswer { it.arguments[0] }

        service.recordFailure(sourceId, "Connection timeout")

        verify(sourceRepository).save(argThat<SourceEntity> {
            consecutiveFailures == 1 && healthy
        })
    }

    @Test
    fun `recordFailure marks unhealthy after 3 consecutive failures`() {
        val sourceId = UUID.randomUUID()
        val source = makeSource(id = sourceId, consecutiveFailures = 2)
        whenever(sourceRepository.findById(sourceId)).thenReturn(Optional.of(source))
        whenever(sourceRepository.save(any())).thenAnswer { it.arguments[0] }

        service.recordFailure(sourceId, "Connection timeout")

        verify(sourceRepository).save(argThat<SourceEntity> {
            consecutiveFailures == 3 && !healthy
        })
    }

    @Test
    fun `recordFailure keeps healthy below threshold`() {
        val sourceId = UUID.randomUUID()
        val source = makeSource(id = sourceId, consecutiveFailures = 1)
        whenever(sourceRepository.findById(sourceId)).thenReturn(Optional.of(source))
        whenever(sourceRepository.save(any())).thenAnswer { it.arguments[0] }

        service.recordFailure(sourceId, "Timeout")

        verify(sourceRepository).save(argThat<SourceEntity> {
            consecutiveFailures == 2 && healthy
        })
    }

    @Test
    fun `recordSuccess with unknown sourceId does not throw`() {
        val unknownId = UUID.randomUUID()
        whenever(sourceRepository.findById(unknownId)).thenReturn(Optional.empty())

        service.recordSuccess(unknownId)

        verify(sourceRepository, never()).save(any())
    }

    @Test
    fun `recordFailure with unknown sourceId does not throw`() {
        val unknownId = UUID.randomUUID()
        whenever(sourceRepository.findById(unknownId)).thenReturn(Optional.empty())

        service.recordFailure(unknownId, "error")

        verify(sourceRepository, never()).save(any())
    }

    @Test
    fun `isHealthy returns true for healthy source`() {
        val sourceId = UUID.randomUUID()
        val source = makeSource(id = sourceId, healthy = true)
        whenever(sourceRepository.findById(sourceId)).thenReturn(Optional.of(source))

        assertTrue(service.isHealthy(sourceId))
    }

    @Test
    fun `isHealthy returns false for unhealthy source`() {
        val sourceId = UUID.randomUUID()
        val source = makeSource(id = sourceId, healthy = false)
        whenever(sourceRepository.findById(sourceId)).thenReturn(Optional.of(source))

        assertFalse(service.isHealthy(sourceId))
    }

    @Test
    fun `isHealthy returns false for unknown sourceId`() {
        val unknownId = UUID.randomUUID()
        whenever(sourceRepository.findById(unknownId)).thenReturn(Optional.empty())

        assertFalse(service.isHealthy(unknownId))
    }

    @Test
    fun `getHealthySourceIds delegates to repository`() {
        val s1 = makeSource(name = "source-1", healthy = true)
        val s2 = makeSource(name = "source-2", healthy = true)
        whenever(sourceRepository.findByHealthyTrue()).thenReturn(listOf(s1, s2))

        val ids = service.getHealthySourceIds()

        assertEquals(2, ids.size)
    }

    @Test
    fun `findSourceByName delegates to repository`() {
        val source = makeSource(name = "ticketmaster")
        whenever(sourceRepository.findByName("ticketmaster")).thenReturn(source)

        val result = service.findSourceByName("ticketmaster")

        assertEquals("ticketmaster", result?.name)
    }

    // Notification integration tests (AC3.1, AC3.2)

    @Test
    fun `recordFailure on 3rd failure triggers notifySourceUnhealthy notification`() {
        val sourceId = UUID.randomUUID()
        val source = makeSource(id = sourceId, name = "ticketmaster", consecutiveFailures = 2, healthy = true)
        whenever(sourceRepository.findById(sourceId)).thenReturn(Optional.of(source))
        whenever(sourceRepository.save(any())).thenAnswer { it.arguments[0] }

        service.recordFailure(sourceId, "Connection refused")

        verify(sourceRepository).save(argThat<SourceEntity> {
            consecutiveFailures == 3 && !healthy
        })
        verify(notificationPort).notifySourceUnhealthy("ticketmaster", 3, "Connection refused")
    }

    @Test
    fun `recordFailure on 4th failure does NOT trigger notification (already unhealthy)`() {
        val sourceId = UUID.randomUUID()
        val source = makeSource(id = sourceId, name = "ticketmaster", consecutiveFailures = 3, healthy = false)
        whenever(sourceRepository.findById(sourceId)).thenReturn(Optional.of(source))
        whenever(sourceRepository.save(any())).thenAnswer { it.arguments[0] }

        service.recordFailure(sourceId, "Timeout")

        verify(sourceRepository).save(argThat<SourceEntity> {
            consecutiveFailures == 4 && !healthy
        })
        verify(notificationPort, never()).notifySourceUnhealthy(any(), any(), any())
    }

    @Test
    fun `recordSuccess on unhealthy source triggers notifySourceRecovered notification`() {
        val sourceId = UUID.randomUUID()
        val source = makeSource(id = sourceId, name = "ticketmaster", consecutiveFailures = 3, healthy = false)
        whenever(sourceRepository.findById(sourceId)).thenReturn(Optional.of(source))
        whenever(sourceRepository.save(any())).thenAnswer { it.arguments[0] }

        service.recordSuccess(sourceId)

        verify(sourceRepository).save(argThat<SourceEntity> {
            consecutiveFailures == 0 && healthy
        })
        verify(notificationPort).notifySourceRecovered("ticketmaster")
    }

    @Test
    fun `recordSuccess on healthy source does NOT trigger notification`() {
        val sourceId = UUID.randomUUID()
        val source = makeSource(id = sourceId, name = "ticketmaster", consecutiveFailures = 0, healthy = true)
        whenever(sourceRepository.findById(sourceId)).thenReturn(Optional.of(source))
        whenever(sourceRepository.save(any())).thenAnswer { it.arguments[0] }

        service.recordSuccess(sourceId)

        verify(sourceRepository).save(argThat<SourceEntity> {
            consecutiveFailures == 0 && healthy
        })
        verify(notificationPort, never()).notifySourceRecovered(any())
    }

    @Test
    fun `recordFailure below threshold does NOT trigger notification`() {
        val sourceId = UUID.randomUUID()
        val source = makeSource(id = sourceId, name = "ticketmaster", consecutiveFailures = 0, healthy = true)
        whenever(sourceRepository.findById(sourceId)).thenReturn(Optional.of(source))
        whenever(sourceRepository.save(any())).thenAnswer { it.arguments[0] }

        service.recordFailure(sourceId, "Error 1")

        verify(sourceRepository).save(argThat<SourceEntity> {
            consecutiveFailures == 1 && healthy
        })
        verify(notificationPort, never()).notifySourceUnhealthy(any(), any(), any())

        // Reset mock for second failure
        reset(sourceRepository)
        val source2 = makeSource(id = sourceId, name = "ticketmaster", consecutiveFailures = 1, healthy = true)
        whenever(sourceRepository.findById(sourceId)).thenReturn(Optional.of(source2))
        whenever(sourceRepository.save(any())).thenAnswer { it.arguments[0] }

        service.recordFailure(sourceId, "Error 2")

        verify(sourceRepository).save(argThat<SourceEntity> {
            consecutiveFailures == 2 && healthy
        })
        verify(notificationPort, never()).notifySourceUnhealthy(any(), any(), any())
    }
}
