package com.memetoclasm.districtlive.event.jpa

import arrow.core.Either
import com.memetoclasm.districtlive.event.SlugUtils.slugify
import com.memetoclasm.districtlive.event.*
import jakarta.persistence.EntityManager
import jakarta.persistence.PersistenceContext
import org.slf4j.LoggerFactory
import org.springframework.dao.DataIntegrityViolationException
import org.springframework.transaction.annotation.Transactional
import java.time.Instant

open class JpaEventRepositoryImpl(
    @PersistenceContext private val entityManager: EntityManager,
    private val venueRepository: JpaVenueRepository,
    private val artistRepository: JpaArtistRepository,
    private val eventSourceRepository: JpaEventSourceRepository
) {
    private val logger = LoggerFactory.getLogger(JpaEventRepositoryImpl::class.java)

    @Transactional
    open fun upsertEvent(command: EventUpsertCommand): Either<EventError, UpsertResult> {
        return Either.catch {
            val venue = command.venueName?.let { resolveVenue(it, command.venueAddress) }
            val artists = command.artistNames.map { resolveArtist(it) }.toMutableSet()

            val existing = findEventBySlug(command.slug)

            if (existing != null) {
                existing.title = command.title
                existing.description = command.description
                existing.startTime = command.startTime
                existing.endTime = command.endTime
                existing.doorsTime = command.doorsTime
                existing.minPrice = command.minPrice
                existing.maxPrice = command.maxPrice
                existing.priceTier = command.priceTier
                existing.ticketUrl = command.ticketUrl
                existing.imageUrl = command.imageUrl
                existing.ageRestriction = command.ageRestriction
                existing.venue = venue
                existing.artists = artists
                existing.updatedAt = Instant.now()
                addSourceAttributions(existing, command.sourceAttributions)
                // No explicit merge/save needed — entity is managed within @Transactional,
                // JPA dirty checking flushes changes at commit
                UpsertResult.Updated(existing.id)
            } else {
                val newEvent = EventEntity(
                    title = command.title,
                    slug = command.slug,
                    description = command.description,
                    startTime = command.startTime,
                    endTime = command.endTime,
                    doorsTime = command.doorsTime,
                    minPrice = command.minPrice,
                    maxPrice = command.maxPrice,
                    priceTier = command.priceTier,
                    ticketUrl = command.ticketUrl,
                    imageUrl = command.imageUrl,
                    ageRestriction = command.ageRestriction,
                    status = EventStatus.ACTIVE,
                    venue = venue,
                    artists = artists
                )
                entityManager.persist(newEvent)
                entityManager.flush()
                addSourceAttributions(newEvent, command.sourceAttributions)
                UpsertResult.Created(newEvent.id)
            }
        }.mapLeft { e ->
            logger.error("Persistence error for slug '{}': {}", command.slug, e.message, e)
            EventError.PersistenceError(e.message ?: "Unknown persistence error")
        }
    }

    private fun findEventBySlug(slug: String): EventEntity? {
        return entityManager.createQuery(
            "SELECT e FROM EventEntity e WHERE e.slug = :slug",
            EventEntity::class.java
        ).setParameter("slug", slug)
            .resultList
            .firstOrNull()
    }

    private fun resolveVenue(name: String, address: String?): VenueEntity {
        venueRepository.findByNameIgnoreCase(name)?.let { return it }
        val slug = slugify(name)
        venueRepository.findBySlug(slug)?.let { return it }
        logger.info("Auto-creating venue '{}' with slug '{}'", name, slug)
        return try {
            venueRepository.save(VenueEntity(name = name, slug = slug, address = address))
        } catch (e: DataIntegrityViolationException) {
            logger.debug("Venue '{}' created concurrently, re-querying", slug)
            entityManager.clear()
            venueRepository.findBySlug(slug)
                ?: throw IllegalStateException("Venue '$slug' not found after constraint violation", e)
        }
    }

    private fun resolveArtist(name: String): ArtistEntity {
        artistRepository.findByNameIgnoreCase(name)?.let { return it }
        val slug = slugify(name)
        artistRepository.findBySlug(slug)?.let { return it }
        return try {
            artistRepository.save(ArtistEntity(name = name, slug = slug))
        } catch (e: DataIntegrityViolationException) {
            logger.debug("Artist '{}' created concurrently, re-querying", slug)
            entityManager.clear()
            artistRepository.findBySlug(slug)
                ?: throw IllegalStateException("Artist '$slug' not found after constraint violation", e)
        }
    }

    private fun addSourceAttributions(event: EventEntity, sources: List<EventSourceAttribution>) {
        for (source in sources) {
            val existing = eventSourceRepository.findBySourceIdentifier(source.sourceIdentifier)
            if (existing == null) {
                event.sources.add(
                    EventSourceEntity(
                        event = event,
                        sourceType = source.sourceType,
                        sourceIdentifier = source.sourceIdentifier,
                        sourceUrl = source.sourceUrl,
                        lastScrapedAt = Instant.now(),
                        confidenceScore = source.confidenceScore,
                        sourceId = source.sourceId
                    )
                )
            }
        }
    }
}
