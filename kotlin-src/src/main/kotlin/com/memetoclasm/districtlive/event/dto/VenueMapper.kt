package com.memetoclasm.districtlive.event.dto

import com.memetoclasm.districtlive.event.jpa.VenueEntity
import org.mapstruct.Mapper
import org.mapstruct.Mapping

@Mapper(componentModel = "spring")
interface VenueMapper {

    @Mapping(target = "name", source = "effectiveName")
    @Mapping(target = "slug", source = "effectiveSlug")
    @Mapping(target = "upcomingEventCount", constant = "0L")
    fun toDto(entity: VenueEntity): VenueDto

    fun toDtoList(entities: List<VenueEntity>): List<VenueDto>
}
