package com.memetoclasm.districtlive.auth

import jakarta.validation.constraints.Email
import jakarta.validation.constraints.NotBlank

data class RegistrationRequest (
    @field:NotBlank(message = "Email is required")
    @field:Email(message = "Invalid email format")
    val email: String,
    val password: String? = null,
    val googleId: String? = null
)
