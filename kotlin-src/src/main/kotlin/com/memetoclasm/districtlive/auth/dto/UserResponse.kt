package com.memetoclasm.districtlive.auth.dto

import com.memetoclasm.districtlive.auth.jpa.AuthProvider
import java.time.Instant

data class UserResponse(
    val email: String,
    val authProvider: AuthProvider,
    val createdAt: Instant
)
