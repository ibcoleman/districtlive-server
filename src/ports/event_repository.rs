use async_trait::async_trait;

use crate::domain::{
    error::RepoError,
    event::{Event, EventFilters, EventId, EventUpsertCommand},
    event_source::EventSource,
    Page, Pagination,
};

/// Result of an upsert operation — whether the row was inserted or updated.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum UpsertResult {
    Created,
    Updated,
}

#[async_trait]
pub trait EventRepository: Send + Sync {
    /// Insert or update an event record.
    ///
    /// Resolves (or creates) the venue and artist records referenced by the command.
    /// Uses `INSERT ... ON CONFLICT (slug) DO UPDATE` for idempotent upsert.
    /// The `UpsertResult` is derived from PostgreSQL's `xmax` system column.
    async fn upsert(&self, cmd: EventUpsertCommand) -> Result<UpsertResult, RepoError>;

    async fn find_by_id(&self, id: EventId) -> Result<Event, RepoError>;
    async fn find_by_slug(&self, slug: &str) -> Result<Option<Event>, RepoError>;
    async fn find_all(
        &self,
        filters: EventFilters,
        page: Pagination,
    ) -> Result<Page<Event>, RepoError>;
    async fn find_by_venue_id(
        &self,
        venue_id: crate::domain::venue::VenueId,
    ) -> Result<Vec<Event>, RepoError>;

    /// Find upcoming events at the same venue within ±7 days of the given event.
    async fn find_related_events(
        &self,
        event_id: EventId,
        window_days: i64,
    ) -> Result<Vec<Event>, RepoError>;

    async fn find_upcoming(&self) -> Result<Vec<Event>, RepoError>;

    /// Count upcoming events per venue (used for VenueDto.upcomingEventCount).
    async fn count_upcoming_by_venue(
        &self,
    ) -> Result<Vec<(crate::domain::venue::VenueId, i64)>, RepoError>;

    /// Return all source attributions recorded for a given event.
    async fn find_sources_by_event_id(
        &self,
        event_id: EventId,
    ) -> Result<Vec<EventSource>, RepoError>;
}
