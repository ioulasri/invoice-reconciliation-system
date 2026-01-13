.PHONY: help up down restart build logs db-connect db-reset db-backup db-restore clean install run-ingestion run-main query-1 query-2 query-3 query-4 query-5 shell-app

# Default target
help:
	@echo "Invoice Reconciliation System - Makefile Commands"
	@echo "=================================================="
	@echo ""
	@echo "Docker Commands:"
	@echo "  make up              - Start all containers"
	@echo "  make down            - Stop all containers"
	@echo "  make restart         - Restart all containers"
	@echo "  make build           - Rebuild containers"
	@echo "  make logs            - Show container logs"
	@echo "  make logs-db         - Show database logs"
	@echo "  make logs-app        - Show application logs"
	@echo ""
	@echo "Database Commands:"
	@echo "  make db-connect      - Connect to PostgreSQL database"
	@echo "  make db-reset        - Reset database (drop volume and restart)"
	@echo "  make db-backup       - Backup database to backup.sql"
	@echo "  make db-restore      - Restore database from backup.sql"
	@echo "  make db-stats        - Show database statistics"
	@echo ""
	@echo "Query Commands:"
	@echo "  make query-1         - Outstanding Invoices by Customer"
	@echo "  make query-2         - Unmatched Payments"
	@echo "  make query-3         - Reconciliation Status Report"
	@echo "  make query-4         - Collection Rate by Customer"
	@echo "  make query-5         - Audit Trail for Reconciliation"
	@echo ""
	@echo "Application Commands:"
	@echo "  make install         - Install Python dependencies"
	@echo "  make run-main        - Run main.py"
	@echo "  make run-ingestion   - Run ingestion.py"
	@echo "  make shell-app       - Open shell in app container"
	@echo ""
	@echo "Cleanup Commands:"
	@echo "  make clean           - Remove containers and volumes"
	@echo "  make clean-all       - Remove everything including images"
	@echo ""

# ==================== Docker Commands ====================

up:
	@echo "Starting containers..."
	docker-compose up -d
	@echo "Waiting for database to be ready..."
	@sleep 3
	@echo "Containers started successfully!"
	@docker-compose ps

down:
	@echo "Stopping containers..."
	docker-compose down
	@echo "Containers stopped."

restart: down up

build:
	@echo "Building containers..."
	docker-compose build --no-cache
	@echo "Build complete."

logs:
	docker-compose logs -f

logs-db:
	docker-compose logs -f db

logs-app:
	docker-compose logs -f app

# ==================== Database Commands ====================

db-connect:
	@echo "Connecting to database..."
	docker exec -it reconciliation_db psql -U reconciliation_user -d invoice_reconciliation

db-reset:
	@echo "Resetting database..."
	docker-compose down
	docker volume rm invoice-reconciliation-system_postgres_data || true
	docker-compose up -d
	@echo "Waiting for database initialization..."
	@sleep 5
	@echo "Database reset complete!"

db-backup:
	@echo "Backing up database to backup.sql..."
	docker exec reconciliation_db pg_dump -U reconciliation_user invoice_reconciliation > backup.sql
	@echo "Backup complete: backup.sql"

db-restore:
	@echo "Restoring database from backup.sql..."
	@if [ ! -f backup.sql ]; then \
		echo "Error: backup.sql not found"; \
		exit 1; \
	fi
	docker exec -i reconciliation_db psql -U reconciliation_user invoice_reconciliation < backup.sql
	@echo "Restore complete!"

db-stats:
	@echo "Database Statistics:"
	@echo "===================="
	docker exec reconciliation_db psql -U reconciliation_user -d invoice_reconciliation -c "\
		SELECT 'Companies' as table_name, COUNT(*) as records FROM companies \
		UNION ALL SELECT 'Customers', COUNT(*) FROM customers \
		UNION ALL SELECT 'Invoices', COUNT(*) FROM invoices \
		UNION ALL SELECT 'Payments', COUNT(*) FROM payments \
		UNION ALL SELECT 'Reconciliations', COUNT(*) FROM reconciliations;"

# ==================== Query Commands ====================

query-1:
	@echo "Query 1: Outstanding Invoices by Customer"
	@echo "=========================================="
	docker exec reconciliation_db psql -U reconciliation_user -d invoice_reconciliation -c "\
		SELECT \
			c.name AS customer_name, \
			c.email AS customer_email, \
			COUNT(i.id) AS total_invoices, \
			SUM(i.amount) AS total_amount_due, \
			MIN(i.due_date) AS oldest_due_date, \
			MAX(i.due_date) AS newest_due_date \
		FROM customers c \
		LEFT JOIN invoices i ON c.id = i.customer_id \
			AND i.status IN ('OPEN', 'PARTIALLY_MATCHED', 'OVERDUE') \
		WHERE c.company_id = 1 \
		GROUP BY c.id, c.name, c.email \
		HAVING SUM(i.amount) > 0 \
		ORDER BY total_amount_due DESC;"

