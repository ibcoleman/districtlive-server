package com.memetoclasm.districtlive.event

import com.memetoclasm.districtlive.event.jpa.ArtistEntity
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import java.util.UUID

interface ArtistRepositoryPort {
    fun findById(id: UUID): java.util.Optional<ArtistEntity>
    fun findBySlug(slug: String): ArtistEntity?
    fun findByNameIgnoreCase(name: String): ArtistEntity?
    fun findByIsLocalTrue(): List<ArtistEntity>
    fun findAll(pageable: Pageable): Page<ArtistEntity>
    fun save(entity: ArtistEntity): ArtistEntity

    /**
     * Claims a batch of PENDING artists for enrichment by locking them with SKIP LOCKED.
     * Callers must immediately update each returned artist to IN_PROGRESS and save.
     */
    fun claimPendingArtistsBatch(pageable: Pageable): List<ArtistEntity>

    /**
     * Resets all IN_PROGRESS artists to PENDING — called on startup to recover from crashes.
     * Returns the number of rows reset.
     */
    fun resetInProgressToPending(): Int

    /**
     * Resets FAILED artists whose attempt count is below maxAttempts back to PENDING so they
     * are retried in the next enrichment cycle.
     * Returns the number of rows reset.
     */
    fun resetEligibleFailedToPending(maxAttempts: Int): Int

    /**
     * Loads a batch of artists by status for processing or monitoring.
     */
    fun findByEnrichmentStatus(status: EnrichmentStatus, pageable: Pageable): List<ArtistEntity>
}
