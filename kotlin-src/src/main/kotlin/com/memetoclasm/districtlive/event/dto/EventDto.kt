package com.memetoclasm.districtlive.event.dto

import com.memetoclasm.districtlive.event.AgeRestriction
import com.memetoclasm.districtlive.event.EventStatus
import com.memetoclasm.districtlive.event.PriceTier
import java.math.BigDecimal
import java.time.Instant
import java.util.UUID

data class EventDto(
    val id: UUID,
    val title: String,
    val slug: String,
    val startTime: Instant,
    val doorsTime: Instant? = null,
    val venue: VenueDto? = null,
    val artists: List<ArtistDto> = emptyList(),
    val minPrice: BigDecimal? = null,
    val maxPrice: BigDecimal? = null,
    val priceTier: PriceTier? = null,
    val ticketUrl: String? = null,
    val soldOut: Boolean = false,
    val imageUrl: String? = null,
    val ageRestriction: AgeRestriction = AgeRestriction.ALL_AGES,
    val status: EventStatus = EventStatus.ACTIVE,
    val createdAt: Instant? = null
)
