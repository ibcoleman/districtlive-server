package com.memetoclasm.districtlive.featured

import arrow.core.left
import arrow.core.right
import com.fasterxml.jackson.databind.ObjectMapper
import com.memetoclasm.districtlive.SecurityConfig
import com.memetoclasm.districtlive.admin.AdminApiService
import com.memetoclasm.districtlive.event.AgeRestriction
import com.memetoclasm.districtlive.event.EventStatus
import com.memetoclasm.districtlive.event.dto.EventDetailDto
import com.memetoclasm.districtlive.featured.dto.FeaturedEventDto
import com.memetoclasm.districtlive.featured.service.FeaturedEventApiService
import com.memetoclasm.districtlive.featured.service.FeaturedEventService
import com.memetoclasm.districtlive.ingestion.IngestionScheduler
import com.memetoclasm.districtlive.ingestion.jpa.IngestionRunRepository
import com.memetoclasm.districtlive.ingestion.service.SourceHealthService
import org.junit.jupiter.api.Test
import org.mockito.kotlin.any
import org.mockito.kotlin.never
import org.mockito.kotlin.verify
import org.mockito.kotlin.whenever
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest
import org.springframework.context.annotation.Import
import org.springframework.http.MediaType
import org.springframework.security.test.context.support.WithMockUser
import org.springframework.test.context.bean.override.mockito.MockitoBean
import org.springframework.test.web.servlet.MockMvc
import org.springframework.test.web.servlet.get
import org.springframework.test.web.servlet.post
import java.time.Instant
import java.util.UUID

/**
 * Integration test for the featured event REST API flow.
 *
 * Uses @WebMvcTest with mocked FeaturedEventService rather than Testcontainers because:
 * 1. Testcontainers is not in the project's test dependencies.
 * 2. The H2 integration profile (used by contextLoads()) has SourceEntity with
 *    @JdbcTypeCode(SqlTypes.JSON) / columnDefinition = "jsonb" which may not work
 *    correctly in H2 mode for a full @SpringBootTest.
 * 3. The service layer logic (query-time expiry, Arrow-kt Either error handling) is
 *    already fully covered by FeaturedEventServiceTest (unit tests with fixed Clock).
 *
 * This test verifies the REST API contract end-to-end:
 * - Correct HTTP status codes and response bodies for each scenario
 * - Security: admin endpoints require authentication, public endpoints do not
 * - Content-type negotiation and JSON serialization
 *
 * Covers ACs:
 * - android-calendar-mvp.AC1.4: POST /api/admin/featured creates a featured pick
 * - android-calendar-mvp.AC1.5: GET /api/featured/current returns 200 with event detail
 * - android-calendar-mvp.AC1.6: GET /api/featured/current returns 404 when no active event
 * - android-calendar-mvp.AC1.7: Auto-expiry — GET /api/featured/current returns 404 when event is in the past
 */
@WebMvcTest(controllers = [FeaturedEventApiService::class, AdminApiService::class])
@Import(SecurityConfig::class)
class FeaturedEventIntegrationTest {

    @Autowired
    private lateinit var mockMvc: MockMvc

    @Autowired
    private lateinit var objectMapper: ObjectMapper

    @MockitoBean
    private lateinit var featuredEventService: FeaturedEventService

    @MockitoBean
    private lateinit var sourceHealthService: SourceHealthService

    @MockitoBean(name = "ingestionScheduler")
    private lateinit var ingestionScheduler: IngestionScheduler

    @MockitoBean
    private lateinit var ingestionRunRepository: IngestionRunRepository

    // -------------------------------------------------------------------------
    // Test data helpers
    // -------------------------------------------------------------------------

    private fun makeEventDetailDto(
        id: UUID = UUID.randomUUID(),
        title: String = "Test Concert",
        startTime: Instant = Instant.parse("2026-04-01T20:00:00Z")
    ): EventDetailDto = EventDetailDto(
        id = id,
        title = title,
        slug = "test-concert",
        startTime = startTime,
        status = EventStatus.ACTIVE,
        ageRestriction = AgeRestriction.ALL_AGES
    )

