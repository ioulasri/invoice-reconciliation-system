import psycopg2
from psycopg2.extras import RealDictCursor
import os
from typing import List, Dict, Optional, Tuple
from contextlib import contextmanager

class Database:
	"""Database connection and operations handler"""

	def __init__(self):
		"""Initialize database connection parameters from environment variables"""
		self.host = os.getenv('POSTGRES_HOST', 'localhost')
		self.port = os.getenv('POSTGRES_PORT', '5433')
		self.user = os.getenv('POSTGRES_USER', 'reconciliation_user')
		self.password = os.getenv('POSTGRES_PASSWORD', 'reconciliation_password_123_321')
		self.database = os.getenv('POSTGRES_DB', 'invoice_reconciliation')

	@contextmanager
	def get_connection(self):
		"""
		Context managet for database connections
		Automatically handles connection cleanup

		Usage:
			with db.get_connection() as conn:
				curson = conn.cursor()
				cursor.execute("SELECT * FROM companies;")
		"""
		conn = None
		try:
			conn = psycopg2.connect(
				host=self.host,
				port=self.port,
				user=self.user,
				password=self.password,
				database=self.database
			)
			yield conn
			conn.commit()
		except Exception as e:
			if conn:
				conn.rollback()
			raise e
		finally:
			if conn:
				conn.close()

	def execute_query(self, query: str, params: tuple = None, fetch: bool = True) -> Optional[List[Dict]]:
		"""
		Execute a SELECT query and return results

		Args:
			query: SQL query string
			params: Query parameters

		Returns:
			ID of inserted record

		Example:
			customer_id = db.execute_insert(
				"INSERT INTO customers (company_id, name, email) VALUES (%s, %s, %s) RETURNING id",
				(1, 'New Customer', 'customer@example.com')
			) 
		"""
		with self.get_connection() as conn:
			cursor = conn.cursor(cursor_factory=RealDictCursor)
			cursor.execute(query, params)
			
			if fetch:
				return [dict(row) for row in cursor.fetchall()]
			return None

	def execute_insert(self, query: str, params: tuple) -> int:
		"""
		Execute an INSERT query and return the inserted ID

		Args:
			query: SQL INSERT query with RETURNING id
			params: Query parameters

		Returns:
			ID of inserted record

		Example:
			customer_id = db.execute_insert(
				"INSERT INTO customers (company_id, name, email) VALUES (%s, %s, %s) RETURNING id",
				(1, 'New customer', 'customer@example.com')
			)
		"""
		with self.get_connection() as conn:
			cursor = conn.cursor()
			cursor.execute(query, params)
			return cursor.fetchone()[0]

	def execute_many(self, query: str, params_list: List[Tuple]) -> int:
		"""
		Execute multiple INSERT/UPDATE queries in batch

		Args:
			query: SQL query string
			params_list: List of parameter tuples

		Returns:
			Number of rows affected
		
		Example:
			db.execute_many(
				"INSERT INTO invoices (company_id, customer_id, invoice_numver, amount) VALUES (%s, %s, %s, %s)",
				[
					(1, 1, 'INV-001', 1000.00),
					(1, 2, 'INV-002', 2000.00),
				]
			)
		"""

		with self.get_connection() as conn:
			cursor = conn.cursor()
			cursor.executemany(query, params_list)
			return cursor.rowcount
		
	def get_company_by_id(self, company_id: int) -> Optional[Tuple]:
		"""Get company by ID"""

		query = "SELECT * FROM companies WHERE id = %s"
		results = self.execute_query(query, (company_id,))
		return results[0] if results else None
	
	def get_customer_by_email(self, company_id: int, email: str) -> Optional[Tuple]:
		"""Get customer by email within a company"""
		query = "SELECT * FROM customers WHERE company_id = %s AND email = %s"
		results = self.execute_query(query, (company_id, email))
		return results[0] if results else None
	
	def insert_customer(self, company_id: int, name: str, email: str, phone: str = None) -> int:
		"""
		Insert a new customer
		Returns:
			customer_id	
		"""
		query = """
			INSERT INTO customers (company_id, name, email, phone)
			VALUES (%s, %s, %s, %s)
			RETURNING id
		"""
		return self.execute_insert(query, (company_id, name, email, phone))

	def insert_invoice(self, company_id: int, customer_id: int, invoice_number: str,
						amount: float, currency: str, issue_date: str, due_date: str,
						status: str = 'OPEN') -> int:
		"""
		INSERT a new invoice

		Returns:
			invoice_id
		"""
		query = """
			INSERT INTO invoices (company_id, customer_id, invoice_number, amount,
								currency, issue_date, due_date, status)
			VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
			RETURNING id
		"""
		return self.execute_insert(query, (company_id, customer_id, invoice_number,
											amount, currency, issue_date, due_date, status))
	
	def insert_payment(self, company_id: int, customer_id: int, external_id: str,
						amount: float, currency: str, payment_date: str, reference: str = None) -> int:
		"""
		Insert a new payment

		Returns:
			payment_id
		"""
		query = """
			INSERT INTO payments (company_id, customer_id, external_id, amount,
								currency, payment_date, reference)
			VALUES (%s, %s, %s, %s, %s, %s, %s)
			RETURNING id
		"""
		return self.execute_insert(query, (company_id, customer_id, external_id,
										   amount, currency, payment_date, reference))
	
	def insert_reconciliation(self, company_id: int, invoice_id: int, payment_id: int,
							matched_amount: float, confidence_score: int,
							status: str = 'PENDING_REVIEW', matched_by: str = 'SYSTEM') -> int:
		"""
		Insert a new reconciliation
		
		Returns:
			reconciliation_id
		"""
		query = """
			INSERT INTO reconciliations (company_id, invoice_id, payment_id, matched_amount,
									   confidence_score, status, matched_by)
			VALUES (%s, %s, %s, %s, %s, %s, %s)
			RETURNING id
		"""
		return self.execute_insert(query, (company_id, invoice_id, payment_id, matched_amount,
										   confidence_score, status, matched_by))
	
	def get_outstanding_invoices(self, company_id: int) -> List[Dict]:
		"""Get all outstanding invoices for a company"""
		query = """
			SELECT i.*, c.name AS customer_name, c.email AS customer_email
			FROM invoices AS i
			JOIN customers AS c
			  ON i.customer_id = c.id
			WHERE i.company_id = %s
			AND i.status IN ('OPEN', 'PARTIALLY_MATCHED', 'OVERDUE')
			ORDER BY i.due_date
		"""

		return self.execute_query(query, (company_id,))
	
	def get_unmatched_payments(self, company_id: int) -> List[Dict]:
		"""Get all unmatched or partially matched payments"""
		query = """
			SELECT
				p.id,
				p.external_id,
				p.payment_date,
				p.amount,
				c.name AS customer_name,
				COALESCE(SUM(r.matched_amount), 0) AS amount_matched,
				p.amount - COALESCE(SUM(r.matched_amount), 0) AS amount_remaining
			FROM payments AS p
			JOIN customers AS c
			  ON p.customer_id = c.id
			LEFT JOIN reconciliations AS r
			  ON p.id = r.payment_id
			  AND r.status != 'REJECTED'
			WHERE p.company_id = %s
			GROUP BY p.id, p.external_id, p.payment_date, p.amount, c.name
			HAVING p.amount > COALESCE(SUM(r.matched_amount), 0)
			ORDER BY p.payment_date
		"""
		return self.execute_query(query, (company_id,))
	
	def insert_audit_log(self, reconciliation_id: int, action: str,
					  	performed_by: str, notes: str = None) -> int:
		"""Insert audit log entry"""
		query = """
			INSERT INTO reconciliation_audit_log (reconciliation_id, action, performed_by, notes)
			VALUES (%s, %s, %s, %s)
			RETURNING id
		"""
		return self.execute_insert(query, (reconciliation_id, action, performed_by, notes))
	
	def test_connection(self) -> bool:
		"""Test database connection"""
		try:
			with self.get_connection() as conn:
				cursor = conn.cursor()
				cursor.execute("SELECT 1")
				return True
		except Exception as e:
			print(f"Connection failed: {e}")
			return False
		


