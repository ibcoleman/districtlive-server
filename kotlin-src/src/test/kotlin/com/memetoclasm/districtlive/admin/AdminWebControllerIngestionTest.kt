package com.memetoclasm.districtlive.admin

import com.memetoclasm.districtlive.SecurityConfig
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest
import org.springframework.context.annotation.Import
import org.springframework.security.test.context.support.WithMockUser
import org.springframework.test.context.TestPropertySource
import org.springframework.test.web.servlet.MockMvc
import org.springframework.test.web.servlet.get

@WebMvcTest(AdminWebController::class)
@Import(SecurityConfig::class)
class AdminWebControllerIngestionTest {

    @Autowired
    private lateinit var mockMvc: MockMvc

    // AC3.1.2: Unauthenticated request returns 401 regardless of vite.dev flag
    @Test
    fun `GET admin-ingestion without auth returns 401`() {
        mockMvc.get("/admin/ingestion")
            .andExpect {
                status { isUnauthorized() }
            }
    }

    // AC3.2.1: Production mode — forwards to built index.html (vite.dev=false by default)
    @Test
    @WithMockUser(username = "admin")
    fun `GET admin-ingestion in production mode forwards to built index html`() {
        mockMvc.get("/admin/ingestion")
            .andExpect {
                status { isOk() }
                forwardedUrl("/src/pages/ingestion/index.html")
            }
    }
}

// AC3.1.1: Dev mode — redirects to Vite dev server
@WebMvcTest(AdminWebController::class)
@Import(SecurityConfig::class)
@TestPropertySource(properties = ["vite.dev=true", "vite.dev-server-url=http://localhost:5173"])
class AdminWebControllerIngestionDevModeTest {

    @Autowired
    private lateinit var mockMvc: MockMvc

    @Test
    @WithMockUser(username = "admin")
    fun `GET admin-ingestion in dev mode redirects to Vite dev server`() {
        mockMvc.get("/admin/ingestion")
            .andExpect {
                status { isFound() }
                redirectedUrl("http://localhost:5173/src/pages/ingestion/index.html")
            }
    }
}
