package com.memetoclasm.districtlive.event.service

import arrow.core.left
import arrow.core.right
import com.memetoclasm.districtlive.SecurityConfig
import com.memetoclasm.districtlive.event.EventError
import com.memetoclasm.districtlive.event.dto.ArtistDto
import com.memetoclasm.districtlive.event.dto.EventDetailDto
import com.memetoclasm.districtlive.event.dto.EventDto
import com.memetoclasm.districtlive.event.dto.EventSourceDto
import com.memetoclasm.districtlive.event.dto.VenueDto
import com.memetoclasm.districtlive.event.SourceType
import java.math.BigDecimal
import java.time.Instant
import java.util.UUID
import kotlin.test.assertEquals
import kotlin.test.assertTrue
import org.junit.jupiter.api.Test
import org.mockito.kotlin.any
import org.mockito.kotlin.anyOrNull
import org.mockito.kotlin.whenever
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest
import org.springframework.context.annotation.Import
import org.springframework.test.context.bean.override.mockito.MockitoBean
import org.springframework.data.domain.PageImpl
import org.springframework.data.domain.PageRequest
import org.springframework.data.domain.Pageable
import org.springframework.test.web.servlet.MockMvc
import org.springframework.test.web.servlet.get

@WebMvcTest(EventApiService::class)
@Import(SecurityConfig::class)
class EventApiServiceTest {

    @Autowired
    private lateinit var mockMvc: MockMvc

    @MockitoBean
    private lateinit var eventService: EventService

    @Test
    fun `GET api-events with nonexistent id returns 404`() {
        val nonexistentId = UUID.randomUUID()
        whenever(eventService.findEventById(nonexistentId))
            .thenReturn(EventError.EventNotFound.left())

        mockMvc.get("/api/events/$nonexistentId")
            .andExpect {
                status { isNotFound() }
            }
    }

    @Test
    fun `GET api-events with filters matching nothing returns empty page with 200`() {
        val emptyPage = PageImpl<EventDto>(emptyList(), PageRequest.of(0, 20), 0)
        whenever(eventService.findEvents(
            anyOrNull(), anyOrNull(), anyOrNull(), anyOrNull(), anyOrNull(), anyOrNull(), any(), any()
        )).thenReturn(emptyPage.right())

        mockMvc.get("/api/events?genre=nonexistent-genre")
            .andExpect {
                status { isOk() }
                jsonPath("$.content.length()") { value(0) }
                jsonPath("$.totalElements") { value(0) }
            }
    }

    @Test
    fun `GET api-events without Authorization header returns 200`() {
        val eventDto = EventDto(
            id = UUID.randomUUID(),
            title = "Test Event",
            slug = "test-event",
            startTime = Instant.now()
        )
        val eventPage = PageImpl(listOf(eventDto), PageRequest.of(0, 20), 1)
        whenever(eventService.findEvents(
            anyOrNull(), anyOrNull(), anyOrNull(), anyOrNull(), anyOrNull(), anyOrNull(), any(), any()
        )).thenReturn(eventPage.right())

        mockMvc.get("/api/events")
            .andExpect {
                status { isOk() }
                jsonPath("$.content[0].title") { value("Test Event") }
            }
    }

    // OpenAPI docs test requires full application context (not @WebMvcTest).
    // Moved to integration tests (Phase 8).
    @Test
    fun `GET v3-api-docs is not available in WebMvcTest slice`() {
        // SpringDoc endpoints require full boot context, not WebMvcTest slice
        mockMvc.get("/v3/api-docs")
            .andExpect {
                status { isNotFound() }
            }
    }

    @Test
    fun `GET api-venues without Authorization header returns 200`() {
        val venueDto = VenueDto(
            id = UUID.randomUUID(),
            name = "Test Venue",
            slug = "test-venue",
            neighborhood = "Downtown",
            websiteUrl = "https://test.com"
        )
        val venuePage = PageImpl(listOf(venueDto), PageRequest.of(0, 20), 1)
        whenever(eventService.findVenues(
            anyOrNull(), any()
        )).thenReturn(venuePage.right())

        mockMvc.get("/api/venues")
            .andExpect {
                status { isOk() }
                jsonPath("$.content[0].name") { value("Test Venue") }
            }
    }

    @Test
    fun `GET api-artists without Authorization header returns 200`() {
        val artistDto = ArtistDto(
            id = UUID.randomUUID(),
            name = "Test Artist",
            slug = "test-artist",
            genres = listOf("rock"),
            isLocal = true
        )
        val artistPage = PageImpl(listOf(artistDto), PageRequest.of(0, 20), 1)
        whenever(eventService.findArtists(
            anyOrNull(), anyOrNull(), any()
        )).thenReturn(artistPage.right())

        mockMvc.get("/api/artists")
            .andExpect {
                status { isOk() }
                jsonPath("$.content[0].name") { value("Test Artist") }
            }
    }

    @Test
    fun `GET api-events with event detail returns 200 with full details`() {
        val eventId = UUID.randomUUID()
        val detailDto = EventDetailDto(
            id = eventId,
            title = "Detailed Event",
            slug = "detailed-event",
            startTime = Instant.now(),
            sources = listOf(EventSourceDto(sourceType = SourceType.MANUAL)),
            relatedEvents = listOf(
                EventDto(
                    id = UUID.randomUUID(),
                    title = "Related Event",
                    slug = "related-event",
                    startTime = Instant.now().plusSeconds(3600)
                )
            )
        )
        whenever(eventService.findEventById(eventId))
            .thenReturn(detailDto.right())

        mockMvc.get("/api/events/$eventId")
            .andExpect {
                status { isOk() }
                jsonPath("$.title") { value("Detailed Event") }
                jsonPath("$.sources.length()") { value(1) }
                jsonPath("$.relatedEvents.length()") { value(1) }
            }
    }

    @Test
    fun `GET api-events with valid filters returns 200 with filtered events`() {
        val eventDto = EventDto(
            id = UUID.randomUUID(),
            title = "Filtered Event",
            slug = "filtered-event",
            startTime = Instant.now(),
            maxPrice = BigDecimal("25.00")
        )
        val eventPage = PageImpl(listOf(eventDto), PageRequest.of(0, 20), 1)
        whenever(eventService.findEvents(
            anyOrNull(), anyOrNull(), anyOrNull(), anyOrNull(), anyOrNull(), anyOrNull(), any(), any()
        )).thenReturn(eventPage.right())

        mockMvc.get("/api/events?genre=rock&priceMax=30.00&page=0&size=20")
            .andExpect {
                status { isOk() }
                jsonPath("$.content[0].title") { value("Filtered Event") }
            }
    }
}
