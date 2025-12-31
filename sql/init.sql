-- =====================================================
-- Invoice Reconciliation System - Database Schema
-- =====================================================
-- This file creates all 7 tables needed for the system
-- It runs automatically when PostgreSQL container starts
-- =====================================================

-- Clean slate: Drop tables if they exist (useful for rebuilding)
DROP TABLE IF EXISTS reconciliation_audit_log CASCADE;
DROP TABLE IF EXISTS reconciliation_policies CASCADE;
DROP TABLE IF EXISTS reconciliations CASCADE;
DROP TABLE IF EXISTS payments CASCADE;
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
    (1, 2, 'INV-003', 2500.00, '2024-01-20', '2024-02-20', 'OPEN'),
    (1, 2, 'INV-004', 2500.00, '2024-01-20', '2024-02-20', 'OPEN'),
    (1, 2, 'INV-005', 2500.00, '2024-01-20', '2024-02-20', 'OPEN');

-- Verify
SELECT * FROM invoices;

CREATE TABLE payments (
	id SERIAL PRIMARY KEY,
	company_id INTEGER NOT NULL,
	customer_id INTEGER NOT NULL,
	external_id VARCHAR(100) NOT NULL UNIQUE,
	amount DECIMAL(10, 2) NOT NULL CHECK (amount > 0),
	currency VARCHAR(3) DEFAULT 'EUR',
	payment_date DATE NOT NULL,
	reference TEXT,
	created_at TIMESTAMP DEFAULT NOW(),
	FOREIGN KEY (company_id) REFERENCES companies(id),
	FOREIGN KEY (customer_id) REFERENCES customers(id)
);

CREATE INDEX idx_payments_company ON payments(company_id);
CREATE INDEX idx_payments_customer ON payments(customer_id);
CREATE INDEX idx_payments_external_id ON payments(external_id);
CREATE INDEX idx_payments_date ON payments(payment_date);

INSERT INTO payments (company_id, customer_id, external_id, amount, payment_date, reference) VALUES
    (1, 1, 'BANK-REF-001', 5000.00, '2024-02-01', 'Payment for INV-001'),
    (1, 2, 'BANK-REF-002', 1500.00, '2024-02-05', 'Partial payment');

SELECT * FROM payments;

CREATE TABLE reconciliations (
	id SERIAL PRIMARY KEY,
	company_id INTEGER NOT NULL,
	invoice_id INTEGER NOT NULL,
	payment_id INTEGER NOT NULL,
	matched_amount DECIMAL(10, 2) NOT NULL CHECK (matched_amount > 0),
	confidence_score INTEGER CHECK (confidence_score >= 0 and confidence_score <= 100),
	status VARCHAR(50) DEFAULT 'PENDING_REVIEW' CHECK (status IN ('AUTO-MATCHED', 'PENDING_REVIEW', 'REJECTED')),
	matched_at TIMESTAMP DEFAULT NOW(),
	matched_by VARCHAR(100) DEFAULT 'SYSTEM',
	FOREIGN KEY (company_id) REFERENCES companies(id),
	FOREIGN KEY (invoice_id) REFERENCES invoices(id),
	FOREIGN KEY (payment_id) REFERENCES payments(id)
);

CREATE INDEX idx_reconciliation_company ON reconciliations(company_id);
CREATE INDEX idx_reconciliation_invoice ON reconciliations(invoice_id);
CREATE INDEX idx_reconciliation_payment ON reconciliations(payment_id);
CREATE INDEX idx_reconciliation_status ON reconciliations(status);

INSERT INTO reconciliations (company_id, invoice_id, payment_id, matched_amount, confidence_score, status, matched_by) VALUES 
    (1, 1, 1, 5000.00, 98, 'AUTO-MATCHED', 'SYSTEM');

SELECT * FROM reconciliations;

CREATE TABLE reconciliation_policies (
	id SERIAL PRIMARY KEY,
	company_id INTEGER NOT NULL UNIQUE,
	auto_match_threshold INTEGER DEFAULT 95 CHECK (auto_match_threshold >= 0 and auto_match_threshold <= 100),
	max_amount_variance DECIMAL(10, 2) DEFAULT 50.00,
	max_days_late INTEGER DEFAULT 30,
	created_at TIMESTAMP DEFAULT NOW(),
	FOREIGN KEY (company_id) REFERENCES companies(id)
);

INSERT INTO reconciliation_policies (company_id, auto_match_threshold, max_amount_variance, max_days_late) VALUES
	(1, 95, 50.00, 30);

SELECT * FROM reconciliation_policies;

CREATE TABLE reconciliation_audit_log (
	id SERIAL PRIMARY KEY,
	reconciliation_id INTEGER NOT NULL,
	action VARCHAR(50) NOT NULL CHECK (action IN ('CREATED', 'APPROVED', 'REJECTED', 'MODIFIED')),
	performed_by VARCHAR(100) NOT NULL,
	performed_at TIMESTAMP DEFAULT NOW(),
	notes TEXT,
	FOREIGN KEY (reconciliation_id) REFERENCES reconciliations(id)
);

CREATE INDEX idx_reconciliation_audit_log_id ON reconciliation_audit_log(reconciliation_id);
CREATE INDEX idx_reconciliation_audit_log_performed_at ON reconciliation_audit_log(performed_at);

INSERT INTO reconciliation_audit_log (reconciliation_id, action, performed_by, notes) VALUES
	(1, 'CREATED', 'SYSTEM', 'Automatic match based on exact amount');

SELECT * FROM reconciliation_audit_log;