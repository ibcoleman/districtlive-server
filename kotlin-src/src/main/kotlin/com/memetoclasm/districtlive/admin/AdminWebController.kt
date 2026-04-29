package com.memetoclasm.districtlive.admin

import org.springframework.beans.factory.annotation.Value
import org.springframework.stereotype.Controller
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.RequestMapping

@Controller
class AdminWebController(
    @Value("\${vite.dev:false}") private val viteDev: Boolean,
    @Value("\${vite.dev-server-url:http://localhost:5173}") private val viteDevServerUrl: String
) {

    @GetMapping("/")
    fun root(): String = "redirect:/admin/ingestion"

    @GetMapping("/admin/featured")
    fun featuredPage(): String {
        return if (viteDev) {
            "redirect:${viteDevServerUrl}/src/pages/featured/index.html"
        } else {
            "forward:/src/pages/featured/index.html"
        }
    }

    @GetMapping("/admin/ingestion")
    fun ingestionDashboard(): String {
        return if (viteDev) {
            "redirect:${viteDevServerUrl}/src/pages/ingestion/index.html"
        } else {
            "forward:/src/pages/ingestion/index.html"
        }
    }
}