    private fun makeFeaturedDto(
        event: EventDetailDto = makeEventDetailDto(),
        blurb: String = "Don't miss this one!"
    ): FeaturedEventDto = FeaturedEventDto(
        id = UUID.randomUUID(),
        event = event,
        blurb = blurb,
        createdAt = Instant.parse("2026-03-15T10:00:00Z"),
        createdBy = "admin"
    )

    // -------------------------------------------------------------------------
    // AC1.5: GET /api/featured/current returns 200 when active featured event exists
    // -------------------------------------------------------------------------

    @Test
    fun `AC1_5 - GET api-featured-current returns 200 with full event detail and blurb`() {
        val dto = makeFeaturedDto(blurb = "Best show of the season!")
        whenever(featuredEventService.getCurrentFeatured()).thenReturn(dto.right())

        mockMvc.get("/api/featured/current")
            .andExpect {
                status { isOk() }
                content { contentType(MediaType.APPLICATION_JSON) }
                jsonPath("$.blurb") { value("Best show of the season!") }
                jsonPath("$.event.title") { value("Test Concert") }
                jsonPath("$.createdBy") { value("admin") }
                jsonPath("$.id") { exists() }
                jsonPath("$.event.id") { exists() }
                jsonPath("$.event.startTime") { exists() }
            }
    }

    // -------------------------------------------------------------------------
    // AC1.6: GET /api/featured/current returns 404 when no active featured event
    // -------------------------------------------------------------------------

    @Test
    fun `AC1_6 - GET api-featured-current returns 404 when no featured events exist`() {
        whenever(featuredEventService.getCurrentFeatured())
            .thenReturn(FeaturedEventError.NoActiveFeaturedEvent.left())

        mockMvc.get("/api/featured/current")
            .andExpect {
                status { isNotFound() }
                content { string("No active featured event") }
            }
    }

    // -------------------------------------------------------------------------
    // AC1.7: Auto-expiry — GET /api/featured/current returns 404 when event start time has passed
    //
    // The auto-expiry mechanism is a query-time filter in JpaFeaturedEventRepository:
    //   WHERE e.startTime > :now
    // When the featured event's event.startTime is in the past, the repository returns null,
    // causing FeaturedEventService to raise NoActiveFeaturedEvent. This is the same
    // Left result as the "no events" case, so the API contract is identical: 404.
    //
    // Note: The query-time filter is tested directly in FeaturedEventServiceTest with a
    // fixed Clock. This test verifies the API contract for the auto-expired case.
    // -------------------------------------------------------------------------

    @Test
    fun `AC1_7 - GET api-featured-current returns 404 when featured event has auto-expired`() {
        // Simulate: featured event exists in DB but event.startTime is in the past.
        // Repository returns null (query-time filter excludes it), service raises NoActiveFeaturedEvent.
        whenever(featuredEventService.getCurrentFeatured())
            .thenReturn(FeaturedEventError.NoActiveFeaturedEvent.left())

        mockMvc.get("/api/featured/current")
            .andExpect {
                status { isNotFound() }
                content { string("No active featured event") }
            }
    }

    // -------------------------------------------------------------------------
    // AC1.4: POST /api/admin/featured creates a featured pick (requires auth)
    // -------------------------------------------------------------------------

