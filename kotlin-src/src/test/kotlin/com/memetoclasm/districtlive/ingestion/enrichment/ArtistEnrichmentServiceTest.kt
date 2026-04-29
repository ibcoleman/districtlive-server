package com.memetoclasm.districtlive.ingestion.enrichment

import arrow.core.right
import com.memetoclasm.districtlive.event.ArtistRepositoryPort
import com.memetoclasm.districtlive.event.EnrichmentStatus
import com.memetoclasm.districtlive.event.jpa.ArtistEntity
import kotlinx.coroutines.test.runTest
import org.junit.jupiter.api.Test
import org.mockito.kotlin.*
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertTrue

class ArtistEnrichmentServiceTest {

    private val artistRepository: ArtistRepositoryPort = mock()
    private val enricher1: ArtistEnricher = mock()
    private val enricher2: ArtistEnricher = mock()

    private val config = EnrichmentConfig(
        enabled = true,
        batchSize = 10,
        maxAttempts = 3,
        musicbrainz = EnrichmentConfig.MusicBrainzConfig(rateLimitMs = 0L)
    )

    private fun createService(enrichers: List<ArtistEnricher>) = ArtistEnrichmentService(
        artistRepository = artistRepository,
        enrichers = enrichers,
        config = config
    )

    private fun testArtist(name: String = "Test Artist", attempts: Int = 0) = ArtistEntity(
        name = name,
        slug = name.lowercase().replace(" ", "-"),
        enrichmentStatus = EnrichmentStatus.PENDING,
        enrichmentAttempts = attempts
    )

    @Test
    fun `resetOrphanedInProgress calls reset methods on startup`() {
        whenever(artistRepository.resetInProgressToPending()).thenReturn(0)
        whenever(artistRepository.resetEligibleFailedToPending(config.maxAttempts)).thenReturn(0)

        val service = createService(listOf(enricher1, enricher2))
        service.resetOrphanedInProgress()

        verify(artistRepository).resetInProgressToPending()
        verify(artistRepository).resetEligibleFailedToPending(config.maxAttempts)
    }

    @Test
    fun `enrichBatch returns Right with count when batch is successfully claimed`() = runTest {
        val artist = testArtist("Artist 1")
        whenever(artistRepository.claimPendingArtistsBatch(any())).thenReturn(listOf(artist))
        whenever(artistRepository.save(any())).thenAnswer {
            val arg = it.arguments[0] as ArtistEntity
            arg
        }
        whenever(enricher1.source).thenReturn(EnrichmentSource.MUSIC_BRAINZ)
        whenever(enricher2.source).thenReturn(EnrichmentSource.SPOTIFY)
        whenever(enricher1.enrich(any())).thenReturn(EnrichmentResult(
            canonicalName = "Better Name",
            externalId = "mbid-123",
            tags = listOf("Rock", "Indie"),
            imageUrl = "http://example.com/image.jpg",
            confidence = 0.95
        ))
        whenever(enricher2.enrich(any())).thenReturn(EnrichmentResult(
            canonicalName = null,
            externalId = "spotify-456",
            tags = listOf("Rock"),
            imageUrl = null,
            confidence = 1.0
        ))

        val service = createService(listOf(enricher1, enricher2))
        val result = service.enrichBatch()

        assertTrue(result.isRight())
        assertEquals(1, result.getOrNull())
    }

