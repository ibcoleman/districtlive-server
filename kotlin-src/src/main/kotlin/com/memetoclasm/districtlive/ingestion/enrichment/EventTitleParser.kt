package com.memetoclasm.districtlive.ingestion.enrichment

import com.memetoclasm.districtlive.event.EventType

/**
 * Port interface for a future Ollama-backed component that parses a raw event title
 * (e.g., "Mitski w/ Hand Habits") into structured fields.
 *
 * Implementation is deferred — no adapter exists yet.
 */
interface EventTitleParser {
    suspend fun parse(rawTitle: String): ParsedTitle
}

/**
 * Structured result of parsing a raw event title.
 *
 * @param headliner  Primary artist extracted from the title, or null if undetermined.
 * @param openers    Supporting acts extracted from the title (may be empty).
 * @param eventType  Classified event type, or null if undetermined.
 */
data class ParsedTitle(
    val headliner: String?,
    val openers: List<String>,
    val eventType: EventType?
)
