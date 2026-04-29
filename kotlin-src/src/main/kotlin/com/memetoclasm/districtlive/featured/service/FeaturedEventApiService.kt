package com.memetoclasm.districtlive.featured.service

import com.memetoclasm.districtlive.featured.handleFeaturedEventError
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RestController

@RestController
@RequestMapping(value = ["/api/featured"])
class FeaturedEventApiService(
    private val featuredEventService: FeaturedEventService
) {

    @GetMapping(value = ["/current"])
    fun getCurrentFeatured(): ResponseEntity<Any> {
        return featuredEventService.getCurrentFeatured().fold(
            ifLeft = { handleFeaturedEventError(it) },
            ifRight = { ResponseEntity.ok(it) }
        )
    }
}
