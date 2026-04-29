package com.memetoclasm.districtlive.event.service

import arrow.core.raise.either
import com.memetoclasm.districtlive.event.ArtistRepositoryPort
import com.memetoclasm.districtlive.event.EventError
import com.memetoclasm.districtlive.event.EventRepositoryPort
import com.memetoclasm.districtlive.event.EventResult
import com.memetoclasm.districtlive.event.EventStatus
import com.memetoclasm.districtlive.event.VenueRepositoryPort
import com.memetoclasm.districtlive.event.dto.ArtistDto
import com.memetoclasm.districtlive.event.dto.ArtistMapper
import com.memetoclasm.districtlive.event.dto.EventDetailDto
import com.memetoclasm.districtlive.event.dto.EventDto
import com.memetoclasm.districtlive.event.dto.EventMapper
import com.memetoclasm.districtlive.event.dto.VenueDto
import com.memetoclasm.districtlive.event.dto.VenueMapper
import com.memetoclasm.districtlive.event.jpa.EventEntity
import org.springframework.data.jpa.domain.Specification
import java.math.BigDecimal
import java.time.Clock
import java.time.Instant
import java.util.UUID
import org.springframework.data.domain.Page
import org.springframework.data.domain.PageImpl
import org.springframework.data.domain.Pageable
import org.springframework.stereotype.Service

@Service
class EventService(
    private val eventRepository: EventRepositoryPort,
    private val venueRepository: VenueRepositoryPort,
    private val artistRepository: ArtistRepositoryPort,
    private val eventMapper: EventMapper,
    private val venueMapper: VenueMapper,
    private val artistMapper: ArtistMapper,
    private val clock: Clock = Clock.systemUTC()
) {

    fun findEvents(
        dateFrom: Instant? = null,
        dateTo: Instant? = null,
        venueSlug: String? = null,
        genre: String? = null,
        neighborhood: String? = null,
        priceMax: BigDecimal? = null,
        status: EventStatus = EventStatus.ACTIVE,
        pageable: Pageable
    ): EventResult<Page<EventDto>> = either {
        var spec = EventSpecifications.hasStatus(status)

        if (dateFrom != null || dateTo != null) {
            spec = spec.and(EventSpecifications.hasDateRange(dateFrom, dateTo))
        }
        if (venueSlug != null) {
            spec = spec.and(EventSpecifications.hasVenueSlug(venueSlug))
        }
        if (genre != null) {
            spec = spec.and(EventSpecifications.hasGenre(genre))
        }
        if (neighborhood != null) {
            spec = spec.and(EventSpecifications.hasNeighborhood(neighborhood))
        }
        if (priceMax != null) {
            spec = spec.and(EventSpecifications.hasPriceMax(priceMax))
        }

        @Suppress("UNCHECKED_CAST")
        val eventPage = eventRepository.findAll(spec as Specification<EventEntity?>?, pageable)
        eventPage.map { eventMapper.toDto(it!!) }
    }

    fun findEventById(id: UUID): EventResult<EventDetailDto> = either {
        val event = eventRepository.findById(id).orElse(null)
            ?: raise(EventError.EventNotFound)

        val relatedEvents = findRelatedEvents(event)
        val detailDto = eventMapper.toDetailDto(event)
        detailDto.copy(relatedEvents = relatedEvents)
    }

    fun findVenues(
        neighborhood: String? = null,
        pageable: Pageable
    ): EventResult<Page<VenueDto>> = either {
        // Get paginated venues
        val venuePage = if (neighborhood != null) {
            // Use database pagination for neighborhood filter
            val venueList = venueRepository.findByNeighborhood(neighborhood)
            val totalCount = venueList.size
            val startIdx = minOf(pageable.offset.toInt(), totalCount)
            val endIdx = minOf(startIdx + pageable.pageSize, totalCount)
            val paginatedVenues = if (startIdx < totalCount) {
                venueList.subList(startIdx, endIdx)
            } else {
                emptyList()
            }
            PageImpl(paginatedVenues, pageable, totalCount.toLong())
        } else {
            venueRepository.findAll(pageable)
        }

        // Get upcoming event counts for all venues in one query
        val now = Instant.now(clock)
        val countMap = eventRepository.countUpcomingEventsByVenue(now)
            .mapNotNull { row ->
                val rawId = row["venueId"] ?: return@mapNotNull null
                val venueId = (rawId as? UUID) ?: UUID.fromString(rawId.toString())
                val count = (row["eventCount"] as? Number)?.toLong() ?: 0L
                venueId to count
            }.toMap()

        // Map venues to DTOs with upcoming event counts
        venuePage.map { venue ->
            val dto = venueMapper.toDto(venue)
            dto.copy(upcomingEventCount = countMap[venue.id] ?: 0L)
        }
    }

    fun findArtists(
        name: String? = null,
        local: Boolean? = null,
        pageable: Pageable
    ): EventResult<Page<ArtistDto>> = either {
        // Apply pagination if needed
        if (name != null || local != null) {
            val artists = when {
                name != null && local == true -> {
                    val artist = artistRepository.findByNameIgnoreCase(name)
                    if (artist != null && artist.isLocal) listOf(artist) else emptyList()
                }
                name != null -> {
                    val artist = artistRepository.findByNameIgnoreCase(name)
                    if (artist != null) listOf(artist) else emptyList()
                }
                local == true -> {
                    artistRepository.findByIsLocalTrue()
                }
                else -> emptyList()
            }

            val artistDtos = artistMapper.toDtoList(artists)
            val totalCount = artistDtos.size
            val startIdx = pageable.offset.toInt()
            val endIdx = minOf(startIdx + pageable.pageSize, totalCount)
            val paginatedDtos = if (startIdx < totalCount) {
                artistDtos.subList(startIdx, endIdx)
            } else {
                emptyList()
            }
            PageImpl(paginatedDtos, pageable, totalCount.toLong())
        } else {
            artistRepository.findAll(pageable).map { artistMapper.toDto(it) }
        }
    }

    private fun findRelatedEvents(targetEvent: EventEntity): List<EventDto> {
        val venue = targetEvent.venue ?: return emptyList()

        // Find events at the same venue within +/- 7 days of the target event's start time
        val sevenDaysInSeconds = 7L * 24 * 3600
        val startRange = targetEvent.startTime.minusSeconds(sevenDaysInSeconds)
        val endRange = targetEvent.startTime.plusSeconds(sevenDaysInSeconds)

        return eventRepository.findByVenueIdAndStartTimeBetweenAndStatus(
            venueId = venue.id,
            startTime = startRange,
            endTime = endRange,
            status = EventStatus.ACTIVE
        )
            .filter { event -> event.id != targetEvent.id }
            .sortedBy { it.startTime }
            .map { eventMapper.toDto(it) }
    }
}
