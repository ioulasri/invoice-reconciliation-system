# Invoice Reconciliation System

A comprehensive automated system for matching customer payments with outstanding invoices, designed to streamline financial operations and improve cash flow management.

## Overview

The Invoice Reconciliation System automates the process of matching payments from customers to their corresponding invoices. It uses intelligent matching algorithms with configurable confidence scoring to automatically reconcile exact matches while flagging uncertain matches for manual review.

## Features

- **Automated Reconciliation**: Automatically matches payments to invoices based on amount, customer, and timing
- **Confidence Scoring**: Each match receives a confidence score (0-100) to determine if it requires manual review
- **Multi-Company Support**: Designed to handle multiple companies in a single database
- **Configurable Policies**: Customize matching thresholds, amount variance tolerance, and payment lateness limits per company
- **Comprehensive Audit Trail**: Full history of all reconciliation actions for compliance and troubleshooting
- **Analytics Queries**: Pre-built SQL queries for financial reporting and KPI tracking

## Architecture

### Database Schema

The system uses PostgreSQL with 7 core tables:

1. **companies**: Multi-tenant support for different organizations
2. **customers**: Customer master data with contact information
3. **invoices**: Outstanding invoices with status tracking (OPEN, PARTIALLY_MATCHED, FULLY_MATCHED, OVERDUE)
4. **payments**: Bank payments received with external references
5. **reconciliations**: Matched invoice-payment pairs with confidence scores
6. **reconciliation_policies**: Company-specific matching rules and thresholds
7. **reconciliation_audit_log**: Complete audit trail of all reconciliation actions

### Technology Stack

- **Database**: PostgreSQL 14
- **Backend**: Python 3.11
- **Libraries**: 
  - psycopg2 for database connectivity
  - pandas for data processing
  - python-dotenv for configuration
- **Infrastructure**: Docker & Docker Compose

## Getting Started

### Prerequisites

- Docker and Docker Compose installed
- Git (for cloning the repository)

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd invoice-reconciliation-system
```

2. Start the system using Docker Compose:
```bash
docker-compose up -d
```

This will:
- Start a PostgreSQL database on port 5432
- Initialize the schema with sample data
- Start the application container

### Database Access

Connect to the PostgreSQL database:

```bash
# Using Docker exec
docker exec -it reconciliation_db psql -U reconciliation_user -d invoice_reconciliation

# Using local psql client
psql -h localhost -p 5432 -U reconciliation_user -d invoice_reconciliation
```

Default credentials:
- **User**: reconciliation_user
- **Password**: reconciliation_password_123_321
- **Database**: invoice_reconciliation

## Usage

### Running Queries

The system includes 5 pre-built analytical queries in `sql/queries.sql`:

**Query 1: Outstanding Invoices by Customer**
```sql
-- Shows unpaid invoices grouped by customer for collections
-- Located at line 8 in queries.sql
```

**Query 2: Unmatched Payments**
```sql
-- Identifies payments not fully reconciled
-- Located at line 34 in queries.sql
```

**Query 3: Reconciliation Status Report**
```sql
-- Monthly KPI dashboard with auto-match rates
-- Located at line 60 in queries.sql
```

**Query 4: Collection Rate by Customer**
```sql
-- Payment behavior analysis for credit risk assessment
-- Located at line 86 in queries.sql
```

**Query 5: Audit Trail**
```sql
-- Complete compliance audit history
-- Located at line 130 in queries.sql
```

### Running Queries in PostgreSQL

```bash
# Execute from file
docker exec -it reconciliation_db psql -U reconciliation_user -d invoice_reconciliation -f /docker-entrypoint-initdb.d/queries.sql

# Or copy-paste individual queries in psql
docker exec -it reconciliation_db psql -U reconciliation_user -d invoice_reconciliation
# Then paste your query
```

## Project Structure

```
invoice-reconciliation-system/
├── docker-compose.yml          # Multi-container orchestration
├── Dockerfile                  # Python application container
├── requirements.txt            # Python dependencies
├── README.md                   # This file
├── sql/
│   ├── init.sql               # Database schema & seed data (auto-runs on startup)
│   └── queries.sql            # Analytical queries for reporting
├── src/
│   └── main.py                # Application entry point
└── data/                      # Directory for data files (CSV imports, etc.)
```

## Configuration

### Reconciliation Policies

Customize matching behavior per company in the `reconciliation_policies` table:

- **auto_match_threshold**: Minimum confidence score (0-100) for automatic matching (default: 95)
- **max_amount_variance**: Maximum acceptable difference between invoice and payment amounts (default: €50.00)
- **max_days_late**: Maximum days after due date to consider for matching (default: 30)

### Environment Variables

Configure database connection in `docker-compose.yml`:

```yaml
POSTGRES_HOST: db
POSTGRES_PORT: 5432
POSTGRES_USER: reconciliation_user
POSTGRES_PASSWORD: reconciliation_password_123_321
POSTGRES_DB: invoice_reconciliation
```

## Sample Data

The system includes sample data for testing:

- 1 demo company
- 2 customers (Acme Corporation, TechStart Inc)
- 5 sample invoices
- 2 sample payments
- 1 auto-matched reconciliation

## Development

### Rebuilding the Database

To reset the database with fresh schema:

```bash
docker-compose down -v
docker-compose up -d
```

The `-v` flag removes volumes, ensuring a clean slate.

### Adding Custom Queries

1. Edit `sql/queries.sql`
2. Connect to database
3. Execute your query

### Testing

```bash
# Run tests (when implemented)
docker exec -it reconciliation_app pytest
```

## Key Concepts

### Reconciliation Status

- **AUTO-MATCHED**: High confidence match (≥95%), automatically approved
- **PENDING_REVIEW**: Lower confidence, requires manual verification
- **REJECTED**: Manually rejected by user

### Invoice Status

- **OPEN**: Unpaid invoice
- **PARTIALLY_MATCHED**: Some payments applied, balance remaining
- **FULLY_MATCHED**: Completely paid
- **OVERDUE**: Past due date and still unpaid

### Confidence Scoring

Matches are scored based on:
- Exact amount match
- Customer match
- Payment timing relative to due date
- Reference field matches (invoice number in payment reference)

## Monitoring & Reporting

Use the pre-built queries for:
- Daily collections tracking
- Customer payment behavior analysis
- Reconciliation efficiency KPIs
- Compliance auditing
- Cash flow forecasting

## Security Considerations

- Change default database passwords in production
- Use environment variables for sensitive configuration
- Implement role-based access control for users
- Regular audit log reviews for compliance

## Troubleshooting

### Database connection failed
```bash
# Check if containers are running
docker-compose ps

# Check logs
docker-compose logs db
```

### Schema not initialized
```bash
# Restart database container
docker-compose restart db
```

### Permission denied
```bash
# Ensure proper file permissions
chmod 644 sql/init.sql sql/queries.sql
```

## License

[Specify your license here]

## Contributors

[Add contributor information]

## Support

For issues and questions, please [create an issue/contact information].
