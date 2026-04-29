package com.memetoclasm.districtlive.event.jpa

import com.memetoclasm.districtlive.event.SourceType
import jakarta.persistence.*
import org.hibernate.annotations.JdbcTypeCode
import org.hibernate.type.SqlTypes
import org.springframework.data.domain.Persistable
import java.time.Instant
import java.util.UUID

@Entity
@Table(name = "sources")
class SourceEntity(
    @Id
    @get:JvmName("getEntityId")
    val id: UUID = UUID.randomUUID(),

    @Column(nullable = false, unique = true)
    val name: String,

    @Column(name = "source_type", nullable = false)
    @Enumerated(EnumType.STRING)
    val sourceType: SourceType,

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(columnDefinition = "jsonb")
    val configuration: String? = null,

    @Column(name = "scrape_schedule")
    val scrapeSchedule: String? = null,

    @Column(name = "last_success_at")
    var lastSuccessAt: Instant? = null,

    @Column(name = "last_failure_at")
    var lastFailureAt: Instant? = null,

    @Column(name = "consecutive_failures")
    var consecutiveFailures: Int = 0,

    var healthy: Boolean = true,

    @Column(name = "created_at")
    val createdAt: Instant = Instant.now(),

    @Column(name = "updated_at")
    var updatedAt: Instant = Instant.now()
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
