//! FeaturedEvent domain type — a curated editorial pick for the homepage.

use serde::{Deserialize, Serialize};
use time::OffsetDateTime;
use uuid::Uuid;

use crate::domain::event::EventId;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize, sqlx::Type)]
#[sqlx(transparent)]
pub struct FeaturedEventId(pub Uuid);

impl FeaturedEventId {
    pub fn new() -> Self {
        Self(Uuid::new_v4())
    }
}

impl Default for FeaturedEventId {
    fn default() -> Self {
        Self::new()
    }
}

#[derive(Debug, Clone, Serialize)]
pub struct FeaturedEvent {
    pub id: FeaturedEventId,
    pub event_id: EventId,
    pub blurb: String,
    pub created_at: OffsetDateTime,
    pub created_by: String,
}
