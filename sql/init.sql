-- =====================================================
-- Invoice Reconciliation System - Database Schema
-- =====================================================
-- This file creates all 7 tables needed for the system
-- It runs automatically when PostgreSQL container starts
-- =====================================================

-- Clean slate: Drop tables if they exist (useful for rebuilding)

DROP TABLE IF EXISTS invoices CASCADE;
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

CREATE TABLE invoices (
	id SERIAL PRIMARY KEY,
	company_id INTEGER NOT NULL,
	customer_id INTEGER NOT NULL,
	invoice_number VARCHAR(50) NOT NULL,
	amount DECIMAL(10, 2) NOT NULL CHECK (amount > 0),
	currency VARCHAR(3) DEFAULT 'EUR',
	issue_date DATE NOT NULL,
	due_date DATE NOT NULL CHECK (due_date >= issue_date),
	status VARCHAR(50) DEFAULT 'OPEN' CHECK (status IN ('OPEN', 'PARTIALLY_MATCHED', 'FULLY_MATCHED', 'OVERDUE')),
	created_at TIMESTAMP DEFAULT NOW(),
	FOREIGN KEY (company_id) REFERENCES companies(id),
	FOREIGN KEY (customer_id) REFERENCES customers(id)
);

ALTER TABLE invoices ADD CONSTRAINT unique_invoice_number_per_company
	UNIQUE (company_id, invoice_number);

CREATE INDEX idx_invoices_company ON invoices(company_id);
CREATE INDEX idx_invoices_customer ON invoices(customer_id); 
CREATE INDEX idx_invoices_status ON invoices(status);
CREATE INDEX idx_invoices_due_date ON invoices(due_date); 

INSERT INTO invoices (company_id, customer_id, invoice_number, amount, issue_date, due_date, status) VALUES
    (1, 1, 'INV-001', 5000.00, '2024-01-01', '2024-02-01', 'OPEN'),
    (1, 1, 'INV-002', 3000.00, '2024-01-15', '2024-02-15', 'OPEN'),
    (1, 2, 'INV-003', 2500.00, '2024-01-20', '2024-02-20', 'OPEN');

-- Verify
SELECT * FROM invoices;