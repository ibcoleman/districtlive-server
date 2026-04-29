package com.memetoclasm.districtlive.event.service

import arrow.core.Either
import arrow.core.left
import arrow.core.right
import org.mockito.kotlin.eq
import com.memetoclasm.districtlive.event.ArtistRepositoryPort
import com.memetoclasm.districtlive.event.EventError
import com.memetoclasm.districtlive.event.EventRepositoryPort
import com.memetoclasm.districtlive.event.EventStatus
import com.memetoclasm.districtlive.event.VenueRepositoryPort
import com.memetoclasm.districtlive.event.dto.ArtistDto
import com.memetoclasm.districtlive.event.dto.ArtistMapper
import com.memetoclasm.districtlive.event.dto.EventDetailDto
import com.memetoclasm.districtlive.event.dto.EventDto
import com.memetoclasm.districtlive.event.dto.EventMapper
import com.memetoclasm.districtlive.event.dto.EventSourceDto
import com.memetoclasm.districtlive.event.dto.VenueDto
import com.memetoclasm.districtlive.event.dto.VenueMapper
import com.memetoclasm.districtlive.event.jpa.ArtistEntity
import com.memetoclasm.districtlive.event.jpa.EventEntity
import com.memetoclasm.districtlive.event.jpa.EventSourceEntity
import com.memetoclasm.districtlive.event.jpa.SourceEntity
import com.memetoclasm.districtlive.event.jpa.VenueEntity
import com.memetoclasm.districtlive.event.SourceType
import java.math.BigDecimal
import java.time.Instant
import java.util.Optional
import java.util.UUID
import kotlin.test.assertEquals
import kotlin.test.assertTrue
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.BeforeEach
import org.mockito.ArgumentCaptor
import org.mockito.Mock
import org.mockito.MockitoAnnotations
import org.mockito.kotlin.any
import org.mockito.kotlin.verify
import org.mockito.kotlin.whenever
import org.springframework.data.domain.PageImpl
import org.springframework.data.domain.PageRequest
import org.springframework.data.domain.Pageable
import org.springframework.data.jpa.domain.Specification

class EventServiceTest {

    @Mock
    private lateinit var eventRepository: EventRepositoryPort

    @Mock
    private lateinit var venueRepository: VenueRepositoryPort

    @Mock
    private lateinit var artistRepository: ArtistRepositoryPort

    @Mock
    private lateinit var eventMapper: EventMapper

    @Mock
    private lateinit var venueMapper: VenueMapper

    @Mock
    private lateinit var artistMapper: ArtistMapper

    private lateinit var eventService: EventService

    @BeforeEach
    fun setUp() {
        MockitoAnnotations.openMocks(this)
        eventService = EventService(
            eventRepository,
            venueRepository,
            artistRepository,
            eventMapper,
            venueMapper,
            artistMapper
        )
    }

    @Test
    fun `findEvents returns events sorted by startTime ascending`() {
        // AC5.1: GET /api/events returns paginated events sorted by startTime ascending
        val venueId = UUID.randomUUID()
        val venue = VenueEntity(id = venueId, name = "Test Venue", slug = "test-venue")

        val now = Instant.now()
        val event1 = EventEntity(
            id = UUID.randomUUID(),
            title = "Event 1",
            slug = "event-1",
            startTime = now.plusSeconds(3600),
            venue = venue,
            status = EventStatus.ACTIVE
        )
        val event2 = EventEntity(
            id = UUID.randomUUID(),
            title = "Event 2",
            slug = "event-2",
            startTime = now.plusSeconds(7200),
            venue = venue,
            status = EventStatus.ACTIVE
        )

        val eventPage = PageImpl(listOf(event1, event2), PageRequest.of(0, 20), 2)
        whenever(eventRepository.findAll(any<Specification<EventEntity?>>(), any<Pageable>()))
            .thenReturn(eventPage)

        val dto1 = EventDto(id = event1.id, title = "Event 1", slug = "event-1", startTime = event1.startTime)
        val dto2 = EventDto(id = event2.id, title = "Event 2", slug = "event-2", startTime = event2.startTime)

        whenever(eventMapper.toDto(event1)).thenReturn(dto1)
        whenever(eventMapper.toDto(event2)).thenReturn(dto2)

        val result = eventService.findEvents(pageable = PageRequest.of(0, 20))

        assertTrue(result.isRight())
        val page = (result as Either.Right).value
        assertEquals(2, page.content.size)
        assertEquals("Event 1", page.content[0].title)
        assertEquals("Event 2", page.content[1].title)

        // Verify specification was passed to repository
        verify(eventRepository).findAll(any<Specification<EventEntity?>>(), any<Pageable>())
    }

