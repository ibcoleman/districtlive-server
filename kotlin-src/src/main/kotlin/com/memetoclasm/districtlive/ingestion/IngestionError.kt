package com.memetoclasm.districtlive.ingestion

import arrow.core.Either

sealed interface IngestionError {
    data class HttpError(val statusCode: Int, val message: String) : IngestionError
    data class RateLimited(val retryAfterSeconds: Long? = null) : IngestionError
    data class ParseError(val source: String, val message: String) : IngestionError
    data class ConnectionError(val source: String, val message: String) : IngestionError
    data class ConfigurationError(val source: String, val message: String) : IngestionError
}

typealias IngestionResult<T> = Either<IngestionError, T>
