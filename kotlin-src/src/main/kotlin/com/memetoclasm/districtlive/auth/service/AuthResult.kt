package com.memetoclasm.districtlive.auth.service

import arrow.core.Either
import com.memetoclasm.districtlive.auth.dto.UserResponse
import com.memetoclasm.districtlive.auth.service.AuthError.EmailAlreadyExists
import com.memetoclasm.districtlive.auth.service.AuthError.InvalidGoogleId
import com.memetoclasm.districtlive.auth.service.AuthError.InvalidPassword
import com.memetoclasm.districtlive.auth.service.AuthError.MissingCredentials
import com.memetoclasm.districtlive.auth.service.AuthError.UserNotFound
import org.springframework.http.ResponseEntity

typealias AuthTokenMap = Map<String, String>

typealias AuthResult = Either<AuthError, AuthTokenMap>
typealias RegisterResult = Either<AuthError, UserResponse>

sealed interface AuthError {
    data object EmailAlreadyExists: AuthError
    data object MissingCredentials : AuthError
    data object InvalidPassword : AuthError
    data object UserNotFound : AuthError
    data object InvalidGoogleId : AuthError
}

fun handleAuthError(err: AuthError): ResponseEntity<Any> =
    when(err) {
        EmailAlreadyExists -> ResponseEntity.badRequest().body("Email Already Exists")
        MissingCredentials -> ResponseEntity.badRequest().body("Missing Credentials")
        InvalidPassword -> ResponseEntity.badRequest().body("Invalid Password")
        InvalidGoogleId -> ResponseEntity.badRequest().body("Invalid Google ID")
        UserNotFound -> ResponseEntity.badRequest().body("User not found")
    }