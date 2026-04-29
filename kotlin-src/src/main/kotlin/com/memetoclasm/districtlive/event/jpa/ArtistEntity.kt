package com.memetoclasm.districtlive.event.jpa

import com.memetoclasm.districtlive.event.EnrichmentStatus
import jakarta.persistence.*
import org.hibernate.annotations.JdbcTypeCode
import org.hibernate.type.SqlTypes
import org.springframework.data.domain.Persistable
import java.time.Instant
import java.util.UUID

@Entity
@Table(name = "artists")
class ArtistEntity(
    @Id
    @get:JvmName("getEntityId")
    val id: UUID = UUID.randomUUID(),

    @Column(nullable = false)
    val name: String,

    @Column(nullable = false, unique = true)
    val slug: String,

    @JdbcTypeCode(SqlTypes.ARRAY)
    @Column(columnDefinition = "text[]")
    val genres: Array<String> = emptyArray(),

    @Column(name = "is_local")
    val isLocal: Boolean = false,

    @Column(name = "spotify_url")
    val spotifyUrl: String? = null,

    @Column(name = "bandcamp_url")
    val bandcampUrl: String? = null,

    @Column(name = "instagram_url")
    val instagramUrl: String? = null,

    @Column(name = "created_at")
    val createdAt: Instant = Instant.now(),

    @Column(name = "updated_at")
    val updatedAt: Instant = Instant.now(),

    @Column(name = "enrichment_status", nullable = false)
    @Enumerated(EnumType.STRING)
    var enrichmentStatus: EnrichmentStatus = EnrichmentStatus.PENDING,

    @Column(name = "enrichment_attempts", nullable = false)
    var enrichmentAttempts: Int = 0,

    @Column(name = "last_enriched_at")
    var lastEnrichedAt: Instant? = null,

    @Column(name = "musicbrainz_id")
    var musicbrainzId: String? = null,

    @Column(name = "spotify_id")
    var spotifyId: String? = null,

    @Column(name = "canonical_name")
    var canonicalName: String? = null,

    @JdbcTypeCode(SqlTypes.ARRAY)
    @Column(name = "mb_tags", columnDefinition = "text[]")
    var mbTags: Array<String> = emptyArray(),

    @JdbcTypeCode(SqlTypes.ARRAY)
    @Column(name = "spotify_genres", columnDefinition = "text[]")
    var spotifyGenres: Array<String> = emptyArray(),

    @Column(name = "image_url")
    var imageUrl: String? = null
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