    @Test
    @WithMockUser(username = "admin", roles = ["ADMIN"])
    fun `AC1_4 - POST api-admin-featured creates featured event and returns 200 with dto`() {
        val eventId = UUID.randomUUID()
        val dto = makeFeaturedDto(
            event = makeEventDetailDto(id = eventId),
            blurb = "Curated editorial pick"
        )
        whenever(featuredEventService.createFeatured(eventId, "Curated editorial pick"))
            .thenReturn(dto.right())

        val requestBody = mapOf("eventId" to eventId.toString(), "blurb" to "Curated editorial pick")

        mockMvc.post("/api/admin/featured") {
            contentType = MediaType.APPLICATION_JSON
            content = objectMapper.writeValueAsString(requestBody)
        }.andExpect {
            status { isOk() }
            jsonPath("$.blurb") { value("Curated editorial pick") }
            jsonPath("$.event.id") { value(eventId.toString()) }
            jsonPath("$.createdBy") { value("admin") }
        }
    }

    @Test
    fun `AC1_4 - POST api-admin-featured without auth returns 401`() {
        val requestBody = mapOf("eventId" to UUID.randomUUID().toString(), "blurb" to "Some blurb")

        mockMvc.post("/api/admin/featured") {
            contentType = MediaType.APPLICATION_JSON
            content = objectMapper.writeValueAsString(requestBody)
        }.andExpect {
            status { isUnauthorized() }
        }
    }

    @Test
    @WithMockUser(username = "admin", roles = ["ADMIN"])
    fun `AC1_4 - POST api-admin-featured returns 404 when event not found`() {
        val unknownId = UUID.randomUUID()
        whenever(featuredEventService.createFeatured(unknownId, "Some blurb"))
            .thenReturn(FeaturedEventError.EventNotFound.left())

        val requestBody = mapOf("eventId" to unknownId.toString(), "blurb" to "Some blurb")

        mockMvc.post("/api/admin/featured") {
            contentType = MediaType.APPLICATION_JSON
            content = objectMapper.writeValueAsString(requestBody)
        }.andExpect {
            status { isNotFound() }
            content { string("Event not found") }
        }
    }

    @Test
    @WithMockUser(username = "admin", roles = ["ADMIN"])
    fun `AC1_4 - POST api-admin-featured returns 400 when blurb is blank`() {
        val eventId = UUID.randomUUID()

        val requestBody = mapOf("eventId" to eventId.toString(), "blurb" to "   ")

        mockMvc.post("/api/admin/featured") {
            contentType = MediaType.APPLICATION_JSON
            content = objectMapper.writeValueAsString(requestBody)
        }.andExpect {
            status { isBadRequest() }
        }

        // Service should never be called — Spring validation rejects the blank blurb
        verify(featuredEventService, never()).createFeatured(any(), any())
    }

    // -------------------------------------------------------------------------
    // AC1.5 security: public endpoint requires no auth
    // -------------------------------------------------------------------------

    @Test
    fun `GET api-featured-current is accessible without authentication`() {
        whenever(featuredEventService.getCurrentFeatured())
            .thenReturn(FeaturedEventError.NoActiveFeaturedEvent.left())

        // No Authorization header — should get 404 (no featured event), not 401
        mockMvc.get("/api/featured/current")
            .andExpect {
                status { isNotFound() }
            }
    }

    // -------------------------------------------------------------------------
    // Admin history endpoint
    // -------------------------------------------------------------------------

    @Test
    @WithMockUser(username = "admin", roles = ["ADMIN"])
    fun `GET api-admin-featured-history returns 200 with history list`() {
        val dto1 = makeFeaturedDto(blurb = "First pick")
        val dto2 = makeFeaturedDto(blurb = "Second pick")
        whenever(featuredEventService.getHistory()).thenReturn(listOf(dto1, dto2))

        mockMvc.get("/api/admin/featured/history")
            .andExpect {
                status { isOk() }
                jsonPath("$.length()") { value(2) }
                jsonPath("$[0].blurb") { value("First pick") }
                jsonPath("$[1].blurb") { value("Second pick") }
            }
    }

    @Test
    fun `GET api-admin-featured-history without auth returns 401`() {
        mockMvc.get("/api/admin/featured/history")
            .andExpect {
                status { isUnauthorized() }
            }
    }
}