if __name__ == "__main__":
    # Initialize database
    db = Database()
    
    # Test connection
    print("Testing database connection...")
    if db.test_connection():
        print("Connection successful!")
    else:
        print("Connection failed!")
        exit(1)
    
    # Example 1: Query all companies
    print("\n" + "="*50)
    print("Example 1: Get all companies")
    print("="*50)
    companies = db.execute_query("SELECT * FROM companies")
    for company in companies:
        print(f"  {company['id']}: {company['name']}")
    
    # Example 2: Get customers for company 1
    print("\n" + "="*50)
    print("Example 2: Get customers for company 1")
    print("="*50)
    customers = db.execute_query(
        "SELECT * FROM customers WHERE company_id = %s",
        (1,)
    )
    for customer in customers:
        print(f"  {customer['name']} ({customer['email']})")
    
    # Example 3: Get outstanding invoices
    print("\n" + "="*50)
    print("Example 3: Outstanding invoices for company 1")
    print("="*50)
    invoices = db.get_outstanding_invoices(1)
    for inv in invoices[:5]:  # Show first 5
        print(f"  {inv['invoice_number']}: ${inv['amount']} - {inv['customer_name']}")
    
    # Example 4: Get unmatched payments
    print("\n" + "="*50)
    print("Example 4: Unmatched payments for company 1")
    print("="*50)
    payments = db.get_unmatched_payments(1)
    for pmt in payments:
        print(f"  {pmt['external_id']}: ${pmt['amount_remaining']} remaining - {pmt['customer_name']}")
    
    print("\n" + "="*50)
    print("All examples completed!")
    print("="*50)