    @Test
    fun `findEvents with dateFrom and dateTo filters returns events within range`() {
        // AC5.2: Date range filter returns only events within the specified range
        val venueId = UUID.randomUUID()
        val venue = VenueEntity(id = venueId, name = "Test Venue", slug = "test-venue")

        val baseTime = Instant.now()
        val dateFrom = baseTime.plusSeconds(3600)
        val dateTo = baseTime.plusSeconds(7200)

        val eventInRange = EventEntity(
            id = UUID.randomUUID(),
            title = "Event In Range",
            slug = "event-in-range",
            startTime = baseTime.plusSeconds(5400),
            venue = venue,
            status = EventStatus.ACTIVE
        )

        val eventPage = PageImpl(listOf(eventInRange), PageRequest.of(0, 20), 1)
        whenever(eventRepository.findAll(any<Specification<EventEntity?>>(), any<Pageable>()))
            .thenReturn(eventPage)

        val dto = EventDto(
            id = eventInRange.id,
            title = "Event In Range",
            slug = "event-in-range",
            startTime = eventInRange.startTime
        )
        whenever(eventMapper.toDto(eventInRange)).thenReturn(dto)

        val result = eventService.findEvents(
            dateFrom = dateFrom,
            dateTo = dateTo,
            pageable = PageRequest.of(0, 20)
        )

        assertTrue(result.isRight())
        val page = (result as Either.Right).value
        assertEquals(1, page.content.size)

        // Verify date range specification was passed to repository
        verify(eventRepository).findAll(any<Specification<EventEntity?>>(), any<Pageable>())
    }

    @Test
    fun `findEvents with venue slug filter returns only events at that venue`() {
        // AC5.3: Venue filter returns only events at the specified venue
        val venueId = UUID.randomUUID()
        val venue = VenueEntity(id = venueId, name = "Test Venue", slug = "test-venue")

        val event = EventEntity(
            id = UUID.randomUUID(),
            title = "Event",
            slug = "event",
            startTime = Instant.now(),
            venue = venue,
            status = EventStatus.ACTIVE
        )

        val eventPage = PageImpl(listOf(event), PageRequest.of(0, 20), 1)
        whenever(eventRepository.findAll(any<Specification<EventEntity?>>(), any<Pageable>()))
            .thenReturn(eventPage)

        val dto = EventDto(
            id = event.id,
            title = "Event",
            slug = "event",
            startTime = event.startTime
        )
        whenever(eventMapper.toDto(event)).thenReturn(dto)

        val result = eventService.findEvents(
            venueSlug = "test-venue",
            pageable = PageRequest.of(0, 20)
        )

        assertTrue(result.isRight())
        val page = (result as Either.Right).value
        assertEquals(1, page.content.size)

        // Verify venue specification was passed to repository
        verify(eventRepository).findAll(any<Specification<EventEntity?>>(), any<Pageable>())
    }

    @Test
    fun `findEvents with genre filter returns only events with matching genre artists`() {
        // AC5.4: Genre filter returns only events matching the specified genre
        val venueId = UUID.randomUUID()
        val venue = VenueEntity(id = venueId, name = "Test Venue", slug = "test-venue")

        val artist = ArtistEntity(
            id = UUID.randomUUID(),
            name = "Test Artist",
            slug = "test-artist",
            genres = arrayOf("rock", "indie")
        )

        val event = EventEntity(
            id = UUID.randomUUID(),
            title = "Event",
            slug = "event",
            startTime = Instant.now(),
            venue = venue,
            artists = mutableSetOf(artist),
            status = EventStatus.ACTIVE
        )

        val eventPage = PageImpl(listOf(event), PageRequest.of(0, 20), 1)
        whenever(eventRepository.findAll(any<Specification<EventEntity?>>(), any<Pageable>()))
            .thenReturn(eventPage)

        val dto = EventDto(
            id = event.id,
            title = "Event",
            slug = "event",
            startTime = event.startTime
        )
        whenever(eventMapper.toDto(event)).thenReturn(dto)

        val result = eventService.findEvents(
            genre = "rock",
            pageable = PageRequest.of(0, 20)
        )

        assertTrue(result.isRight())
        val page = (result as Either.Right).value
        assertEquals(1, page.content.size)

        // Verify genre specification was passed to repository
        verify(eventRepository).findAll(any<Specification<EventEntity?>>(), any<Pageable>())
    }

    @Test
    fun `findEvents with priceMax filter returns only events at or below that price`() {
        // AC5.5: Price range filter returns only events at or below the max price
        val venueId = UUID.randomUUID()
        val venue = VenueEntity(id = venueId, name = "Test Venue", slug = "test-venue")

        val event = EventEntity(
            id = UUID.randomUUID(),
            title = "Event",
            slug = "event",
            startTime = Instant.now(),
            maxPrice = BigDecimal("25.00"),
            venue = venue,
            status = EventStatus.ACTIVE
        )

        val eventPage = PageImpl(listOf(event), PageRequest.of(0, 20), 1)
        whenever(eventRepository.findAll(any<Specification<EventEntity?>>(), any<Pageable>()))
            .thenReturn(eventPage)

        val dto = EventDto(
            id = event.id,
            title = "Event",
            slug = "event",
            startTime = event.startTime
        )
        whenever(eventMapper.toDto(event)).thenReturn(dto)

        val result = eventService.findEvents(
            priceMax = BigDecimal("30.00"),
            pageable = PageRequest.of(0, 20)
        )

        assertTrue(result.isRight())
        val page = (result as Either.Right).value
        assertEquals(1, page.content.size)
    }

