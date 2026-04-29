package com.memetoclasm.districtlive.ingestion.enrichment

import org.springframework.boot.context.properties.ConfigurationProperties

@ConfigurationProperties(prefix = "enrichment")
data class EnrichmentConfig(
    var enabled: Boolean = false,
    var schedule: String = "0 */5 * * * *",
    var batchSize: Int = 20,
    var maxAttempts: Int = 3,
    var musicbrainz: MusicBrainzConfig = MusicBrainzConfig(),
    var spotify: SpotifyConfig = SpotifyConfig()
) {
    data class MusicBrainzConfig(
        var enabled: Boolean = true,
        var rateLimitMs: Long = 1100L,
        var confidenceThreshold: Double = 0.90,
        var userAgent: String = "DistrictLive/1.0 ( contact@districtlive.memetoclasm.com )",
        var baseUrl: String = "https://musicbrainz.org"
    )

    data class SpotifyConfig(
        var enabled: Boolean = false,
        var clientId: String = "",
        var clientSecret: String = "",
        var tokenBaseUrl: String = "https://accounts.spotify.com",
        var searchBaseUrl: String = "https://api.spotify.com",
        var maxRetries: Int = 3,
        var confidenceThreshold: Double = 0.90
    )
}
