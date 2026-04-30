//! Venue domain type — a physical venue where events take place.
// pattern: Functional Core

use serde::{Deserialize, Serialize};
use time::OffsetDateTime;
use uuid::Uuid;

/// Newtype wrapper around UUID for venues. Prevents accidental ID confusion.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize, sqlx::Type)]
#[sqlx(transparent)]
pub struct VenueId(pub Uuid);

impl VenueId {
    pub fn new() -> Self {
        Self(Uuid::new_v4())
    }
}

impl Default for VenueId {
    fn default() -> Self {
        Self::new()
    }
}

impl std::fmt::Display for VenueId {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        self.0.fmt(f)
    }
}

#[derive(Debug, Clone, Serialize)]
pub struct Venue {
    pub id: VenueId,
    pub name: String,
    pub slug: String,
    pub address: Option<String>,
    pub neighborhood: Option<String>,
    pub capacity: Option<i32>,
    pub venue_type: Option<String>,
    pub website_url: Option<String>,
    /// Override for public display name (falls back to `name`).
    pub display_name: Option<String>,
    /// Override for public slug (falls back to `slug`).
    pub display_slug: Option<String>,
    pub created_at: OffsetDateTime,
    pub updated_at: OffsetDateTime,
}

impl Venue {
    /// The name shown publicly (display_name override or raw name).
    pub fn effective_name(&self) -> &str {
        self.display_name.as_deref().unwrap_or(&self.name)
    }

    /// The slug used in public URLs (display_slug override or raw slug).
    pub fn effective_slug(&self) -> &str {
        self.display_slug.as_deref().unwrap_or(&self.slug)
    }
}