    @Test
    fun `enrichBatch marks artist as DONE when all enrichers succeed`() = runTest {
        val artist = testArtist("Artist 1")
        val savedArtists = mutableListOf<ArtistEntity>()
        whenever(artistRepository.claimPendingArtistsBatch(any())).thenReturn(listOf(artist))
        whenever(artistRepository.save(any())).thenAnswer {
            val arg = it.arguments[0] as ArtistEntity
            // Capture a snapshot of the current state
            savedArtists.add(ArtistEntity(
                name = arg.name,
                slug = arg.slug,
                enrichmentStatus = arg.enrichmentStatus,
                enrichmentAttempts = arg.enrichmentAttempts,
                canonicalName = arg.canonicalName,
                musicbrainzId = arg.musicbrainzId,
                spotifyId = arg.spotifyId,
                lastEnrichedAt = arg.lastEnrichedAt
            ))
            arg
        }
        whenever(enricher1.source).thenReturn(EnrichmentSource.MUSIC_BRAINZ)
        whenever(enricher2.source).thenReturn(EnrichmentSource.SPOTIFY)
        whenever(enricher1.enrich(any())).thenReturn(EnrichmentResult(
            canonicalName = "Better Name",
            externalId = "mbid-123",
            tags = listOf("Rock"),
            imageUrl = null,
            confidence = 0.95
        ))
        whenever(enricher2.enrich(any())).thenReturn(EnrichmentResult(
            canonicalName = null,
            externalId = "spotify-456",
            tags = listOf("Rock"),
            imageUrl = "http://example.com/img.jpg",
            confidence = 1.0
        ))

        val service = createService(listOf(enricher1, enricher2))
        service.enrichBatch()

        assertTrue(savedArtists.size >= 2, "Expected at least 2 saves")
        val lastSaved = savedArtists.last()
        assertEquals(EnrichmentStatus.DONE, lastSaved.enrichmentStatus)
        assertEquals("Better Name", lastSaved.canonicalName)
        assertEquals("mbid-123", lastSaved.musicbrainzId)
        assertEquals("spotify-456", lastSaved.spotifyId)
        assertNotNull(lastSaved.lastEnrichedAt, "lastEnrichedAt should be set when artist is marked DONE")
    }

    @Test
    fun `enrichBatch marks artist as FAILED when enricher throws exception`() = runTest {
        val artist = testArtist("Artist 1")
        val savedArtists = mutableListOf<ArtistEntity>()
        whenever(artistRepository.claimPendingArtistsBatch(any())).thenReturn(listOf(artist))
        whenever(artistRepository.save(any())).thenAnswer {
            val arg = it.arguments[0] as ArtistEntity
            // Capture a snapshot of the current state
            savedArtists.add(ArtistEntity(
                name = arg.name,
                slug = arg.slug,
                enrichmentStatus = arg.enrichmentStatus,
                enrichmentAttempts = arg.enrichmentAttempts
            ))
            arg
        }
        whenever(enricher1.source).thenReturn(EnrichmentSource.MUSIC_BRAINZ)
        whenever(enricher2.source).thenReturn(EnrichmentSource.SPOTIFY)
        whenever(enricher1.enrich(any())).thenThrow(RuntimeException("Connection error"))
        whenever(enricher2.enrich(any())).thenReturn(null)

        val service = createService(listOf(enricher1, enricher2))
        service.enrichBatch()

        assertTrue(savedArtists.size >= 2, "Expected at least 2 saves")
        val lastSaved = savedArtists.last()
        assertEquals(EnrichmentStatus.FAILED, lastSaved.enrichmentStatus)
        assertEquals(1, lastSaved.enrichmentAttempts)
    }

    @Test
    fun `enrichBatch marks artist as SKIPPED when attempts exceed maxAttempts`() = runTest {
        val artist = testArtist("Artist 1", attempts = 3)
        val savedArtists = mutableListOf<ArtistEntity>()
        whenever(artistRepository.claimPendingArtistsBatch(any())).thenReturn(listOf(artist))
        whenever(artistRepository.save(any())).thenAnswer {
            val arg = it.arguments[0] as ArtistEntity
            // Capture a snapshot of the current state
            savedArtists.add(ArtistEntity(
                name = arg.name,
                slug = arg.slug,
                enrichmentStatus = arg.enrichmentStatus,
                enrichmentAttempts = arg.enrichmentAttempts
            ))
            arg
        }

        val service = createService(listOf(enricher1, enricher2))
        service.enrichBatch()

        assertTrue(savedArtists.size >= 2, "Expected at least 2 saves")
        val lastSaved = savedArtists.last()
        assertEquals(EnrichmentStatus.SKIPPED, lastSaved.enrichmentStatus)
        assertEquals(4, lastSaved.enrichmentAttempts)
    }

