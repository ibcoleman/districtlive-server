package com.memetoclasm.districtlive.ingestion.enrichment

/**
 * Sealed error hierarchy for the enrichment batch pipeline.
 */
sealed class EnrichmentError {
    /** Repository operation failed (e.g. database connectivity issue). */
    data class RepositoryError(val cause: Throwable) : EnrichmentError()
}
