-- V1__init.sql

-- 1. Create the schema for your app
CREATE SCHEMA IF NOT EXISTS districtlive;

-- Users
CREATE TABLE IF NOT EXISTS users
(
    id            SERIAL PRIMARY KEY,
    email         VARCHAR(256) UNIQUE NOT NULL,
    password_hash VARCHAR(512),
    google_id     VARCHAR(256),
    auth_provider VARCHAR(50) DEFAULT 'LOCAL',
    created_at    TIMESTAMP   DEFAULT now(),
    updated_at    TIMESTAMP   DEFAULT now()
);
