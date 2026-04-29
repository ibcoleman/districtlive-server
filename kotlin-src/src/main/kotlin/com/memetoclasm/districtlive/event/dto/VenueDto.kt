package com.memetoclasm.districtlive.event.dto

import java.util.UUID

data class VenueDto(
    val id: UUID,
    val name: String,
    val slug: String,
    val neighborhood: String?,
    val websiteUrl: String?,
    val upcomingEventCount: Long = 0
)
