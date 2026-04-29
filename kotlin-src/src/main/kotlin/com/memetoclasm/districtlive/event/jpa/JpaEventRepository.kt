package com.memetoclasm.districtlive.event.jpa

import com.memetoclasm.districtlive.event.EventRepositoryPort
import com.memetoclasm.districtlive.event.EventStatus
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.JpaSpecificationExecutor
import org.springframework.data.jpa.repository.Query
import org.springframework.data.repository.query.Param
import org.springframework.stereotype.Repository
import java.time.Instant
import java.util.UUID

@Repository
interface JpaEventRepository : JpaRepository<EventEntity, UUID>, JpaSpecificationExecutor<EventEntity>, EventRepositoryPort {

    override fun findByVenueIdAndStartTimeBetweenAndStatus(
        venueId: UUID,
        startTime: Instant,
        endTime: Instant,
        status: EventStatus
    ): List<EventEntity>

    @Query(
        "SELECT e.venue.id as venueId, COUNT(e) as eventCount " +
        "FROM EventEntity e " +
        "WHERE e.startTime > :now AND e.venue IS NOT NULL " +
        "AND e.status = com.memetoclasm.districtlive.event.EventStatus.ACTIVE " +
        "GROUP BY e.venue.id"
    )
    override fun countUpcomingEventsByVenue(@Param("now") now: Instant): List<Map<String, Any>>

    @Query(
        "SELECT e FROM EventEntity e " +
        "WHERE e.startTime > :now AND e.status = com.memetoclasm.districtlive.event.EventStatus.ACTIVE " +
        "ORDER BY e.startTime ASC " +
        "LIMIT 100"
    )
    override fun findUpcomingEvents(@Param("now") now: Instant): List<EventEntity>
}
