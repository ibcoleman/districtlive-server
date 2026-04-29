package com.memetoclasm.districtlive.featured.service

import arrow.core.left
import arrow.core.right
import com.memetoclasm.districtlive.SecurityConfig
import com.memetoclasm.districtlive.event.AgeRestriction
import com.memetoclasm.districtlive.event.EventStatus
import com.memetoclasm.districtlive.event.dto.EventDetailDto
import com.memetoclasm.districtlive.featured.FeaturedEventError
import com.memetoclasm.districtlive.featured.dto.FeaturedEventDto
import org.junit.jupiter.api.Test
import org.mockito.kotlin.whenever
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest
import org.springframework.context.annotation.Import
import org.springframework.test.context.bean.override.mockito.MockitoBean
import org.springframework.test.web.servlet.MockMvc
import org.springframework.test.web.servlet.get
import java.time.Instant
import java.util.UUID

@WebMvcTest(FeaturedEventApiService::class)
@Import(SecurityConfig::class)
class FeaturedEventApiServiceTest {

    @Autowired
    private lateinit var mockMvc: MockMvc

    @MockitoBean
    private lateinit var featuredEventService: FeaturedEventService

    private fun makeEventDetailDto(): EventDetailDto {
        return EventDetailDto(
            id = UUID.randomUUID(),
            title = "Featured Show",
            slug = "featured-show",
            startTime = Instant.parse("2026-02-22T20:00:00Z"),
            status = EventStatus.ACTIVE,
            ageRestriction = AgeRestriction.ALL_AGES
        )
    }

    @Test
    fun `GET api-featured-current returns 200 with FeaturedEventDto when service returns Right`() {
        // AC1.5: GET /api/featured/current returns 200 with event detail and blurb when active featured event exists
        val featuredId = UUID.randomUUID()
        val dto = FeaturedEventDto(
            id = featuredId,
            event = makeEventDetailDto(),
            blurb = "Don't miss this show!",
            createdAt = Instant.parse("2026-02-22T10:00:00Z"),
            createdBy = "admin"
        )
        whenever(featuredEventService.getCurrentFeatured()).thenReturn(dto.right())

        mockMvc.get("/api/featured/current")
            .andExpect {
                status { isOk() }
                jsonPath("$.id") { value(featuredId.toString()) }
                jsonPath("$.blurb") { value("Don't miss this show!") }
                jsonPath("$.event.title") { value("Featured Show") }
                jsonPath("$.createdBy") { value("admin") }
            }
    }

    @Test
    fun `GET api-featured-current returns 404 with message when service returns Left(NoActiveFeaturedEvent)`() {
        // AC1.6: GET /api/featured/current returns 404 when no active featured event exists
        whenever(featuredEventService.getCurrentFeatured())
            .thenReturn(FeaturedEventError.NoActiveFeaturedEvent.left())

        mockMvc.get("/api/featured/current")
            .andExpect {
                status { isNotFound() }
                content { string("No active featured event") }
            }
    }

    @Test
    fun `GET api-featured-current does not require authentication`() {
        // AC1.5 security: the endpoint is public (no auth required)
        val dto = FeaturedEventDto(
            id = UUID.randomUUID(),
            event = makeEventDetailDto(),
            blurb = "Public endpoint test",
            createdAt = Instant.parse("2026-02-22T10:00:00Z"),
            createdBy = "admin"
        )
        whenever(featuredEventService.getCurrentFeatured()).thenReturn(dto.right())

        // No Authorization header — should still return 200
        mockMvc.get("/api/featured/current")
            .andExpect {
                status { isOk() }
            }
    }
}
