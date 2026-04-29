package com.memetoclasm.districtlive.event.dto

import java.util.UUID

data class ArtistDto(
    val id: UUID,
    val name: String,
    val slug: String,
    val genres: List<String> = emptyList(),
    val isLocal: Boolean = false,
    val spotifyUrl: String? = null,
    val bandcampUrl: String? = null,
    val instagramUrl: String? = null,
    val canonicalName: String? = null,
    val imageUrl: String? = null
)
