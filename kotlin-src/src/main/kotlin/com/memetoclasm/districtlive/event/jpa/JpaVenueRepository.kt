package com.memetoclasm.districtlive.event.jpa

import com.memetoclasm.districtlive.event.VenueRepositoryPort
import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.stereotype.Repository
import java.util.UUID

@Repository
interface JpaVenueRepository : JpaRepository<VenueEntity, UUID>, VenueRepositoryPort
