package com.memetoclasm.districtlive.ingestion

import com.memetoclasm.districtlive.event.SourceType
import java.math.BigDecimal
import java.time.Instant

data class RawEventDto(
    val sourceType: SourceType,
    val sourceIdentifier: String,
    val sourceUrl: String? = null,
    val title: String,
    val description: String? = null,
    val venueName: String? = null,
    val venueAddress: String? = null,
    val artistNames: List<String> = emptyList(),
    val startTime: Instant? = null,
    val endTime: Instant? = null,
    val doorsTime: Instant? = null,
    val minPrice: BigDecimal? = null,
    val maxPrice: BigDecimal? = null,
    val ticketUrl: String? = null,
    val imageUrl: String? = null,
    val ageRestriction: String? = null,
    val genres: List<String> = emptyList(),
    val confidenceScore: BigDecimal = BigDecimal("0.50")
)
