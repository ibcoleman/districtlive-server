package com.memetoclasm.districtlive.ingestion.jpa

import jakarta.persistence.*
import org.springframework.data.domain.Persistable
import java.time.Instant
import java.util.UUID

enum class IngestionRunStatus {
    RUNNING,
    SUCCESS,
    FAILED
}

@Entity
@Table(name = "ingestion_runs")
class IngestionRunEntity(
    @Id
    @get:JvmName("getEntityId")
    val id: UUID = UUID.randomUUID(),

    @Column(name = "source_id", nullable = false)
    val sourceId: UUID,

    @Column(nullable = false)
    @Enumerated(EnumType.STRING)
    var status: IngestionRunStatus = IngestionRunStatus.RUNNING,

    @Column(name = "events_fetched")
    var eventsFetched: Int = 0,

    @Column(name = "events_created")
    var eventsCreated: Int = 0,

    @Column(name = "events_updated")
    var eventsUpdated: Int = 0,

    @Column(name = "events_deduplicated")
    var eventsDeduplicated: Int = 0,

    @Column(name = "error_message")
    var errorMessage: String? = null,

    @Column(name = "started_at", nullable = false)
    val startedAt: Instant = Instant.now(),

    @Column(name = "completed_at")
    var completedAt: Instant? = null
) : Persistable<UUID> {
    // isNew=true: this entity is only ever inserted, never updated via save()
    override fun getId(): UUID = id
    override fun isNew(): Boolean = true
}
