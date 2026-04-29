package com.example.auth

import com.memetoclasm.districtlive.auth.service.JwtService
import io.jsonwebtoken.Jwts
import org.junit.jupiter.api.Assertions.*
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import org.springframework.security.core.userdetails.User
import java.util.*

class JwtServiceTest {

    private lateinit var jwtService: JwtService
    private val email = "user@example.com"
    private lateinit var accessToken: String
    private lateinit var refreshToken: String
    private lateinit var userDetails: org.springframework.security.core.userdetails.UserDetails

    @BeforeEach
    fun setup() {
        jwtService = JwtService("test-secret-key-must-be-at-least-32-bytes-long")
        accessToken = jwtService.generateAccessToken(email)
        refreshToken = jwtService.generateRefreshToken(email)
        userDetails = User(email, "password", listOf())
    }

    @Test
    fun `access token should contain correct subject`() {
        val extracted = jwtService.extractEmail(accessToken)
        assertEquals(email, extracted)
    }

    @Test
    fun `refresh token should contain correct subject`() {
        val extracted = jwtService.extractEmail(refreshToken)
        assertEquals(email, extracted)
    }

    @Test
    fun `access token should be valid for matching user`() {
        assertTrue(jwtService.isTokenValid(accessToken, userDetails))
    }

    @Test
    fun `token should be invalid for wrong user`() {
        val wrongUser = User("other@example.com", "password", listOf())
        assertFalse(jwtService.isTokenValid(accessToken, wrongUser))
    }

    @Test
    fun `expired token should be invalid`() {
        // generate a 1 ms token and wait for it to expire
        val shortToken = jwtService.run {
            Jwts.builder()
                .subject(email)
                .issuedAt(Date())
                .expiration(Date(System.currentTimeMillis() + 1))
                .signWith(jwtService.secretKey)
                .compact()
        }
        Thread.sleep(5)
        val valid = jwtService.isRefreshTokenValid(shortToken)
        assertTrue(valid.not())

    }

    @Test
    fun `refresh token should be valid immediately after creation`() {
        assertTrue(jwtService.isRefreshTokenValid(refreshToken))
    }
}