query-2:
	@echo "Query 2: Unmatched Payments"
	@echo "============================"
	docker exec reconciliation_db psql -U reconciliation_user -d invoice_reconciliation -c "\
		SELECT \
			p.external_id, \
			p.payment_date, \
			c.name AS customer_name, \
			p.amount AS payment_amount, \
			COALESCE(SUM(r.matched_amount), 0) AS amount_matched, \
			p.amount - COALESCE(SUM(r.matched_amount), 0) AS amount_remaining \
		FROM payments p \
		JOIN customers c ON p.customer_id = c.id \
		LEFT JOIN reconciliations r on p.id = r.payment_id \
			AND r.status != 'REJECTED' \
		WHERE p.company_id = 1 \
		GROUP BY p.id, p.external_id, p.payment_date, c.name, p.amount \
		HAVING p.amount > COALESCE(SUM(r.matched_amount), 0) \
		ORDER BY p.payment_date ASC;"

query-3:
	@echo "Query 3: Reconciliation Status Report"
	@echo "======================================"
	docker exec reconciliation_db psql -U reconciliation_user -d invoice_reconciliation -c "\
		SELECT \
			TO_CHAR(r.matched_at, 'YYYY-MM') AS month, \
			COUNT(*) AS total_reconciliations, \
			COUNT(CASE WHEN r.status = 'AUTO_MATCHED' THEN 1 END) AS auto_matched, \
			COUNT(CASE WHEN r.status = 'PENDING_REVIEW' THEN 1 END) AS pending_review, \
			COUNT(CASE WHEN r.status = 'REJECTED' THEN 1 END) AS rejected, \
			ROUND(100.0 * COUNT(CASE WHEN r.status = 'AUTO_MATCHED' THEN 1 END) / COUNT(*), 2) AS auto_match_rate_percent, \
			SUM(r.matched_amount) AS total_amount_reconcilied \
		FROM reconciliations r \
		WHERE r.company_id = 1 \
		GROUP BY TO_CHAR(r.matched_at, 'YYYY-MM') \
		ORDER BY month DESC;"

query-4:
	@echo "Query 4: Collection Rate by Customer"
	@echo "====================================="
	docker exec reconciliation_db psql -U reconciliation_user -d invoice_reconciliation -c "\
		SELECT \
			c.name AS customer_name, \
			COUNT(DISTINCT i.id) AS total_invoices, \
			COUNT(DISTINCT CASE WHEN r.id IS NOT NULL THEN i.id END) AS paid_invoices, \
			ROUND(100.0 * COUNT(DISTINCT CASE WHEN r.id IS NOT NULL THEN i.id END) / NULLIF(COUNT(DISTINCT i.id), 0), 2) AS collection_rate_percent \
		FROM customers c \
		LEFT JOIN invoices i ON c.id = i.customer_id \
		LEFT JOIN reconciliations r ON i.id = r.invoice_id \
			AND r.status IN ('AUTO_MATCHED', 'PENDING_REVIEW') \
		WHERE c.company_id = 1 \
		GROUP BY c.id, c.name \
		ORDER BY collection_rate_percent DESC;"

query-5:
	@echo "Query 5: Audit Trail (Reconciliation ID=1)"
	@echo "=========================================="
	docker exec reconciliation_db psql -U reconciliation_user -d invoice_reconciliation -c "\
		SELECT \
			a.id AS audit_id, \
			a.performed_at AS action_timestamp, \
			a.action, \
			a.performed_by, \
			a.notes, \
			r.matched_amount, \
			r.confidence_score, \
			i.invoice_number, \
			p.external_id AS payment_reference \
		FROM reconciliation_audit_log a \
		JOIN reconciliations r ON a.reconciliation_id = r.id \
		JOIN invoices i ON r.invoice_id = i.id \
		JOIN payments p ON r.payment_id = p.id \
		WHERE r.company_id = 1 AND r.id = 1 \
		ORDER BY a.performed_at DESC;"

# ==================== Application Commands ====================

install:
	@echo "Installing Python dependencies..."
	pip install -r requirements.txt
	@echo "Dependencies installed!"

run-main:
	@echo "Running main.py..."
	docker exec reconciliation_app python /app/src/main.py

run-ingestion:
	@echo "Running ingestion.py..."
	docker exec reconciliation_app python /app/src/ingestion.py

run-database:
	docker exec reconciliation_app python /app/src/database.py

shell-app:
	@echo "Opening shell in app container..."
	docker exec -it reconciliation_app /bin/bash

# ==================== Cleanup Commands ====================

clean:
	@echo "Cleaning up containers and volumes..."
	docker-compose down -v
	@echo "Cleanup complete!"

clean-all: clean
	@echo "Removing all images..."
	docker-compose down --rmi all -v
	@echo "All cleaned up!"
