package com.memetoclasm.districtlive.event.dto

import com.memetoclasm.districtlive.event.jpa.ArtistEntity
import org.mapstruct.Mapper
import org.mapstruct.Mapping

@Mapper(componentModel = "spring")
interface ArtistMapper {

    @Mapping(target = "genres", expression = "java(java.util.Arrays.asList(entity.getGenres()))")
    @Mapping(target = "canonicalName", source = "entity.canonicalName")
    @Mapping(target = "imageUrl", source = "entity.imageUrl")
    fun toDto(entity: ArtistEntity): ArtistDto

    fun toDtoList(entities: List<ArtistEntity>): List<ArtistDto>
}
