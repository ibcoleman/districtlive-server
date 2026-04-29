package com.memetoclasm.districtlive.featured

import com.memetoclasm.districtlive.featured.jpa.FeaturedEventEntity
import java.time.Instant

interface FeaturedEventRepositoryPort {
    fun findCurrentFeatured(now: Instant): FeaturedEventEntity?
    fun findAllByOrderByCreatedAtDesc(): List<FeaturedEventEntity>
    fun save(entity: FeaturedEventEntity): FeaturedEventEntity
}
