package com.memetoclasm.districtlive.event

import java.math.BigDecimal
import java.time.Instant
import java.util.UUID

data class EventUpsertCommand(
    val slug: String,
    val title: String,
    val description: String?,
    val startTime: Instant,
    val endTime: Instant?,
    val doorsTime: Instant?,
    val venueName: String?,
    val venueAddress: String?,
    val artistNames: List<String>,
    val minPrice: BigDecimal?,
    val maxPrice: BigDecimal?,
    val priceTier: PriceTier?,
    val ticketUrl: String?,
    val imageUrl: String?,
    val ageRestriction: AgeRestriction,
    val sourceAttributions: List<EventSourceAttribution>
)

data class EventSourceAttribution(
    val sourceType: SourceType,
    val sourceIdentifier: String,
    val sourceUrl: String?,
    val confidenceScore: BigDecimal,
    val sourceId: UUID? = null
)
