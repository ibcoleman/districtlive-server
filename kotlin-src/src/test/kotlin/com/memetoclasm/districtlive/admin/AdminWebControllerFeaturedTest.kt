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
class AdminWebControllerFeaturedTest {

    @Autowired
    private lateinit var mockMvc: MockMvc

    // AC4.1.2: Unauthenticated request returns 401
    @Test
    fun `GET admin-featured without auth returns 401`() {
        mockMvc.get("/admin/featured")
            .andExpect {
                status { isUnauthorized() }
            }
    }

    // AC4.2.1: Production mode — forwards to built index.html (vite.dev=false by default)
    @Test
    @WithMockUser(username = "admin")
    fun `GET admin-featured in production mode forwards to built index html`() {
        mockMvc.get("/admin/featured")
            .andExpect {
                status { isOk() }
                forwardedUrl("/src/pages/featured/index.html")
            }
    }
}

// AC4.1.1: Dev mode — redirects to Vite dev server
@WebMvcTest(AdminWebController::class)
@Import(SecurityConfig::class)
@TestPropertySource(properties = ["vite.dev=true", "vite.dev-server-url=http://localhost:5173"])
class AdminWebControllerFeaturedDevModeTest {

    @Autowired
    private lateinit var mockMvc: MockMvc

    @Test
    @WithMockUser(username = "admin")
    fun `GET admin-featured in dev mode redirects to Vite dev server`() {
        mockMvc.get("/admin/featured")
            .andExpect {
                status { isFound() }
                redirectedUrl("http://localhost:5173/src/pages/featured/index.html")
            }
    }
}
