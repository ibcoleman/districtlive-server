package com.memetoclasm.districtlive.event

import com.memetoclasm.districtlive.event.jpa.VenueEntity
import org.springframework.data.domain.Page
import org.springframework.data.domain.Pageable
import java.util.UUID

interface VenueRepositoryPort {
    fun findById(id: UUID): java.util.Optional<VenueEntity>
    fun findBySlug(slug: String): VenueEntity?
    fun findByNeighborhood(neighborhood: String): List<VenueEntity>
    fun findByNameIgnoreCase(name: String): VenueEntity?
    fun findAll(pageable: Pageable): Page<VenueEntity>
    fun findAll(): List<VenueEntity>
    fun save(entity: VenueEntity): VenueEntity
}
