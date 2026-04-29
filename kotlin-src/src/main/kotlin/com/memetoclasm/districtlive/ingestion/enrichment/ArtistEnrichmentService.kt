package com.memetoclasm.districtlive.ingestion.enrichment

import arrow.core.Either
import arrow.core.left
import arrow.core.right
import com.memetoclasm.districtlive.event.ArtistRepositoryPort
import com.memetoclasm.districtlive.event.EnrichmentStatus
import com.memetoclasm.districtlive.event.jpa.ArtistEntity
import kotlinx.coroutines.delay
import org.slf4j.LoggerFactory
import org.springframework.boot.context.event.ApplicationReadyEvent
import org.springframework.context.event.EventListener
import org.springframework.data.domain.PageRequest
import org.springframework.stereotype.Service
import org.springframework.transaction.annotation.Propagation
import org.springframework.transaction.annotation.Transactional
import java.time.Instant

@Service
class ArtistEnrichmentService(
    private val artistRepository: ArtistRepositoryPort,
    private val enrichers: List<ArtistEnricher>,
    private val config: EnrichmentConfig
) {
    private val logger = LoggerFactory.getLogger(ArtistEnrichmentService::class.java)

    @EventListener(ApplicationReadyEvent::class)
    @Transactional(propagation = Propagation.NOT_SUPPORTED)
    fun resetOrphanedInProgress() {
        try {
            val inProgressCount = artistRepository.resetInProgressToPending()
            if (inProgressCount > 0) {
                logger.warn("Reset {} orphaned IN_PROGRESS artists to PENDING at startup", inProgressCount)
            }
            val failedCount = artistRepository.resetEligibleFailedToPending(config.maxAttempts)
            if (failedCount > 0) {
                logger.info("Reset {} eligible FAILED artists to PENDING at startup", failedCount)
            }
            // TODO(future): add @Scheduled periodic call to resetEligibleFailedToPending() for
            //   timed-backoff retry without requiring server restart.
        } catch (ex: Exception) {
            logger.warn("Failed to reset orphaned enrichment records at startup (may be normal in test contexts): {}", ex.message)
        }
    }

    suspend fun enrichBatch(): Either<EnrichmentError, Int> {
        val pageable = PageRequest.of(0, config.batchSize)

        val artists = runCatching {
            artistRepository.claimPendingArtistsBatch(pageable)
        }.getOrElse { ex ->
            logger.error("Failed to claim pending artists: {}", ex.message)
            return EnrichmentError.RepositoryError(ex).left()
        }

        if (artists.isEmpty()) {
            logger.debug("No PENDING artists to enrich")
            return 0.right()
        }

        logger.info("Claimed {} PENDING artists for enrichment", artists.size)

        // Mark all claimed artists as IN_PROGRESS before processing
        artists.forEach { artist ->
            artist.enrichmentStatus = EnrichmentStatus.IN_PROGRESS
            artist.enrichmentAttempts += 1
            artistRepository.save(artist)
        }

        for (artist in artists) {
            try {
                processArtist(artist)
            } catch (ex: Exception) {
                logger.error("Unexpected error processing artist '{}': {}", artist.name, ex.message)
                markFailed(artist)
            }
            delay(config.musicbrainz.rateLimitMs)
        }

        return artists.size.right()
    }

    private suspend fun processArtist(artist: ArtistEntity) {
        // enrichmentAttempts was already incremented before processing, so > maxAttempts means this is attempt maxAttempts+1
        if (artist.enrichmentAttempts > config.maxAttempts) {
            logger.info("Artist '{}' exceeded max attempts ({}), marking SKIPPED", artist.name, config.maxAttempts)
            markSkipped(artist)
            return
        }

        var anyEnricherSucceeded = false
        var anyEnricherThrew = false

        for (enricher in enrichers) {
            try {
                val result = enricher.enrich(artist.name)
                if (result != null) {
                    applyResult(artist, enricher.source, result)
                    anyEnricherSucceeded = true
                }
            } catch (ex: Exception) {
                logger.warn("Enricher {} threw for artist '{}': {}", enricher.source, artist.name, ex.message)
                anyEnricherThrew = true
            }
        }

        when {
            anyEnricherThrew -> markFailed(artist)
            !anyEnricherSucceeded && artist.enrichmentAttempts >= config.maxAttempts -> markSkipped(artist)
            !anyEnricherSucceeded -> markFailed(artist) // retry next poll
            else -> markDone(artist)
        }
    }

    private fun applyResult(artist: ArtistEntity, source: EnrichmentSource, result: EnrichmentResult) {
        when (source) {
            EnrichmentSource.MUSIC_BRAINZ -> {
                if (result.canonicalName != null) artist.canonicalName = result.canonicalName
                if (result.externalId != null) artist.musicbrainzId = result.externalId
                artist.mbTags = result.tags.toTypedArray()
            }
            EnrichmentSource.SPOTIFY -> {
                if (result.externalId != null) artist.spotifyId = result.externalId
                artist.spotifyGenres = result.tags.toTypedArray()
                if (result.imageUrl != null) artist.imageUrl = result.imageUrl
            }
            EnrichmentSource.OLLAMA -> {
                // No-op: Ollama adapter not yet implemented
            }
        }
    }

    private fun markDone(artist: ArtistEntity) {
        artist.enrichmentStatus = EnrichmentStatus.DONE
        artist.lastEnrichedAt = Instant.now()
        artistRepository.save(artist)
        logger.debug("Artist '{}' enrichment DONE", artist.name)
    }

    private fun markFailed(artist: ArtistEntity) {
        artist.enrichmentStatus = EnrichmentStatus.FAILED
        artistRepository.save(artist)
        logger.debug("Artist '{}' enrichment FAILED (attempts: {})", artist.name, artist.enrichmentAttempts)
    }

    private fun markSkipped(artist: ArtistEntity) {
        artist.enrichmentStatus = EnrichmentStatus.SKIPPED
        artist.lastEnrichedAt = Instant.now()
        artistRepository.save(artist)
        logger.info("Artist '{}' enrichment SKIPPED after {} attempts", artist.name, artist.enrichmentAttempts)
    }
}
