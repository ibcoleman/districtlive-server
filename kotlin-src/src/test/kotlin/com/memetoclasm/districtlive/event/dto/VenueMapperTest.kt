package com.memetoclasm.districtlive.event.dto

import com.memetoclasm.districtlive.event.jpa.VenueEntity
import org.junit.jupiter.api.Test
import org.mapstruct.factory.Mappers
import kotlin.test.assertEquals

class VenueMapperTest {

    private val venueMapper: VenueMapper = Mappers.getMapper(VenueMapper::class.java)

    @Test
    fun `toDto uses displayName when displayName is set`() {
        // venue-name-sanitize.AC2.1: When display_name is set, VenueDto.name returns display_name
        val entity = VenueEntity(
            name = "Trump Kennedy Center - Concert Hall",
            slug = "trump-kennedy-center-concert-hall",
            displayName = "The Kennedy Center"
        )

        val dto = venueMapper.toDto(entity)

        assertEquals("The Kennedy Center", dto.name)
    }

    @Test
    fun `toDto uses displaySlug when displaySlug is set`() {
        // venue-name-sanitize.AC2.2: When display_slug is set, VenueDto.slug returns display_slug
        val entity = VenueEntity(
            name = "Trump Kennedy Center - Concert Hall",
            slug = "trump-kennedy-center-concert-hall",
            displaySlug = "the-kennedy-center"
        )

        val dto = venueMapper.toDto(entity)

        assertEquals("the-kennedy-center", dto.slug)
    }

    @Test
    fun `toDto returns source name when displayName is null`() {
        // venue-name-sanitize.AC2.3: When display_name is NULL, VenueDto.name returns the source name
        val entity = VenueEntity(
            name = "Black Cat",
            slug = "black-cat",
            displayName = null
        )

        val dto = venueMapper.toDto(entity)

        assertEquals("Black Cat", dto.name)
    }

    @Test
    fun `toDto returns source slug when displaySlug is null`() {
        // venue-name-sanitize.AC2.4: When display_slug is NULL, VenueDto.slug returns the source slug
        val entity = VenueEntity(
            name = "Black Cat",
            slug = "black-cat",
            displaySlug = null
        )

        val dto = venueMapper.toDto(entity)

        assertEquals("black-cat", dto.slug)
    }
}
