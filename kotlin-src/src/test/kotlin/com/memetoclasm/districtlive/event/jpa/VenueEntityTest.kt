package com.memetoclasm.districtlive.event.jpa

import kotlin.test.assertEquals
import org.junit.jupiter.api.Test

class VenueEntityTest {

    private fun venueEntity(
        name: String = "Black Cat",
        slug: String = "black-cat",
        displayName: String? = null,
        displaySlug: String? = null
    ) = VenueEntity(
        name = name,
        slug = slug,
        displayName = displayName,
        displaySlug = displaySlug
    )

    @Test
    fun `effectiveName returns displayName when displayName is set`() {
        // venue-name-sanitize.AC2.1
        val venue = venueEntity(
            name = "Trump Kennedy Center - Concert Hall",
            slug = "trump-kennedy-center-concert-hall",
            displayName = "The Kennedy Center"
        )
        assertEquals("The Kennedy Center", venue.effectiveName)
    }

    @Test
    fun `effectiveSlug returns displaySlug when displaySlug is set`() {
        // venue-name-sanitize.AC2.2
        val venue = venueEntity(
            name = "Trump Kennedy Center - Concert Hall",
            slug = "trump-kennedy-center-concert-hall",
            displaySlug = "the-kennedy-center"
        )
        assertEquals("the-kennedy-center", venue.effectiveSlug)
    }

    @Test
    fun `effectiveName returns source name when displayName is null`() {
        // venue-name-sanitize.AC2.3
        val venue = venueEntity(name = "Black Cat", slug = "black-cat", displayName = null)
        assertEquals("Black Cat", venue.effectiveName)
    }

    @Test
    fun `effectiveSlug returns source slug when displaySlug is null`() {
        // venue-name-sanitize.AC2.4
        val venue = venueEntity(name = "Black Cat", slug = "black-cat", displaySlug = null)
        assertEquals("black-cat", venue.effectiveSlug)
    }
}
