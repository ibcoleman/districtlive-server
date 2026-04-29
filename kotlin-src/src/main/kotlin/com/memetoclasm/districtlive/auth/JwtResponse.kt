package com.memetoclasm.districtlive.auth

import java.time.Instant

data class JwtResponse (
    val token: String,
    val expiresAt: Instant
)