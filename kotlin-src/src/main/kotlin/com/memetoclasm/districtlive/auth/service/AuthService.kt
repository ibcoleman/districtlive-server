package com.memetoclasm.districtlive.auth.service

import arrow.core.Either
import arrow.core.raise.either
import arrow.core.right
import com.memetoclasm.districtlive.auth.jpa.AuthProvider
import com.memetoclasm.districtlive.auth.LoginRequest
import com.memetoclasm.districtlive.auth.RegistrationRequest
import com.memetoclasm.districtlive.auth.dto.UserMapper
import com.memetoclasm.districtlive.auth.jpa.UserEntity
import com.memetoclasm.districtlive.auth.jpa.UserRepository
import com.memetoclasm.districtlive.auth.service.AuthError.EmailAlreadyExists
import com.memetoclasm.districtlive.auth.service.AuthError.InvalidGoogleId
import com.memetoclasm.districtlive.auth.service.AuthError.InvalidPassword
import com.memetoclasm.districtlive.auth.service.AuthError.MissingCredentials
import com.memetoclasm.districtlive.auth.service.AuthError.UserNotFound
import org.springframework.security.crypto.password.PasswordEncoder
import org.springframework.stereotype.Service

@Service
class AuthService(
    private val userRepository: UserRepository,
    private val passwordEncoder: PasswordEncoder,
    private val jwtService: JwtService,
    private val userMapper: UserMapper
) {

    /**
     *
     */
    fun register(request: RegistrationRequest): RegisterResult = either {

        existsByEmail(request.email).bind()
        val user = makeNewUser(request).bind()
        userRepository.save(user)

        return userMapper.toUserResponse(user).right()
    }

    /**
     * Creates a new `User` instance based on the given `RegistrationRequest`.
     * The user is initialized with either the `googleId` or an encoded `password`,
     * depending on the contents of the request. The user's authentication provider
     * is also set accordingly. If neither `googleId` nor `password` is provided,
     * an error is raised.
     *
     * @param request the registration request containing user-related information,
     *                such as email, password, or Google ID.
     * @return an `Either` containing the created `User` instance if successful,
     *         or an `AuthError` if the provided data is invalid or incomplete.
     */
    fun makeNewUser(request: RegistrationRequest): Either<AuthError, UserEntity> = either {
        when {
            request.googleId != null -> UserEntity(
                email = request.email,
                googleId = request.googleId,
                authProvider = AuthProvider.GOOGLE
            )
            request.password != null -> UserEntity(
                email = request.email,
                passwordHash = passwordEncoder.encode(request.password),
                authProvider = AuthProvider.LOCAL
            )
            else -> raise(MissingCredentials)
        }
    }

    /**
     * Checks whether a user exists based on the provided email address.
     *
     * @param email the email address to check for an existing user.
     * @return an `Either` that contains `Unit` if no user exists with the given email,
     *         or an `AuthError.EmailAlreadyExists` if a user is already registered with the email.
     */
    fun existsByEmail(email: String): Either<AuthError, Unit> = either {
        when {
            userRepository.existsByEmail(email) -> raise(EmailAlreadyExists)
        }
    }

    fun findByEmail(email: String): Either<AuthError, UserEntity> = either {
        val user = userRepository.findByEmail(email) ?: raise(UserNotFound)
        return user.right()
    }

    private fun validateLocalId(request: LoginRequest, userEntity: UserEntity): Either<AuthError, Unit> = either {

        if (userEntity.passwordHash == null || !passwordEncoder.matches(request.password, userEntity.passwordHash)) {
            raise(InvalidPassword)
        }
    }

    private fun validateGoogleId(request: LoginRequest, userEntity: UserEntity): Either<AuthError, Unit> = either {
        if (request.googleId != userEntity.googleId) {
            raise(InvalidGoogleId)
        }
    }
    /**
     *
     */
    fun login(request: LoginRequest): AuthResult = either {
        val user = findByEmail(request.email).bind()
        when (user.authProvider) {
            AuthProvider.LOCAL -> validateLocalId(request, user).bind()
            AuthProvider.GOOGLE -> validateGoogleId(request, user).bind()
        }

        return mapOf(
            "access_token" to jwtService.generateAccessToken(user.email),
            "refresh_token" to jwtService.generateRefreshToken(user.email),
        ).right()
    }
}
