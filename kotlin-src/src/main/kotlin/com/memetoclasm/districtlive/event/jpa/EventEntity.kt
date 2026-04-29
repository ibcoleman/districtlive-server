package com.memetoclasm.districtlive.event.jpa

import com.memetoclasm.districtlive.event.AgeRestriction
import com.memetoclasm.districtlive.event.EventStatus
import com.memetoclasm.districtlive.event.EventType
import com.memetoclasm.districtlive.event.PriceTier
import jakarta.persistence.*
import org.springframework.data.domain.Persistable
import java.math.BigDecimal
import java.time.Instant
import java.util.UUID

@Entity
@Table(name = "events")
class EventEntity(
    @Id
    @get:JvmName("getEntityId")
    val id: UUID = UUID.randomUUID(),

    @Column(nullable = false)
    var title: String,

    @Column(nullable = false)
    val slug: String,

    var description: String? = null,

    @Column(name = "start_time", nullable = false)
    var startTime: Instant,

    @Column(name = "end_time")
    var endTime: Instant? = null,

    @Column(name = "doors_time")
    var doorsTime: Instant? = null,

    @Column(name = "min_price")
    var minPrice: BigDecimal? = null,

    @Column(name = "max_price")
    var maxPrice: BigDecimal? = null,

    @Column(name = "price_tier")
    @Enumerated(EnumType.STRING)
    var priceTier: PriceTier? = null,

    @Column(name = "ticket_url")
    var ticketUrl: String? = null,

    @Column(name = "on_sale_date")
    var onSaleDate: Instant? = null,

    @Column(name = "sold_out")
    var soldOut: Boolean = false,

    @Column(name = "ticket_platform")
    var ticketPlatform: String? = null,

    @Column(name = "image_url")
    var imageUrl: String? = null,

    @Column(name = "age_restriction")
    @Enumerated(EnumType.STRING)
    var ageRestriction: AgeRestriction = AgeRestriction.ALL_AGES,

    @Enumerated(EnumType.STRING)
    var status: EventStatus = EventStatus.ACTIVE,

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "venue_id")
    var venue: VenueEntity? = null,

    @ManyToMany(fetch = FetchType.LAZY)
    @JoinTable(
        name = "event_artists",
        joinColumns = [JoinColumn(name = "event_id")],
        inverseJoinColumns = [JoinColumn(name = "artist_id")]
    )
    var artists: MutableSet<ArtistEntity> = mutableSetOf(),

    @OneToMany(mappedBy = "event", cascade = [CascadeType.ALL], orphanRemoval = true, fetch = FetchType.LAZY)
    val sources: MutableList<EventSourceEntity> = mutableListOf(),

    @Column(name = "created_at")
    val createdAt: Instant = Instant.now(),

    @Column(name = "updated_at")
    var updatedAt: Instant = Instant.now(),

    @Column(name = "title_parsed", nullable = false)
    var titleParsed: Boolean = false,

    @Column(name = "event_type")
    @Enumerated(EnumType.STRING)
    var eventType: EventType? = null
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
