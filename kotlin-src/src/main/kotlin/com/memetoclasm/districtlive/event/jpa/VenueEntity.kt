package com.memetoclasm.districtlive.event.jpa

import jakarta.persistence.*
import org.springframework.data.domain.Persistable
import java.time.Instant
import java.util.UUID

@Entity
@Table(name = "venues")
class VenueEntity(
    @Id
    @get:JvmName("getEntityId")
    val id: UUID = UUID.randomUUID(),

    @Column(nullable = false)
    val name: String,

    @Column(nullable = false, unique = true)
    val slug: String,

    val address: String? = null,

    val neighborhood: String? = null,

    val capacity: Int? = null,

    @Column(name = "venue_type")
    val venueType: String? = null,

    @Column(name = "website_url")
    val websiteUrl: String? = null,

    @Column(name = "display_name")
    var displayName: String? = null,

    @Column(name = "display_slug")
    var displaySlug: String? = null,

    @Column(name = "created_at")
    val createdAt: Instant = Instant.now(),

    @Column(name = "updated_at")
    val updatedAt: Instant = Instant.now()
) : Persistable<UUID> {

    @Transient
    private var _isNew: Boolean = true

    @PostLoad
    private fun onLoad() {
        _isNew = false
    }

    val effectiveName: String
        get() = displayName ?: name

    val effectiveSlug: String
        get() = displaySlug ?: slug

    override fun getId(): UUID = id
    override fun isNew(): Boolean = _isNew
}
