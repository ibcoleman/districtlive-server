package com.memetoclasm.districtlive

import org.springframework.boot.info.BuildProperties
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RestController

@RestController
@RequestMapping("/api/version")
class VersionApiService(private val buildProperties: BuildProperties?) {

    @GetMapping
    fun getVersion() = mapOf(
        "build" to (buildProperties?.get("build.number") ?: "dev"),
        "commit" to (buildProperties?.get("build.commit") ?: "unknown"),
        "version" to (buildProperties?.version ?: "dev")
    )
}
