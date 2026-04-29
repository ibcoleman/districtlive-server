package com.memetoclasm.districtlive.featured.dto

import com.memetoclasm.districtlive.event.dto.EventDetailDto
import java.time.Instant
import java.util.UUID

data class FeaturedEventDto(
    val id: UUID,
    val event: EventDetailDto,
    val blurb: String,
    val createdAt: Instant,
    val createdBy: String
)
