package com.memetoclasm.districtlive.featured.jpa

import com.memetoclasm.districtlive.featured.FeaturedEventRepositoryPort
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.data.jpa.repository.Query
import java.time.Instant
import java.util.UUID

interface JpaFeaturedEventRepository : JpaRepository<FeaturedEventEntity, UUID>, FeaturedEventRepositoryPort {

    @Query("""
        SELECT fe FROM FeaturedEventEntity fe
        JOIN FETCH fe.event e
        WHERE e.startTime > :now
        ORDER BY fe.createdAt DESC
        LIMIT 1
    """)
    override fun findCurrentFeatured(now: Instant): FeaturedEventEntity?

    override fun findAllByOrderByCreatedAtDesc(): List<FeaturedEventEntity>
}
