//! rust_app_template library crate.
//!
//! The hexagonal skeleton:
//! * [`domain`]   — value types, no I/O.
//! * [`ports`]    — async trait abstractions.
//! * [`adapters`] — concrete implementations injected at runtime.
//! * [`http`]     — axum router, handlers, and error mapping.

pub mod adapters;
pub mod config;
pub mod domain;
pub mod enrichment;
pub mod http;
pub mod ingestion;
pub mod ports;