    @Test
    fun `enrichBatch marks artist as SKIPPED when all enrichers return null at maxAttempts`() = runTest {
        val artist = testArtist("Artist 1", attempts = 2)
        val savedArtists = mutableListOf<ArtistEntity>()
        whenever(artistRepository.claimPendingArtistsBatch(any())).thenReturn(listOf(artist))
        whenever(artistRepository.save(any())).thenAnswer {
            val arg = it.arguments[0] as ArtistEntity
            // Capture a snapshot of the current state
            savedArtists.add(ArtistEntity(
                name = arg.name,
                slug = arg.slug,
                enrichmentStatus = arg.enrichmentStatus,
                enrichmentAttempts = arg.enrichmentAttempts
            ))
            arg
        }
        whenever(enricher1.source).thenReturn(EnrichmentSource.MUSIC_BRAINZ)
        whenever(enricher2.source).thenReturn(EnrichmentSource.SPOTIFY)
        whenever(enricher1.enrich(any())).thenReturn(null)
        whenever(enricher2.enrich(any())).thenReturn(null)

        val service = createService(listOf(enricher1, enricher2))
        service.enrichBatch()

        assertTrue(savedArtists.size >= 2, "Expected at least 2 saves")
        val lastSaved = savedArtists.last()
        assertEquals(EnrichmentStatus.SKIPPED, lastSaved.enrichmentStatus)
        assertEquals(3, lastSaved.enrichmentAttempts)
    }

    @Test
    fun `enrichBatch returns Right when no pending artists claimed`() = runTest {
        whenever(artistRepository.claimPendingArtistsBatch(any())).thenReturn(emptyList())

        val service = createService(listOf(enricher1, enricher2))
        val result = service.enrichBatch()

        assertTrue(result.isRight())
        assertEquals(0, result.getOrNull())
    }

    @Test
    fun `enrichBatch returns Left on repository error during claim`() = runTest {
        whenever(artistRepository.claimPendingArtistsBatch(any())).thenThrow(
            RuntimeException("Database connection failed")
        )

        val service = createService(listOf(enricher1, enricher2))
        val result = service.enrichBatch()

        assertTrue(result.isLeft())
        val error = result.swap().getOrNull()
        assertTrue(error is EnrichmentError.RepositoryError)
    }

    @Test
    fun `enrichBatch increments attempts before processing`() = runTest {
        val artist = testArtist("Artist 1", attempts = 1)
        val savedArtists = mutableListOf<ArtistEntity>()
        whenever(artistRepository.claimPendingArtistsBatch(any())).thenReturn(listOf(artist))
        whenever(artistRepository.save(any())).thenAnswer {
            val arg = it.arguments[0] as ArtistEntity
            // Capture a snapshot of the current state
            savedArtists.add(ArtistEntity(
                name = arg.name,
                slug = arg.slug,
                enrichmentStatus = arg.enrichmentStatus,
                enrichmentAttempts = arg.enrichmentAttempts
            ))
            arg
        }
        whenever(enricher1.source).thenReturn(EnrichmentSource.MUSIC_BRAINZ)
        whenever(enricher2.source).thenReturn(EnrichmentSource.SPOTIFY)
        whenever(enricher1.enrich(any())).thenReturn(null)
        whenever(enricher2.enrich(any())).thenReturn(null)

        val service = createService(listOf(enricher1, enricher2))
        service.enrichBatch()

        assertTrue(savedArtists.isNotEmpty(), "Expected at least 1 save")
        val firstSave = savedArtists[0]
        assertEquals(EnrichmentStatus.IN_PROGRESS, firstSave.enrichmentStatus)
        assertEquals(2, firstSave.enrichmentAttempts)
    }
}

/**
 * AC3.2 concurrent isolation: FOR UPDATE SKIP LOCKED prevents concurrent batch overlap.
 * This PostgreSQL feature is verified manually by running two server instances against
 * the same PostgreSQL instance and confirming no artists are processed by both instances.
 * H2 (used in unit tests) does not support FOR UPDATE SKIP LOCKED, so this cannot be
 * verified with unit tests — it is verified by the JpaArtistRepository implementation
 * which includes @Lock(PESSIMISTIC_WRITE) + @QueryHints timeout.
 */
