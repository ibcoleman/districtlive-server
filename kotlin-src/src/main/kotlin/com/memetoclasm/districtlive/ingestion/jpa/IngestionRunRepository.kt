package com.memetoclasm.districtlive.ingestion.jpa

import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Modifying
import org.springframework.data.jpa.repository.Query
import org.springframework.stereotype.Repository
import org.springframework.transaction.annotation.Transactional
import java.time.Instant
import java.util.UUID

@Repository
interface IngestionRunRepository : JpaRepository<IngestionRunEntity, UUID> {
    fun findBySourceIdOrderByStartedAtDesc(sourceId: UUID): List<IngestionRunEntity>

    @Modifying
    @Transactional
    @Query("""
        UPDATE IngestionRunEntity r SET
            r.status = :status,
            r.eventsFetched = :eventsFetched,
            r.eventsCreated = :eventsCreated,
            r.eventsUpdated = :eventsUpdated,
            r.eventsDeduplicated = :eventsDeduplicated,
            r.completedAt = :completedAt
        WHERE r.id = :id
    """)
    fun markSuccess(
        id: UUID,
        status: IngestionRunStatus,
        eventsFetched: Int,
        eventsCreated: Int,
        eventsUpdated: Int,
        eventsDeduplicated: Int,
        completedAt: Instant
    )

    @Modifying
    @Transactional
    @Query("""
        UPDATE IngestionRunEntity r SET
            r.status = :status,
            r.errorMessage = :errorMessage,
            r.completedAt = :completedAt
        WHERE r.id = :id
    """)
    fun markFailed(
        id: UUID,
        status: IngestionRunStatus,
        errorMessage: String,
        completedAt: Instant
    )
}
