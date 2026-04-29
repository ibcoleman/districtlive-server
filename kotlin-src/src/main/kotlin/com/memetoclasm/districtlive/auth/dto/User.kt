package com.memetoclasm.districtlive.auth.dto

import com.memetoclasm.districtlive.auth.jpa.AuthProvider
import java.time.Instant


data class User (
    val email: String,
    val passwordHash: String,
    val authProvider: AuthProvider,
    val createdAt: Instant,
    val updatedAt: Instant
)