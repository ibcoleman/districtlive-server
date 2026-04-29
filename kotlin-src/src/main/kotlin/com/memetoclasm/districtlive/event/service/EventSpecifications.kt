package com.memetoclasm.districtlive.event.service

import com.memetoclasm.districtlive.event.EventStatus
import com.memetoclasm.districtlive.event.jpa.EventEntity
import org.springframework.data.jpa.domain.Specification
import java.math.BigDecimal
import java.time.Instant
import java.time.ZoneId

object EventSpecifications {

    /**
     * Day boundary hour in America/New_York. A "day" runs from 5 AM ET to 4:59 AM ET the next
     * calendar day. This keeps late-night shows (midnight, 1 AM) grouped with the evening they
     * belong to rather than the next calendar day.
     */
    private const val DAY_BOUNDARY_HOUR = 5
    private val ET_ZONE = ZoneId.of("America/New_York")

    fun hasVenueSlug(slug: String?): Specification<EventEntity> {
        return Specification { root, _, cb ->
            if (slug == null) return@Specification null
            val venueJoin = root.join<Any, Any>("venue")
            cb.or(
                cb.equal(venueJoin.get<String>("slug"), slug),
                cb.equal(venueJoin.get<String>("displaySlug"), slug)
            )
        }
    }

    /**
     * Applies a 5 AM ET day boundary so late-night events (midnight–4:59 AM) stay grouped
     * with the previous evening. When [from] falls on midnight ET, it shifts to 5 AM ET
     * that day. When [to] falls on midnight ET (i.e. end of a calendar day), it shifts to
     * 5 AM ET the next day.
     */
    fun hasDateRange(from: Instant?, to: Instant?): Specification<EventEntity> {
        return Specification { root, _, cb ->
            val predicates = mutableListOf<jakarta.persistence.criteria.Predicate>()

            if (from != null) {
                val adjustedFrom = applyDayBoundary(from)
                predicates.add(cb.greaterThanOrEqualTo(root.get("startTime"), adjustedFrom))
            }
            if (to != null) {
                val adjustedTo = applyDayBoundary(to)
                predicates.add(cb.lessThanOrEqualTo(root.get("startTime"), adjustedTo))
            }

            if (predicates.isEmpty()) null else cb.and(*predicates.toTypedArray())
        }
    }

    /**
     * If the instant falls exactly on midnight ET (hour 0), shift it to [DAY_BOUNDARY_HOUR] AM ET.
     * Otherwise return as-is — the caller already sent a specific time.
     */
    private fun applyDayBoundary(instant: Instant): Instant {
        val zoned = instant.atZone(ET_ZONE)
        return if (zoned.hour == 0 && zoned.minute == 0 && zoned.second == 0) {
            zoned.withHour(DAY_BOUNDARY_HOUR).toInstant()
        } else {
            instant
        }
    }

    fun hasGenre(genre: String?): Specification<EventEntity> {
        return Specification { root, _, cb ->
            if (genre == null) return@Specification null
            val artistJoin = root.join<Any, Any>("artists")
            cb.isTrue(
                cb.function(
                    "array_position",
                    Integer::class.java,
                    artistJoin.get<Any>("genres"),
                    cb.literal(genre)
                ).isNotNull
            )
        }
    }

    fun hasNeighborhood(neighborhood: String?): Specification<EventEntity> {
        return Specification { root, _, cb ->
            if (neighborhood == null) return@Specification null
            val venueJoin = root.join<Any, Any>("venue")
            cb.equal(venueJoin.get<String>("neighborhood"), neighborhood)
        }
    }

    fun hasPriceMax(maxPrice: BigDecimal?): Specification<EventEntity> {
        return Specification { root, _, cb ->
            if (maxPrice == null) return@Specification null
            cb.lessThanOrEqualTo(root.get("maxPrice"), maxPrice)
        }
    }

    fun hasStatus(status: EventStatus?): Specification<EventEntity> {
        return Specification { root, _, cb ->
            if (status == null) return@Specification null
            cb.equal(root.get<EventStatus>("status"), status)
        }
    }
}
