package com.memetoclasm.districtlive.ingestion.service

import com.memetoclasm.districtlive.event.jpa.JpaSourceRepository
import com.memetoclasm.districtlive.event.jpa.SourceEntity
import com.memetoclasm.districtlive.ingestion.NotificationPort
import org.slf4j.LoggerFactory
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Transactional
import java.time.Instant
import java.util.UUID

@Service
class SourceHealthService(
    private val sourceRepository: JpaSourceRepository,
    private val notificationPort: NotificationPort
) {

    private val logger = LoggerFactory.getLogger(SourceHealthService::class.java)

    companion object {
        const val UNHEALTHY_THRESHOLD = 3
    }

    @Transactional
    fun recordSuccess(sourceId: UUID) {
        val source = sourceRepository.findById(sourceId).orElse(null) ?: run {
            logger.warn("Source not found for id={}", sourceId)
            return
        }

        val wasUnhealthy = !source.healthy

        source.lastSuccessAt = Instant.now()
        source.consecutiveFailures = 0
        source.healthy = true
        source.updatedAt = Instant.now()
        sourceRepository.save(source)
        logger.info("Source '{}' ingestion succeeded, health reset", source.name)

        if (wasUnhealthy) {
            notificationPort.notifySourceRecovered(source.name)
        }
    }

    @Transactional
    fun recordFailure(sourceId: UUID, errorMessage: String?) {
        val source = sourceRepository.findById(sourceId).orElse(null) ?: run {
            logger.warn("Source not found for id={}", sourceId)
            return
        }

        val wasHealthy = source.healthy

        source.consecutiveFailures += 1
        source.lastFailureAt = Instant.now()
        source.healthy = source.consecutiveFailures < UNHEALTHY_THRESHOLD
        source.updatedAt = Instant.now()
        sourceRepository.save(source)

        if (!source.healthy) {
            logger.error(
                "Source '{}' marked UNHEALTHY after {} consecutive failures. Last error: {}",
                source.name, source.consecutiveFailures, errorMessage
            )
            if (wasHealthy) {
                notificationPort.notifySourceUnhealthy(source.name, source.consecutiveFailures, errorMessage)
            }
        } else {
            logger.warn(
                "Source '{}' ingestion failed ({}/{} failures). Error: {}",
                source.name, source.consecutiveFailures, UNHEALTHY_THRESHOLD, errorMessage
            )
        }
    }

    fun isHealthy(sourceId: UUID): Boolean {
        return sourceRepository.findById(sourceId)
            .map { it.healthy }
            .orElse(false)
    }

    fun getHealthySourceIds(): List<UUID> {
        return sourceRepository.findByHealthyTrue().map { it.id }
    }

    fun getAllSourceHealth(): List<SourceEntity> {
        return sourceRepository.findAll()
    }

    fun findSourceByName(name: String): SourceEntity? {
        return sourceRepository.findByName(name)
    }
}
