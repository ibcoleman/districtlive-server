package com.memetoclasm.districtlive.featured.jpa

import com.memetoclasm.districtlive.event.jpa.EventEntity
import jakarta.persistence.*
import org.springframework.data.domain.Persistable
import java.time.Instant
import java.util.UUID

@Entity
@Table(name = "featured_events")
class FeaturedEventEntity(
    @Id
    @get:JvmName("getEntityId")
    val id: UUID = UUID.randomUUID(),

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "event_id", nullable = false)
    val event: EventEntity,

    @Column(nullable = false)
    val blurb: String,

    @Column(name = "created_at", nullable = false)
    val createdAt: Instant = Instant.now(),

    @Column(name = "created_by", nullable = false)
    val createdBy: String = "admin"
) : Persistable<UUID> {

    @Transient
    private var _isNew: Boolean = true

    @PostLoad
    private fun onLoad() {
        _isNew = false
    }

    override fun getId(): UUID = id
    override fun isNew(): Boolean = _isNew
}
