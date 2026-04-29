package com.memetoclasm.districtlive.event.dto

import com.memetoclasm.districtlive.event.jpa.EventEntity
import com.memetoclasm.districtlive.event.jpa.EventSourceEntity
import org.mapstruct.Mapper
import org.mapstruct.Mapping

@Mapper(componentModel = "spring", uses = [VenueMapper::class, ArtistMapper::class])
interface EventMapper {

    @Mapping(target = "artists", source = "artists")
    fun toDto(entity: EventEntity): EventDto

    @Mapping(target = "artists", source = "artists")
    @Mapping(target = "sources", source = "sources")
    @Mapping(target = "relatedEvents", expression = "java(java.util.Collections.emptyList())")
    fun toDetailDto(entity: EventEntity): EventDetailDto

    fun toSourceDto(entity: EventSourceEntity): EventSourceDto

    fun toDtoList(entities: List<EventEntity>): List<EventDto>
}
