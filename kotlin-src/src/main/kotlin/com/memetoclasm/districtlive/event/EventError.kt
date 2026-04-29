package com.memetoclasm.districtlive.event

import arrow.core.Either
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity

sealed interface EventError {
    data object EventNotFound : EventError
    data object VenueNotFound : EventError
    data object ArtistNotFound : EventError
    data class InvalidFilter(val message: String) : EventError
    data class PersistenceError(val message: String) : EventError
}

fun handleEventError(err: EventError): ResponseEntity<Any> =
    when (err) {
        EventError.EventNotFound -> ResponseEntity.status(HttpStatus.NOT_FOUND).body("Event not found")
        EventError.VenueNotFound -> ResponseEntity.status(HttpStatus.NOT_FOUND).body("Venue not found")
        EventError.ArtistNotFound -> ResponseEntity.status(HttpStatus.NOT_FOUND).body("Artist not found")
        is EventError.InvalidFilter -> ResponseEntity.badRequest().body(err.message)
        is EventError.PersistenceError -> ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(err.message)
    }

typealias EventResult<T> = Either<EventError, T>
