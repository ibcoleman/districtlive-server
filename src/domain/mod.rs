//! Domain types — pure value types with no I/O dependencies.
// pattern: Functional Core

pub mod artist;
pub mod error;
pub mod event;
pub mod event_source;
pub mod featured_event;
pub mod ingestion_run;
pub mod source;
pub mod venue;

// Re-export error types at domain level for convenience
pub use error::{EnrichmentError, IngestionError, RepoError};

/// Generate a URL-safe slug from any string.
///
/// Lowercases input, replaces non-alphanumeric runs with a single hyphen,
/// and trims leading/trailing hyphens. Used by both ingestion normalization
/// (event slugs) and adapter code (venue/artist auto-creation slugs).
///
/// Single canonical implementation to ensure consistent slug formatting
/// across the entire application.
pub fn slugify(s: &str) -> String {
    let s = s.to_lowercase();
    let mut slug = String::with_capacity(s.len());
    let mut prev_hyphen = true;
    for c in s.chars() {
        if c.is_alphanumeric() {
            slug.push(c);
            prev_hyphen = false;
        } else if !prev_hyphen {
            slug.push('-');
            prev_hyphen = true;
        }
    }
    if slug.ends_with('-') {
        slug.pop();
    }
    slug
}

/// A paginated result set.
#[derive(Debug, Clone, serde::Serialize)]
pub struct Page<T> {
    pub items: Vec<T>,
    pub total: i64,
    pub page: i64,
    pub per_page: i64,
}

/// Pagination parameters passed to repository list methods.
#[derive(Debug, Clone, Copy)]
pub struct Pagination {
    /// Zero-based page index.
    pub page: i64,
    /// Number of items per page. Must be ≥ 1.
    pub per_page: i64,
}

impl Pagination {
    /// SQL OFFSET for this page.
    pub fn offset(self) -> i64 {
        self.page * self.per_page
    }
}

impl Default for Pagination {
    fn default() -> Self {
        Self {
            page: 0,
            per_page: 20,
        }
    }
}
