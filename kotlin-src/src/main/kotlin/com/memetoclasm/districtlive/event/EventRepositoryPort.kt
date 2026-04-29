package com.memetoclasm.districtlive.event

import arrow.core.Either
import com.memetoclasm.districtlive.event.jpa.EventEntity
import java.time.Instant
import java.util.UUID
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.data.jpa.domain.Specification

interface EventRepositoryPort {
    fun findById(id: UUID): java.util.Optional<EventEntity>
    fun findBySlug(slug: String): EventEntity?
    fun findByVenueId(venueId: UUID): List<EventEntity>
    fun findByVenueIdAndStartTimeBetweenAndStatus(
        venueId: UUID,
        startTime: Instant,
        endTime: Instant,
        status: EventStatus
    ): List<EventEntity>
    fun findAll(spec: Specification<EventEntity?>?, pageable: Pageable): Page<EventEntity?>
    fun countUpcomingEventsByVenue(now: Instant): List<Map<String, Any>>
    fun findUpcomingEvents(now: Instant): List<EventEntity>
    fun save(entity: EventEntity): EventEntity
    fun upsertEvent(command: EventUpsertCommand): Either<EventError, UpsertResult>
}
