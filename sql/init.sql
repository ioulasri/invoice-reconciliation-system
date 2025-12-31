-- =====================================================
-- Invoice Reconciliation System - Database Schema
-- =====================================================
-- This file creates all 7 tables needed for the system
-- It runs automatically when PostgreSQL container starts
-- =====================================================

-- Clean slate: Drop tables if they exist (useful for rebuilding)

DROP TABLE IF EXISTS customers CASCADE;
DROP TABLE IF EXISTS companies CASCADE;

CREATE TABLE companies (
	id SERIAL PRIMARY KEY,
	name VARCHAR(100) NOT NULL,
	created_at TIMESTAMP DEFAULT NOW(),
	active BOOLEAN DEFAULT TRUE
);

INSERT INTO companies (name) VALUES ('Demo Company Ltd');

SELECT * FROM companies;

CREATE TABLE customers (
	id SERIAL PRIMARY KEY,
	company_id INTEGER NOT NULL,
	name VARCHAR(100) NOT NULL,
	email VARCHAR(100),
	phone VARCHAR(100),
	created_at TIMESTAMP DEFAULT NOW(),
	FOREIGN KEY (company_id) REFERENCES companies(id)
);

ALTER TABLE customers ADD CONSTRAINT unique_customer_email_per_company UNIQUE (company_id, email);

CREATE INDEX idx_customers_company ON customers(company_id);

INSERT INTO customers (company_id, name, email, phone) VALUES
	(1, 'Acme Corporation', 'billing@acme.com', '+1-555-0100'),
    (1, 'TechStart Inc', 'accounts@techstart.io', '+1-555-0200');

SELECT * FROM customers;
