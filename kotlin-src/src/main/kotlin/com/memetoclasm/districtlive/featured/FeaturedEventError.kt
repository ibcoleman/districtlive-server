package com.memetoclasm.districtlive.featured

import arrow.core.Either
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity

sealed interface FeaturedEventError {
    data object NoActiveFeaturedEvent : FeaturedEventError
    data object EventNotFound : FeaturedEventError
    data class InvalidRequest(val message: String) : FeaturedEventError
}

fun handleFeaturedEventError(err: FeaturedEventError): ResponseEntity<Any> =
    when (err) {
        FeaturedEventError.NoActiveFeaturedEvent ->
            ResponseEntity.status(HttpStatus.NOT_FOUND).body("No active featured event")
        FeaturedEventError.EventNotFound ->
            ResponseEntity.status(HttpStatus.NOT_FOUND).body("Event not found")
        is FeaturedEventError.InvalidRequest ->
            ResponseEntity.badRequest().body(err.message)
    }

typealias FeaturedEventResult<T> = Either<FeaturedEventError, T>
