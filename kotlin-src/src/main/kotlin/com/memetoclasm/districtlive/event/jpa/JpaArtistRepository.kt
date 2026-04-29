package com.memetoclasm.districtlive.event.jpa

import com.memetoclasm.districtlive.event.ArtistRepositoryPort
import com.memetoclasm.districtlive.event.EnrichmentStatus
import jakarta.persistence.LockModeType
import jakarta.persistence.QueryHint
import org.springframework.data.domain.Pageable
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Lock
import org.springframework.data.jpa.repository.Modifying
import org.springframework.data.jpa.repository.Query
import org.springframework.data.jpa.repository.QueryHints
import org.springframework.data.repository.query.Param
import org.springframework.stereotype.Repository
import org.springframework.transaction.annotation.Transactional
import java.util.UUID

@Repository
interface JpaArtistRepository : JpaRepository<ArtistEntity, UUID>, ArtistRepositoryPort {
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @QueryHints(QueryHint(name = "jakarta.persistence.lock.timeout", value = "-2"))
    @Query("""
        SELECT a FROM ArtistEntity a
        WHERE a.enrichmentStatus = com.memetoclasm.districtlive.event.EnrichmentStatus.PENDING
        ORDER BY a.createdAt ASC
    """)
    override fun claimPendingArtistsBatch(pageable: Pageable): List<ArtistEntity>

    @Modifying
    @Transactional
    @Query("""
        UPDATE ArtistEntity a
        SET a.enrichmentStatus = com.memetoclasm.districtlive.event.EnrichmentStatus.PENDING
        WHERE a.enrichmentStatus = com.memetoclasm.districtlive.event.EnrichmentStatus.IN_PROGRESS
    """)
    override fun resetInProgressToPending(): Int

    @Modifying
    @Transactional
    @Query("""
        UPDATE ArtistEntity a
        SET a.enrichmentStatus = com.memetoclasm.districtlive.event.EnrichmentStatus.PENDING
        WHERE a.enrichmentStatus = com.memetoclasm.districtlive.event.EnrichmentStatus.FAILED
          AND a.enrichmentAttempts < :maxAttempts
    """)
    override fun resetEligibleFailedToPending(@Param("maxAttempts") maxAttempts: Int): Int

    @Query("""
        SELECT a FROM ArtistEntity a
        WHERE a.enrichmentStatus = :status
        ORDER BY a.createdAt ASC
    """)
    override fun findByEnrichmentStatus(
        @Param("status") status: EnrichmentStatus,
        pageable: Pageable
    ): List<ArtistEntity>
}
