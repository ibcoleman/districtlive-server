package com.memetoclasm.districtlive.auth.service

import com.memetoclasm.districtlive.auth.LoginRequest
import com.memetoclasm.districtlive.auth.RegistrationRequest
import jakarta.validation.Valid
import org.slf4j.LoggerFactory
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RestController

@RestController
@RequestMapping(value = ["/api/auth"])
class AuthApiService (
    private val authService: AuthService
) {
    companion object {
        private val log = LoggerFactory.getLogger(AuthApiService::class.java)
    }

    /**
     * Handles the creation of a new user account based on the provided registration details*/
    @PostMapping(value= ["/register"], consumes = ["application/json"])
    fun  createAccount(@Valid @RequestBody request: RegistrationRequest): ResponseEntity<Any> =
        authService.register(request)
            .fold(::handleAuthError) {
                user -> ResponseEntity.ok(user)
            }

    /**
     * Handles user login based on the provided login request.
     * This method authenticates the user using either local credentials (email and password)
     * or Google ID, depending on the authentication provider associated with the user account.
     *
     * @param request the login request containing user email and either password or Google ID.
     * @return a response entity containing either the authentication token upon successful login
     *         or an error response if the login fails.
     */
    @PostMapping(value= ["/login"], consumes = ["application/json"])
    fun login(@Valid @RequestBody request: LoginRequest): ResponseEntity<Any> =
        authService.login(request)
            .fold(::handleAuthError) {
                tokenMap -> ResponseEntity.ok(tokenMap)
            }

}