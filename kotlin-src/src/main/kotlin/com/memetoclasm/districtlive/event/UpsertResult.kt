package com.memetoclasm.districtlive.event

import java.util.UUID

sealed interface UpsertResult {
    data class Created(val eventId: UUID) : UpsertResult
    data class Updated(val eventId: UUID) : UpsertResult
}
