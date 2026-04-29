package com.memetoclasm.districtlive.auth.jpa

import jakarta.persistence.Column
import jakarta.persistence.Entity
import jakarta.persistence.EnumType
import jakarta.persistence.Enumerated
import jakarta.persistence.GeneratedValue
import jakarta.persistence.GenerationType
import jakarta.persistence.Id
import jakarta.persistence.Table
import lombok.Builder
import java.time.Instant

@Builder
@Entity
@Table(name = "users")
class UserEntity(
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    val id: Long = 0,

    @Column(nullable = false, unique = true)
    val email: String,

    @Column(name = "password_hash")
    val passwordHash: String? = null,

    @Column(name = "google_id", unique = true)
    val googleId: String? = null,

    @Column(name = "auth_provider", nullable = false)
    @Enumerated(EnumType.STRING)
    val authProvider: AuthProvider = AuthProvider.LOCAL,

    @Column(name = "created_at")
    val createdAt: Instant = Instant.now(),

    @Column(name = "updated_at")
    val updatedAt: Instant = Instant.now()
) {
    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (other !is UserEntity) return false
        return id == other.id
    }

    override fun hashCode(): Int = id.hashCode()
}

enum class AuthProvider {
    LOCAL,
    GOOGLE
}