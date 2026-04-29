package com.memetoclasm.districtlive.event.jpa

import com.memetoclasm.districtlive.event.SourceType
import jakarta.persistence.*
import org.springframework.data.domain.Persistable
import java.math.BigDecimal
import java.time.Instant
import java.util.UUID

@Entity
@Table(name = "event_sources")
class EventSourceEntity(
    @Id
    @get:JvmName("getEntityId")
    val id: UUID = UUID.randomUUID(),

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "event_id", nullable = false)
    val event: EventEntity,

    @Column(name = "source_type", nullable = false)
    @Enumerated(EnumType.STRING)
    val sourceType: SourceType,

    @Column(name = "source_identifier")
    val sourceIdentifier: String? = null,

    @Column(name = "source_url")
    val sourceUrl: String? = null,

    @Column(name = "last_scraped_at")
    val lastScrapedAt: Instant? = null,

    @Column(name = "source_id")
    val sourceId: UUID? = null,

    @Column(name = "confidence_score")
    val confidenceScore: BigDecimal = BigDecimal("0.50"),

    @Column(name = "created_at")
    val createdAt: Instant = Instant.now()
) : Persistable<UUID> {
    override fun getId(): UUID = id
    override fun isNew(): Boolean = true
}
