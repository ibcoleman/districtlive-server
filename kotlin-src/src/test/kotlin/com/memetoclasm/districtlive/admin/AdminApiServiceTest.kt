package com.memetoclasm.districtlive.admin

import com.memetoclasm.districtlive.SecurityConfig
import com.memetoclasm.districtlive.event.SourceType
import com.memetoclasm.districtlive.event.jpa.SourceEntity
import com.memetoclasm.districtlive.featured.service.FeaturedEventService
import com.memetoclasm.districtlive.ingestion.IngestionScheduler
import com.memetoclasm.districtlive.ingestion.jpa.IngestionRunEntity
import com.memetoclasm.districtlive.ingestion.jpa.IngestionRunRepository
import com.memetoclasm.districtlive.ingestion.jpa.IngestionRunStatus
import com.memetoclasm.districtlive.ingestion.service.SourceHealthService
import org.junit.jupiter.api.Test
import org.mockito.kotlin.whenever
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest
import org.springframework.context.annotation.Import
import org.springframework.security.test.context.support.WithMockUser
import org.springframework.test.context.bean.override.mockito.MockitoBean
import org.springframework.test.web.servlet.MockMvc
import org.springframework.test.web.servlet.get
import org.springframework.test.web.servlet.post
import java.time.Instant
import java.util.UUID

@WebMvcTest(AdminApiService::class)
@Import(SecurityConfig::class)
class AdminApiServiceTest {

    @Autowired
    private lateinit var mockMvc: MockMvc

    @MockitoBean
    private lateinit var sourceHealthService: SourceHealthService

    @MockitoBean(name = "ingestionScheduler")
    private lateinit var ingestionScheduler: IngestionScheduler

    @MockitoBean
    private lateinit var ingestionRunRepository: IngestionRunRepository

    @MockitoBean
    private lateinit var featuredEventService: FeaturedEventService

    // AC6.3: Admin endpoints return 401 without token
    @Test
    fun `GET api-admin-sources without auth returns 401`() {
        mockMvc.get("/api/admin/sources")
            .andExpect {
                status { isUnauthorized() }
            }
    }

    @Test
    fun `POST api-admin-ingest-trigger without auth returns 401`() {
        mockMvc.post("/api/admin/ingest/trigger/ticketmaster")
            .andExpect {
                status { isUnauthorized() }
            }
    }

    @Test
    fun `GET api-admin-sources-history without auth returns 401`() {
        val sourceId = UUID.randomUUID()
        mockMvc.get("/api/admin/sources/$sourceId/history")
            .andExpect {
                status { isUnauthorized() }
            }
    }

    // AC6.2: Admin endpoints work with valid authentication
    @Test
    @WithMockUser(username = "admin")
    fun `GET api-admin-sources with auth returns 200 with source list`() {
        val sources = listOf(
            SourceEntity(
                name = "ticketmaster",
                sourceType = SourceType.TICKETMASTER_API,
                healthy = true,
                consecutiveFailures = 0,
                lastSuccessAt = Instant.now()
            )
        )
        whenever(sourceHealthService.getAllSourceHealth()).thenReturn(sources)

        mockMvc.get("/api/admin/sources")
            .andExpect {
                status { isOk() }
                jsonPath("$[0].name") { value("ticketmaster") }
                jsonPath("$[0].healthy") { value(true) }
            }
    }

    @Test
    @WithMockUser(username = "admin")
    fun `GET api-admin-sources-id-history with auth returns 200 with run history`() {
        val sourceId = UUID.randomUUID()
        val runs = listOf(
            IngestionRunEntity(
                sourceId = sourceId,
                status = IngestionRunStatus.SUCCESS,
                eventsFetched = 10,
                eventsCreated = 5,
                startedAt = Instant.now().minusSeconds(3600),
                completedAt = Instant.now().minusSeconds(3500)
            )
        )
        whenever(ingestionRunRepository.findBySourceIdOrderByStartedAtDesc(sourceId)).thenReturn(runs)

        mockMvc.get("/api/admin/sources/$sourceId/history")
            .andExpect {
                status { isOk() }
                jsonPath("$[0].status") { value("SUCCESS") }
                jsonPath("$[0].eventsFetched") { value(10) }
                jsonPath("$[0].eventsCreated") { value(5) }
            }
    }

    @Test
    @WithMockUser(username = "admin")
    fun `POST api-admin-ingest-trigger with auth returns 200`() {
        mockMvc.post("/api/admin/ingest/trigger/ticketmaster")
            .andExpect {
                status { isOk() }
                jsonPath("$.status") { value("triggered") }
                jsonPath("$.sourceId") { value("ticketmaster") }
            }
    }

    @Test
    @WithMockUser(username = "admin")
    fun `POST api-admin-ingest-trigger with unknown source returns 400`() {
        whenever(ingestionScheduler.runSingleConnector("unknown")).thenThrow(
            IllegalArgumentException("No connector found with sourceId 'unknown'")
        )

        mockMvc.post("/api/admin/ingest/trigger/unknown")
            .andExpect {
                status { isBadRequest() }
            }
    }

    @Test
    @WithMockUser(username = "admin")
    fun `GET api-admin-sources-id returns 404 for unknown source`() {
        whenever(sourceHealthService.getAllSourceHealth()).thenReturn(emptyList())

        mockMvc.get("/api/admin/sources/${UUID.randomUUID()}")
            .andExpect {
                status { isNotFound() }
            }
    }
}
