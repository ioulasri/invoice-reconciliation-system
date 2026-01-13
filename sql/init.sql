-- =====================================================
-- Invoice Reconciliation System - Database Schema
-- =====================================================
-- This file creates all 7 tables needed for the system
-- It runs automatically when PostgreSQL container starts
-- =====================================================

-- Clean slate: Drop tables if they exist (useful for rebuilding)
DROP TABLE IF EXISTS reconciliation_audit_log CASCADE;
DROP TABLE IF EXISTS reconciliations CASCADE;
DROP TABLE IF EXISTS reconciliation_policies CASCADE;
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

INSERT INTO companies (name) VALUES 
	('Demo Company Ltd'),
	('TechCorp Solutions Inc'),
	('Global Trading Partners'),
	('CloudServices Co');

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
	-- Company 1 customers
	(1, 'Acme Corporation', 'billing@acme.com', '+1-555-0100'),
	(1, 'TechStart Inc', 'accounts@techstart.io', '+1-555-0200'),
	(1, 'BuildRight Construction', 'finance@buildright.com', '+1-555-0300'),
	(1, 'MegaMart Retail', 'ap@megamart.com', '+1-555-0400'),
	(1, 'HealthPlus Medical', 'billing@healthplus.com', '+1-555-0500'),
	-- Company 2 customers
	(2, 'DataSync Systems', 'payments@datasync.io', '+1-555-1100'),
	(2, 'CloudFirst Ltd', 'accounts@cloudfirst.com', '+1-555-1200'),
	(2, 'DevOps Masters', 'billing@devopsm.net', '+1-555-1300'),
	-- Company 3 customers
	(3, 'Import Export LLC', 'finance@impexp.com', '+1-555-2100'),
	(3, 'Shipping Solutions', 'ar@shipsol.com', '+1-555-2200'),
	(3, 'Logistics Pro', 'billing@logipro.com', '+1-555-2300'),
	-- Company 4 customers
	(4, 'Startup Ventures', 'pay@startupv.io', '+1-555-3100'),
	(4, 'ScaleUp Inc', 'finance@scaleup.com', '+1-555-3200');

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
	-- Company 1 invoices
	(1, 1, 'INV-001', 5000.00, '2024-01-01', '2024-02-01', 'FULLY_MATCHED'),
	(1, 1, 'INV-002', 3000.00, '2024-01-15', '2024-02-15', 'FULLY_MATCHED'),
	(1, 2, 'INV-003', 2500.00, '2024-01-20', '2024-02-20', 'PARTIALLY_MATCHED'),
	(1, 2, 'INV-004', 1800.00, '2024-01-25', '2024-02-25', 'OPEN'),
	(1, 1, 'INV-005', 7500.00, '2024-02-01', '2024-03-01', 'OPEN'),
	(1, 3, 'INV-006', 12000.00, '2024-02-05', '2024-03-05', 'FULLY_MATCHED'),
	(1, 3, 'INV-007', 8500.00, '2024-02-10', '2024-03-10', 'OVERDUE'),
	(1, 4, 'INV-008', 4200.00, '2024-02-12', '2024-03-12', 'FULLY_MATCHED'),
	(1, 4, 'INV-009', 6800.00, '2024-02-15', '2024-03-15', 'PARTIALLY_MATCHED'),
	(1, 5, 'INV-010', 3300.00, '2024-02-18', '2024-03-18', 'FULLY_MATCHED'),
	(1, 1, 'INV-011', 15000.00, '2024-02-20', '2024-03-20', 'FULLY_MATCHED'),
	(1, 2, 'INV-012', 2100.00, '2024-02-22', '2024-03-22', 'OVERDUE'),
	(1, 3, 'INV-013', 9500.00, '2024-02-25', '2024-03-25', 'FULLY_MATCHED'),
	(1, 5, 'INV-014', 5600.00, '2024-02-28', '2024-03-28', 'FULLY_MATCHED'),
	-- Company 2 invoices
	(2, 6, 'INV-001', 25000.00, '2024-01-05', '2024-02-05', 'FULLY_MATCHED'),
	(2, 6, 'INV-002', 18000.00, '2024-01-20', '2024-02-20', 'FULLY_MATCHED'),
	(2, 7, 'INV-003', 12500.00, '2024-02-01', '2024-03-01', 'PARTIALLY_MATCHED'),
	(2, 7, 'INV-004', 8900.00, '2024-02-10', '2024-03-10', 'OPEN'),
	(2, 8, 'INV-005', 15600.00, '2024-02-15', '2024-03-15', 'FULLY_MATCHED'),
	(2, 6, 'INV-006', 22000.00, '2024-02-20', '2024-03-20', 'OVERDUE'),
	-- Company 3 invoices
	(3, 9, 'INV-001', 45000.00, '2024-01-10', '2024-02-10', 'FULLY_MATCHED'),
	(3, 9, 'INV-002', 38500.00, '2024-01-25', '2024-02-25', 'FULLY_MATCHED'),
	(3, 10, 'INV-003', 27800.00, '2024-02-05', '2024-03-05', 'PARTIALLY_MATCHED'),
	(3, 10, 'INV-004', 19200.00, '2024-02-15', '2024-03-15', 'OPEN'),
	(3, 11, 'INV-005', 31500.00, '2024-02-20', '2024-03-20', 'FULLY_MATCHED'),
	-- Company 4 invoices
	(4, 12, 'INV-001', 8800.00, '2024-01-15', '2024-02-15', 'FULLY_MATCHED'),
	(4, 12, 'INV-002', 6500.00, '2024-02-01', '2024-03-01', 'FULLY_MATCHED'),
	(4, 13, 'INV-003', 11200.00, '2024-02-10', '2024-03-10', 'FULLY_MATCHED'),
	(4, 13, 'INV-004', 9400.00, '2024-02-20', '2024-03-20', 'PARTIALLY_MATCHED');

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
	-- Company 1 payments
	(1, 1, 'BANK-REF-001', 5000.00, '2024-02-01', 'Payment for INV-001'),
	(1, 2, 'BANK-REF-002', 1500.00, '2024-02-05', 'Partial payment'),
	(1, 3, 'BANK-REF-003', 12000.00, '2024-02-06', 'Wire transfer'),
	(1, 4, 'BANK-REF-004', 3500.00, '2024-02-08', 'Check payment'),
	(1, 1, 'BANK-REF-005', 3000.00, '2024-02-16', 'ACH payment'),
	(1, 2, 'BANK-REF-006', 1000.00, '2024-02-19', 'Additional partial payment'),
	(1, 4, 'BANK-REF-007', 4200.00, '2024-02-13', 'Payment ref INV-008'),
	(1, 5, 'BANK-REF-008', 3300.00, '2024-02-19', 'Full payment'),
	(1, 3, 'BANK-REF-009', 9500.00, '2024-02-26', 'Bulk payment'),
	(1, 1, 'BANK-REF-010', 15000.00, '2024-02-21', 'Large payment'),
	(1, 5, 'BANK-REF-011', 5600.00, '2024-02-29', 'Monthly payment'),
	-- Company 2 payments
	(2, 6, 'BANK-REF-101', 25000.00, '2024-02-06', 'Enterprise payment'),
	(2, 7, 'BANK-REF-102', 8000.00, '2024-02-03', 'Partial for INV-003'),
	(2, 8, 'BANK-REF-103', 15600.00, '2024-02-16', 'Full payment'),
	(2, 6, 'BANK-REF-104', 18000.00, '2024-02-21', 'Second invoice payment'),
	(2, 7, 'BANK-REF-105', 4500.00, '2024-02-12', 'Additional payment'),
	-- Company 3 payments
	(3, 9, 'BANK-REF-201', 45000.00, '2024-02-11', 'Large import payment'),
	(3, 10, 'BANK-REF-202', 20000.00, '2024-02-07', 'Partial shipping payment'),
	(3, 11, 'BANK-REF-203', 31500.00, '2024-02-21', 'Logistics payment'),
	(3, 9, 'BANK-REF-204', 38500.00, '2024-02-26', 'Second quarter payment'),
	-- Company 4 payments
	(4, 12, 'BANK-REF-301', 8800.00, '2024-02-16', 'Startup payment'),
	(4, 13, 'BANK-REF-302', 11200.00, '2024-02-11', 'ScaleUp invoice'),
	(4, 13, 'BANK-REF-303', 5000.00, '2024-02-22', 'Partial payment'),
	(4, 12, 'BANK-REF-304', 6500.00, '2024-02-02', 'Monthly service fee');

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
	-- Company 1 reconciliations
	(1, 1, 1, 5000.00, 98, 'AUTO_MATCHED', 'SYSTEM'),
	(1, 3, 2, 1500.00, 92, 'AUTO_MATCHED', 'SYSTEM'),
	(1, 6, 3, 12000.00, 99, 'AUTO_MATCHED', 'SYSTEM'),
	(1, 9, 4, 3500.00, 88, 'AUTO_MATCHED', 'SYSTEM'),
	(1, 2, 5, 3000.00, 97, 'AUTO_MATCHED', 'SYSTEM'),
	(1, 3, 6, 1000.00, 85, 'PENDING_REVIEW', 'SYSTEM'),
	(1, 8, 7, 4200.00, 96, 'AUTO_MATCHED', 'SYSTEM'),
	(1, 10, 8, 3300.00, 99, 'AUTO_MATCHED', 'SYSTEM'),
	(1, 13, 9, 9500.00, 98, 'AUTO_MATCHED', 'SYSTEM'),
	(1, 11, 10, 15000.00, 97, 'AUTO_MATCHED', 'john.doe@demo.com'),
	(1, 14, 11, 5600.00, 95, 'AUTO_MATCHED', 'SYSTEM'),
	-- Company 2 reconciliations
	(2, 15, 12, 25000.00, 99, 'AUTO_MATCHED', 'SYSTEM'),
	(2, 17, 13, 8000.00, 90, 'AUTO_MATCHED', 'SYSTEM'),
	(2, 19, 14, 15600.00, 98, 'AUTO_MATCHED', 'SYSTEM'),
	(2, 16, 15, 18000.00, 96, 'PENDING_REVIEW', 'SYSTEM'),
	(2, 17, 16, 4500.00, 87, 'PENDING_REVIEW', 'SYSTEM'),
	-- Company 3 reconciliations
	(3, 21, 17, 45000.00, 100, 'AUTO_MATCHED', 'SYSTEM'),
	(3, 23, 18, 20000.00, 89, 'AUTO_MATCHED', 'SYSTEM'),
	(3, 25, 19, 31500.00, 97, 'AUTO_MATCHED', 'SYSTEM'),
	(3, 22, 20, 38500.00, 99, 'AUTO_MATCHED', 'admin@global.com'),
	-- Company 4 reconciliations
	(4, 27, 21, 8800.00, 98, 'AUTO_MATCHED', 'SYSTEM'),
	(4, 29, 22, 11200.00, 96, 'AUTO_MATCHED', 'SYSTEM'),
	(4, 30, 23, 5000.00, 91, 'AUTO_MATCHED', 'SYSTEM'),
	(4, 28, 24, 6500.00, 94, 'PENDING_REVIEW', 'SYSTEM');

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

