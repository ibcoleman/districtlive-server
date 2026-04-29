package com.memetoclasm.districtlive.ingestion

import arrow.core.Either
import com.memetoclasm.districtlive.event.SourceType

interface SourceConnector {
    val sourceId: String
    val sourceType: SourceType
    suspend fun fetch(): Either<IngestionError, List<RawEventDto>>
    fun healthCheck(): Boolean
}
