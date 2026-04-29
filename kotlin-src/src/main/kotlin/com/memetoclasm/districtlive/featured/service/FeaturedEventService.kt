package com.memetoclasm.districtlive.featured.service

import arrow.core.raise.either
import arrow.core.raise.ensure
import com.memetoclasm.districtlive.event.EventRepositoryPort
import org.springframework.transaction.annotation.Transactional
import com.memetoclasm.districtlive.event.dto.ArtistMapper
import com.memetoclasm.districtlive.event.dto.EventMapper
import com.memetoclasm.districtlive.event.dto.VenueMapper
import com.memetoclasm.districtlive.featured.FeaturedEventError
import com.memetoclasm.districtlive.featured.FeaturedEventRepositoryPort
import com.memetoclasm.districtlive.featured.FeaturedEventResult
import com.memetoclasm.districtlive.featured.dto.FeaturedEventDto
import com.memetoclasm.districtlive.featured.jpa.FeaturedEventEntity
import org.springframework.stereotype.Service
import java.time.Clock
import java.time.Instant
import java.util.UUID

@Service
class FeaturedEventService(
    private val featuredEventRepository: FeaturedEventRepositoryPort,
    private val eventRepository: EventRepositoryPort,
    private val eventMapper: EventMapper,
    private val venueMapper: VenueMapper,
    private val artistMapper: ArtistMapper,
    private val clock: Clock = Clock.systemUTC()
) {

    @Transactional(readOnly = true)
    fun getCurrentFeatured(): FeaturedEventResult<FeaturedEventDto> = either {
        val now = Instant.now(clock)
        val featured = featuredEventRepository.findCurrentFeatured(now)
            ?: raise(FeaturedEventError.NoActiveFeaturedEvent)
        featured.toDto()
    }

    @Transactional
    fun createFeatured(eventId: UUID, blurb: String): FeaturedEventResult<FeaturedEventDto> = either {
        ensure(blurb.isNotBlank()) { FeaturedEventError.InvalidRequest("Blurb cannot be blank") }
        val event = eventRepository.findById(eventId).orElse(null)
            ?: raise(FeaturedEventError.EventNotFound)
        val entity = FeaturedEventEntity(
            event = event,
            blurb = blurb.trim()
        )
        val saved = featuredEventRepository.save(entity)
        saved.toDto()
    }

    @Transactional(readOnly = true)
    fun getHistory(): List<FeaturedEventDto> {
        return featuredEventRepository.findAllByOrderByCreatedAtDesc()
            .map { it.toDto() }
    }

    private fun FeaturedEventEntity.toDto(): FeaturedEventDto {
        val eventEntity = this.event
        val eventDetail = eventMapper.toDetailDto(eventEntity).copy(
            venue = eventEntity.venue?.let { venueMapper.toDto(it) },
            artists = eventEntity.artists.map { artistMapper.toDto(it) }
        )
        return FeaturedEventDto(
            id = id,
            event = eventDetail,
            blurb = blurb,
            createdAt = createdAt,
            createdBy = createdBy
        )
    }
}
