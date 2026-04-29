package com.memetoclasm.districtlive.auth.service

import io.jsonwebtoken.ExpiredJwtException
import io.jsonwebtoken.JwtException
import io.jsonwebtoken.Jwts
import io.jsonwebtoken.security.Keys
import org.springframework.beans.factory.annotation.Value
import org.springframework.security.core.userdetails.UserDetails
import org.springframework.stereotype.Service
import java.util.Date
import javax.crypto.SecretKey

@Service
class JwtService(
    @Value("\${districtlive.jwt.secret}") secret: String
) {
    val secretKey: SecretKey = Keys.hmacShaKeyFor(secret.toByteArray())

    fun generateAccessToken(email: String): String =
        Jwts.builder()
            .subject(email)
            .issuedAt(Date())
            .expiration(Date(System.currentTimeMillis() + 3600_000)) // 1 hour
            .signWith(secretKey)
            .compact()

    fun generateRefreshToken(email: String): String =
        Jwts.builder()
            .subject(email)
            .issuedAt(Date())
            .expiration(Date(System.currentTimeMillis() + 15 * 24 * 3600_000)) // 15 days
            .signWith(secretKey)
            .compact()

    fun extractEmail(token: String): String? =
        runCatching {
            Jwts.parser()
                .verifyWith(secretKey)
                .build()
                .parseSignedClaims(token)
                .payload
                .subject
        }.getOrNull()

    fun isTokenValid(token: String, userDetails: UserDetails): Boolean =
        extractEmail(token) == userDetails.username && !isExpired(token)

    private fun isExpired(token: String): Boolean =
        try {
            Jwts.parser().verifyWith(secretKey).build()
                .parseSignedClaims(token)
                .payload
                .expiration
                .before(Date())
        } catch (_: ExpiredJwtException) {
            true
        } catch (_: JwtException) {
            true
        }


    fun isRefreshTokenValid(token: String): Boolean =
        try {
            !isExpired(token)
        } catch (_: JwtException) {
            false
        }

}