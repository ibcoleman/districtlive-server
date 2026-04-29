package com.memetoclasm.districtlive.event.jpa

import org.springframework.data.jpa.repository.JpaRepository
import org.springframework.stereotype.Repository
import java.util.UUID

@Repository
interface JpaSourceRepository : JpaRepository<SourceEntity, UUID> {
    fun findByName(name: String): SourceEntity?
    fun findByHealthyTrue(): List<SourceEntity>
    fun findByHealthyFalse(): List<SourceEntity>
}
