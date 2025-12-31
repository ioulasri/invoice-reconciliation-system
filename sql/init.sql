-- =====================================================
-- Invoice Reconciliation System - Database Schema
-- =====================================================
-- This file creates all 7 tables needed for the system
-- It runs automatically when PostgreSQL container starts
-- =====================================================

-- Clean slate: Drop tables if they exist (useful for rebuilding)

DROP TABLE IF EXISTS companies CASCADE;

CREATE TABLE companies (
	id SERIAL PRIMARY KEY,
	name VARCHAR(100) NOT NULL,
	created_at TIMESTAMP DEFAULT NOW(),
	active BOOLEAN DEFAULT TRUE
);

INSERT INTO companies (name) VALUES ('Demo Company Ltd');

SELECT * FROM companies;