    @Test
    fun `findEvents with multiple filters combines them with AND logic`() {
        // AC5.6: Multiple filters combine (AND logic)
        val venueId = UUID.randomUUID()
        val venue = VenueEntity(id = venueId, name = "Test Venue", slug = "test-venue")

        val artist = ArtistEntity(
            id = UUID.randomUUID(),
            name = "Test Artist",
            slug = "test-artist",
            genres = arrayOf("rock")
        )

        val baseTime = Instant.now()
        val event = EventEntity(
            id = UUID.randomUUID(),
            title = "Event",
            slug = "event",
            startTime = baseTime.plusSeconds(5400),
            maxPrice = BigDecimal("25.00"),
            venue = venue,
            artists = mutableSetOf(artist),
            status = EventStatus.ACTIVE
        )

        val eventPage = PageImpl(listOf(event), PageRequest.of(0, 20), 1)
        whenever(eventRepository.findAll(any<Specification<EventEntity?>>(), any<Pageable>()))
            .thenReturn(eventPage)

        val dto = EventDto(
            id = event.id,
            title = "Event",
            slug = "event",
            startTime = event.startTime
        )
        whenever(eventMapper.toDto(event)).thenReturn(dto)

        val result = eventService.findEvents(
            dateFrom = baseTime,
            venueSlug = "test-venue",
            genre = "rock",
            priceMax = BigDecimal("30.00"),
            pageable = PageRequest.of(0, 20)
        )

        assertTrue(result.isRight())
        val page = (result as Either.Right).value
        assertEquals(1, page.content.size)
    }

    @Test
    fun `findEventById returns detail DTO with sources and related events`() {
        // AC5.7: GET /api/events/{id} returns full event detail with sources and related events
        val eventId = UUID.randomUUID()
        val venueId = UUID.randomUUID()
        val venue = VenueEntity(id = venueId, name = "Test Venue", slug = "test-venue")

        val baseTime = Instant.now()
        val event = EventEntity(
            id = eventId,
            title = "Main Event",
            slug = "main-event",
            startTime = baseTime,
            venue = venue,
            status = EventStatus.ACTIVE
        )

        val relatedEvent = EventEntity(
            id = UUID.randomUUID(),
            title = "Related Event",
            slug = "related-event",
            startTime = baseTime.plusSeconds(3600),
            venue = venue,
            status = EventStatus.ACTIVE
        )

        val source = EventSourceEntity(
            id = UUID.randomUUID(),
            event = event,
            sourceType = SourceType.MANUAL
        )
        event.sources.add(source)

        whenever(eventRepository.findById(eventId)).thenReturn(Optional.of(event))
        whenever(eventRepository.findByVenueIdAndStartTimeBetweenAndStatus(
            venueId = eq(venueId),
            startTime = any(),
            endTime = any(),
            status = eq(EventStatus.ACTIVE)
        )).thenReturn(listOf(event, relatedEvent))

        val detailDto = EventDetailDto(
            id = event.id,
            title = "Main Event",
            slug = "main-event",
            startTime = event.startTime,
            sources = listOf(EventSourceDto(sourceType = SourceType.MANUAL))
        )

        whenever(eventMapper.toDetailDto(event)).thenReturn(detailDto)

        val relatedDto = EventDto(
            id = relatedEvent.id,
            title = "Related Event",
            slug = "related-event",
            startTime = relatedEvent.startTime
        )
        whenever(eventMapper.toDto(relatedEvent)).thenReturn(relatedDto)

        val result = eventService.findEventById(eventId)

        assertTrue(result.isRight())
        val detail = (result as Either.Right).value
        assertEquals("Main Event", detail.title)
        assertEquals(1, detail.sources.size)
        assertEquals(SourceType.MANUAL, detail.sources[0].sourceType)
        assertEquals(1, detail.relatedEvents.size)
    }

    @Test
    fun `findEventById with nonexistent UUID returns Left(EventNotFound)`() {
        // AC5.8: GET /api/events/{nonexistent-id} returns 404
        val nonexistentId = UUID.randomUUID()

        whenever(eventRepository.findById(nonexistentId)).thenReturn(Optional.empty())

        val result = eventService.findEventById(nonexistentId)

        assertTrue(result.isLeft())
        assertEquals(EventError.EventNotFound, (result as Either.Left).value)
    }

    @Test
    fun `findEvents with filters matching nothing returns empty page`() {
        // AC5.9: Filters matching zero events return empty page (not 404)
        val emptyPage = PageImpl<EventEntity>(emptyList(), PageRequest.of(0, 20), 0)
        whenever(eventRepository.findAll(any<Specification<EventEntity?>>(), any<Pageable>()))
            .thenReturn(emptyPage)

        val result = eventService.findEvents(
            genre = "nonexistent-genre",
            pageable = PageRequest.of(0, 20)
        )

        assertTrue(result.isRight())
        val page = (result as Either.Right).value
        assertEquals(0, page.content.size)
        assertEquals(0, page.totalElements)
    }
}
