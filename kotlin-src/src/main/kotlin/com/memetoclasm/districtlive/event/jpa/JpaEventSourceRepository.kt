package com.memetoclasm.districtlive.event.jpa

import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.stereotype.Repository
import java.util.UUID

@Repository
interface JpaEventSourceRepository : JpaRepository<EventSourceEntity, UUID> {
    fun findByEventId(eventId: UUID): List<EventSourceEntity>
    fun findBySourceIdentifier(sourceIdentifier: String): EventSourceEntity?
}
