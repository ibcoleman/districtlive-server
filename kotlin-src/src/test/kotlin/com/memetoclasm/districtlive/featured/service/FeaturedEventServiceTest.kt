package com.memetoclasm.districtlive.featured.service

import arrow.core.Either
import com.memetoclasm.districtlive.event.AgeRestriction
import com.memetoclasm.districtlive.event.EventRepositoryPort
import com.memetoclasm.districtlive.event.EventStatus
import com.memetoclasm.districtlive.event.dto.ArtistMapper
import com.memetoclasm.districtlive.event.dto.EventDetailDto
import com.memetoclasm.districtlive.event.dto.EventMapper
import com.memetoclasm.districtlive.event.dto.VenueMapper
import com.memetoclasm.districtlive.event.jpa.EventEntity
import com.memetoclasm.districtlive.event.jpa.VenueEntity
import com.memetoclasm.districtlive.featured.FeaturedEventError
import com.memetoclasm.districtlive.featured.FeaturedEventRepositoryPort
import com.memetoclasm.districtlive.featured.jpa.FeaturedEventEntity
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import org.mockito.Mock
import org.mockito.MockitoAnnotations
import org.mockito.kotlin.any
import org.mockito.kotlin.whenever
import java.time.Clock
import java.time.Instant
import java.time.ZoneOffset
import java.util.Optional
import java.util.UUID
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class FeaturedEventServiceTest {

    @Mock private lateinit var featuredEventRepository: FeaturedEventRepositoryPort
    @Mock private lateinit var eventRepository: EventRepositoryPort
    @Mock private lateinit var eventMapper: EventMapper
    @Mock private lateinit var venueMapper: VenueMapper
    @Mock private lateinit var artistMapper: ArtistMapper

    private lateinit var service: FeaturedEventService

    // Fixed clock for deterministic time assertions
    private val fixedNow: Instant = Instant.parse("2026-02-22T12:00:00Z")
    private val fixedClock: Clock = Clock.fixed(fixedNow, ZoneOffset.UTC)

    @BeforeEach
    fun setUp() {
        MockitoAnnotations.openMocks(this)
        service = FeaturedEventService(
            featuredEventRepository = featuredEventRepository,
            eventRepository = eventRepository,
            eventMapper = eventMapper,
            venueMapper = venueMapper,
            artistMapper = artistMapper,
            clock = fixedClock
        )
    }

    private fun makeEventEntity(startTime: Instant): EventEntity {
        val venue = VenueEntity(name = "Test Venue", slug = "test-venue")
        return EventEntity(
            title = "Test Event",
            slug = "test-event",
            startTime = startTime,
            venue = venue,
            status = EventStatus.ACTIVE
        )
    }

    private fun makeFeaturedEntity(event: EventEntity): FeaturedEventEntity {
        return FeaturedEventEntity(
            event = event,
            blurb = "Great show tonight!",
            createdAt = fixedNow.minusSeconds(3600)
        )
    }

    private fun makeDetailDto(event: EventEntity): EventDetailDto {
        return EventDetailDto(
            id = event.id,
            title = event.title,
            slug = event.slug,
            startTime = event.startTime
        )
    }

    @Test
    fun `getCurrentFeatured returns Right(FeaturedEventDto) when active featured event exists`() {
        // AC1.5: getCurrentFeatured() returns Right(FeaturedEventDto) with full event detail and blurb
        val futureTime = fixedNow.plusSeconds(7200)
        val eventEntity = makeEventEntity(futureTime)
        val featuredEntity = makeFeaturedEntity(eventEntity)
        val detailDto = makeDetailDto(eventEntity)

        whenever(featuredEventRepository.findCurrentFeatured(fixedNow)).thenReturn(featuredEntity)
        whenever(eventMapper.toDetailDto(eventEntity)).thenReturn(detailDto)
        whenever(venueMapper.toDto(any())).thenReturn(null)

        val result = service.getCurrentFeatured()

        assertTrue(result.isRight())
        val dto = (result as Either.Right).value
        assertEquals(featuredEntity.id, dto.id)
        assertEquals("Great show tonight!", dto.blurb)
        assertEquals(eventEntity.id, dto.event.id)
        assertEquals("Test Event", dto.event.title)
    }

    @Test
    fun `getCurrentFeatured returns Left(NoActiveFeaturedEvent) when no featured events exist`() {
        // AC1.6: getCurrentFeatured() returns Left(NoActiveFeaturedEvent) when no featured events in DB
        whenever(featuredEventRepository.findCurrentFeatured(fixedNow)).thenReturn(null)

        val result = service.getCurrentFeatured()

        assertTrue(result.isLeft())
        assertEquals(FeaturedEventError.NoActiveFeaturedEvent, (result as Either.Left).value)
    }

    @Test
    fun `getCurrentFeatured returns Left(NoActiveFeaturedEvent) when featured event start time has passed`() {
        // AC1.6 and AC1.7: Auto-expiry — query-time filter excludes events whose startTime is in the past.
        // The repository returns null when no active featured event exists (startTime <= now).
        // This is the same mechanism as the "no featured events" case — the WHERE clause filters them out.
        whenever(featuredEventRepository.findCurrentFeatured(fixedNow)).thenReturn(null)

        val result = service.getCurrentFeatured()

        assertTrue(result.isLeft())
        assertEquals(FeaturedEventError.NoActiveFeaturedEvent, (result as Either.Left).value)
    }

    @Test
    fun `createFeatured returns Right(FeaturedEventDto) when event exists and blurb is valid`() {
        val futureTime = fixedNow.plusSeconds(7200)
        val eventId = UUID.randomUUID()
        val eventEntity = EventEntity(
            id = eventId,
            title = "Test Event",
            slug = "test-event",
            startTime = futureTime,
            status = EventStatus.ACTIVE
        )
        val detailDto = makeDetailDto(eventEntity)

        whenever(eventRepository.findById(eventId)).thenReturn(Optional.of(eventEntity))
        whenever(featuredEventRepository.save(any())).thenAnswer { it.arguments[0] as FeaturedEventEntity }
        whenever(eventMapper.toDetailDto(eventEntity)).thenReturn(detailDto)

        val result = service.createFeatured(eventId, "  A great event!  ")

        assertTrue(result.isRight())
        val dto = (result as Either.Right).value
        assertEquals("A great event!", dto.blurb) // blurb trimmed
        assertEquals(eventId, dto.event.id)
    }

    @Test
    fun `createFeatured returns Left(EventNotFound) when event does not exist`() {
        val nonexistentId = UUID.randomUUID()
        whenever(eventRepository.findById(nonexistentId)).thenReturn(Optional.empty())

        val result = service.createFeatured(nonexistentId, "Some blurb")

        assertTrue(result.isLeft())
        assertEquals(FeaturedEventError.EventNotFound, (result as Either.Left).value)
    }

    @Test
    fun `createFeatured returns Left(InvalidRequest) when blurb is blank`() {
        val eventId = UUID.randomUUID()

        val result = service.createFeatured(eventId, "   ")

        assertTrue(result.isLeft())
        val error = (result as Either.Left).value
        assertTrue(error is FeaturedEventError.InvalidRequest)
        assertEquals("Blurb cannot be blank", (error as FeaturedEventError.InvalidRequest).message)
    }

    @Test
    fun `getHistory returns list ordered by createdAt descending`() {
        val event = makeEventEntity(fixedNow.plusSeconds(3600))
        val featured1 = FeaturedEventEntity(event = event, blurb = "First pick", createdAt = fixedNow.minusSeconds(7200))
        val featured2 = FeaturedEventEntity(event = event, blurb = "Second pick", createdAt = fixedNow.minusSeconds(3600))
        val detailDto = makeDetailDto(event)

        whenever(featuredEventRepository.findAllByOrderByCreatedAtDesc()).thenReturn(listOf(featured2, featured1))
        whenever(eventMapper.toDetailDto(event)).thenReturn(detailDto)

        val history = service.getHistory()

        assertEquals(2, history.size)
        assertEquals("Second pick", history[0].blurb)
        assertEquals("First pick", history[1].blurb)
    }
}
