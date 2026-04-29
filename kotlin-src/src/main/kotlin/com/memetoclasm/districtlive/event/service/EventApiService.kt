package com.memetoclasm.districtlive.event.service

import com.memetoclasm.districtlive.event.dto.ArtistDto
import com.memetoclasm.districtlive.event.dto.EventDetailDto
import com.memetoclasm.districtlive.event.dto.EventDto
import com.memetoclasm.districtlive.event.dto.VenueDto
import com.memetoclasm.districtlive.event.handleEventError
import java.math.BigDecimal
import java.time.Instant
import java.util.UUID
import org.slf4j.LoggerFactory
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import org.springframework.data.web.PageableDefault
import org.springframework.format.annotation.DateTimeFormat
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PathVariable
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RequestParam
import org.springframework.web.bind.annotation.RestController

@RestController
@RequestMapping(value = ["/api"])
class EventApiService(
    private val eventService: EventService
) {
    companion object {
        private val log = LoggerFactory.getLogger(EventApiService::class.java)
    }

    /**
     * Retrieves a paginated list of events with optional filtering and sorting.
     *
     * @param dateFrom optional start date for event filtering (ISO 8601 format)
     * @param dateTo optional end date for event filtering (ISO 8601 format)
     * @param venue optional venue slug to filter events by venue
     * @param genre optional genre to filter events by artist genre
     * @param neighborhood optional neighborhood to filter venues
     * @param priceMax optional maximum price to filter events
     * @param pageable pagination and sorting parameters (default: 20 per page, sorted by startTime)
     * @return paginated list of EventDto objects or error response
     */
    @GetMapping(value = ["/events"])
    fun getEvents(
        @RequestParam(required = false)
        @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME)
        dateFrom: Instant?,
        @RequestParam(required = false)
        @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME)
        dateTo: Instant?,
        @RequestParam(required = false) venue: String?,
        @RequestParam(required = false) genre: String?,
        @RequestParam(required = false) neighborhood: String?,
        @RequestParam(required = false) priceMax: BigDecimal?,
        @PageableDefault(size = 20, sort = ["startTime"]) pageable: Pageable
    ): ResponseEntity<Any> =
        eventService.findEvents(
            dateFrom = dateFrom,
            dateTo = dateTo,
            venueSlug = venue,
            genre = genre,
            neighborhood = neighborhood,
            priceMax = priceMax,
            pageable = pageable
        )
            .fold(::handleEventError) { eventPage ->
                ResponseEntity.ok(eventPage)
            }

    /**
     * Retrieves detailed information about a specific event.
     *
     * @param id the UUID of the event to retrieve
     * @return EventDetailDto with full details, sources, and related events, or 404 if not found
     */
    @GetMapping(value = ["/events/{id}"])
    fun getEventById(@PathVariable id: UUID): ResponseEntity<Any> =
        eventService.findEventById(id)
            .fold(::handleEventError) { eventDetail ->
                ResponseEntity.ok(eventDetail)
            }

    /**
     * Retrieves a paginated list of venues with optional neighborhood filtering.
     *
     * @param neighborhood optional neighborhood to filter venues
     * @param pageable pagination parameters (default: 20 per page)
     * @return paginated list of VenueDto objects or error response
     */
    @GetMapping(value = ["/venues"])
    fun getVenues(
        @RequestParam(required = false) neighborhood: String?,
        @PageableDefault(size = 20) pageable: Pageable
    ): ResponseEntity<Any> =
        eventService.findVenues(
            neighborhood = neighborhood,
            pageable = pageable
        )
            .fold(::handleEventError) { venuePage ->
                ResponseEntity.ok(venuePage)
            }

    /**
     * Retrieves a paginated list of artists with optional name and local filters.
     *
     * @param name optional artist name to filter artists
     * @param local optional filter for local artists only
     * @param pageable pagination parameters (default: 20 per page)
     * @return paginated list of ArtistDto objects or error response
     */
    @GetMapping(value = ["/artists"])
    fun getArtists(
        @RequestParam(required = false) name: String?,
        @RequestParam(required = false) local: Boolean?,
        @PageableDefault(size = 20) pageable: Pageable
    ): ResponseEntity<Any> =
        eventService.findArtists(
            name = name,
            local = local,
            pageable = pageable
        )
            .fold(::handleEventError) { artistPage ->
                ResponseEntity.ok(artistPage)
            }
}
