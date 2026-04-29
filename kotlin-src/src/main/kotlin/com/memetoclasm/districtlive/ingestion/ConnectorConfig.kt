package com.memetoclasm.districtlive.ingestion

import com.memetoclasm.districtlive.ingestion.enrichment.EnrichmentConfig
import org.springframework.boot.context.properties.ConfigurationProperties
import org.springframework.boot.context.properties.EnableConfigurationProperties
import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration
import org.springframework.http.codec.ClientCodecConfigurer
import org.springframework.web.reactive.function.client.ExchangeStrategies
import org.springframework.web.reactive.function.client.WebClient

@ConfigurationProperties(prefix = "districtlive.connectors")
data class ConnectorConfig(
    var ticketmaster: TicketmasterConfig = TicketmasterConfig(),
    var bandsintown: BandsintownConfig = BandsintownConfig(),
    var dice: DiceConfig = DiceConfig(),
    var unionStagePresents: UnionStagePresentsCfg = UnionStagePresentsCfg()
) {
    data class TicketmasterConfig(
        var apiKey: String = "",
        var baseUrl: String = "",
        var pageSize: Int = 200
    )

    data class BandsintownConfig(
        var appId: String = "",
        var baseUrl: String = "",
        var seedArtists: List<String> = emptyList()
    )

    data class DiceConfig(
        var venueSlugs: List<String> = listOf(
            "songbyrd-r58r",
            "dc9-q2xvo",
            "comet-ping-pong-5bky",
            "byrdland-wo3n",
            "berhta-8emn5",
            "the-arlo-washington-dc-2w997",
            "secret-location---dc-xeex3"
        )
    )

    data class UnionStagePresentsCfg(
        var venues: List<VenueMapping> = emptyList()
    ) {
        data class VenueMapping(
            var slug: String = "",
            var path: String = ""
        )
    }
}

@Configuration
@EnableConfigurationProperties(ConnectorConfig::class, IngestionConfig::class, EnrichmentConfig::class, NotificationConfig::class)
class WebClientConfiguration {
    @Bean
    fun webClientBuilder(): WebClient.Builder {
        val strategies = ExchangeStrategies.builder()
            .codecs { codecs: ClientCodecConfigurer ->
                codecs.defaultCodecs().maxInMemorySize(2 * 1024 * 1024) // 2 MB
            }
            .build()
        return WebClient.builder().exchangeStrategies(strategies)
    }
}
