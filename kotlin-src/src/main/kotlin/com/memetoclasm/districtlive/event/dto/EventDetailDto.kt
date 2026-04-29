package com.memetoclasm.districtlive.event.dto

import com.memetoclasm.districtlive.event.AgeRestriction
import com.memetoclasm.districtlive.event.EventStatus
import com.memetoclasm.districtlive.event.PriceTier
import com.memetoclasm.districtlive.event.SourceType
import java.math.BigDecimal
import java.time.Instant
import java.util.UUID

data class EventDetailDto(
    val id: UUID,
    val title: String,
    val slug: String,
    val description: String? = null,
    val startTime: Instant,
    val endTime: Instant? = null,
    val doorsTime: Instant? = null,
    val venue: VenueDto? = null,
    val artists: List<ArtistDto> = emptyList(),
    val minPrice: BigDecimal? = null,
    val maxPrice: BigDecimal? = null,
    val priceTier: PriceTier? = null,
    val ticketUrl: String? = null,
    val onSaleDate: Instant? = null,
    val soldOut: Boolean = false,
    val ticketPlatform: String? = null,
    val imageUrl: String? = null,
    val ageRestriction: AgeRestriction = AgeRestriction.ALL_AGES,
    val status: EventStatus = EventStatus.ACTIVE,
    val createdAt: Instant? = null,
    val sources: List<EventSourceDto> = emptyList(),
    val relatedEvents: List<EventDto> = emptyList()
)

data class EventSourceDto(
    val sourceType: SourceType,
    val lastScrapedAt: Instant? = null
)