CREATE INDEX idx_reconciliation_policies_company ON reconciliation_policies(company_id);

INSERT INTO reconciliation_policies (company_id, auto_match_threshold, max_amount_variance, max_days_late) VALUES
	(1, 95, 50.00, 30),
	(2, 90, 100.00, 45),
	(3, 98, 25.00, 15),
	(4, 92, 75.00, 60);

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
	(1, 'CREATED', 'SYSTEM', 'Automatic match based on exact amount'),
	(1, 'APPROVED', 'john.doe@demo.com', 'Verified and approved'),
	(2, 'CREATED', 'SYSTEM', 'Partial match detected'),
	(2, 'APPROVED', 'jane.smith@demo.com', 'Partial payment approved'),
	(3, 'CREATED', 'SYSTEM', 'Perfect match on amount and date'),
	(4, 'CREATED', 'SYSTEM', 'Auto-matched with high confidence'),
	(5, 'CREATED', 'SYSTEM', 'Exact match found'),
	(5, 'APPROVED', 'john.doe@demo.com', 'Confirmed'),
	(6, 'CREATED', 'SYSTEM', 'Partial match - review needed'),
	(6, 'MODIFIED', 'finance.manager@demo.com', 'Adjusted matched amount'),
	(7, 'CREATED', 'SYSTEM', 'Auto-matched'),
	(8, 'CREATED', 'SYSTEM', 'Perfect match'),
	(9, 'CREATED', 'SYSTEM', 'Auto-matched'),
	(10, 'CREATED', 'SYSTEM', 'Large payment matched'),
	(10, 'APPROVED', 'john.doe@demo.com', 'Large amount verified manually'),
	(11, 'CREATED', 'SYSTEM', 'Auto-matched'),
	(12, 'CREATED', 'SYSTEM', 'Perfect match for Company 2'),
	(13, 'CREATED', 'SYSTEM', 'Partial match'),
	(14, 'CREATED', 'SYSTEM', 'Full payment matched'),
	(15, 'CREATED', 'SYSTEM', 'Pending manual review'),
	(16, 'CREATED', 'SYSTEM', 'Additional payment logged'),
	(17, 'CREATED', 'SYSTEM', 'Large payment - Company 3'),
	(17, 'APPROVED', 'admin@global.com', 'Approved after verification'),
	(18, 'CREATED', 'SYSTEM', 'Partial payment'),
	(19, 'CREATED', 'SYSTEM', 'Full match'),
	(20, 'CREATED', 'SYSTEM', 'Matched successfully'),
	(20, 'APPROVED', 'admin@global.com', 'Confirmed'),
	(21, 'CREATED', 'SYSTEM', 'Company 4 - Auto match'),
	(22, 'CREATED', 'SYSTEM', 'Full payment'),
	(23, 'CREATED', 'SYSTEM', 'Partial match'),
	(24, 'CREATED', 'SYSTEM', 'Needs review'),
	(24, 'MODIFIED', 'finance@cloudservices.com', 'Updated status after review');

SELECT * FROM reconciliation_audit_log;