import csv
from datetime import datetime

VALID_CURRENCIES = {'USD', 'EUR', 'JPY', 'GBP', 'AUD', 'CAD', 'CHF', 'CNY', 'INR', 'BRL', 'ZAR', 'SGD', 'NZD', 'HKD'}

def read_csv_lines(path: str) -> list[str]:
	records = []

	with open(path, "r", encoding="utf-8") as file:
		reader = csv.DictReader(file)

		for row in reader:
			records.append(row)

	return records

def validate_invoice_number(invoice_number: str) -> tuple:
	"""Validate invoice number format: INV-XXX where XXX is digits"""
	if not invoice_number:
		return False, "Missing invoice number"

	invoice_number = invoice_number.strip()

	if not invoice_number.startswith("INV-"):
		return False, f"Invoice number must start with 'INV-', got: {invoice_number}"
	
	suffix = invoice_number[4:]

	if not suffix or not suffix.isdigit():
		return False, f"Invoice number suffix must be numeric, got: {suffix}"
	
	return True, None

def validate_name(name: str) -> tuple:
	"""Validate customer name is not empty"""
	if not name or not name.strip():
		return False, "Missing customer name"
	
	if len(name) > 200:
		return False, f"Customer name too long (max 200 chars): {len(name)}"
	
	return True, None

def validate_amount(amount: str) -> tuple:
	"""Validate amount is positive decimal with max 2 decimal places"""
	if not amount:
		return False, "Missing amount"
	
	try:
		amount_float = float(amount)
		if amount_float <= 0:
			return False, "amount should be > 0"
	except:
			return False, "amount should be float"

	return True, None		

def validate_currency(currency: str) -> tuple:
	"""Validate currency is in supported list"""
	if not currency:
		return False, "Missing currency"

	currency_upper = currency.strip().upper()

	if currency_upper not in VALID_CURRENCIES:
		return False, f"Invalid currency: {currency}. Valid: {', '.join(VALID_CURRENCIES)}"

	return True, None

def validate_date(date: str) -> tuple:
	"""Validate date format YYYY-MM-DD"""
	if not date:
		return False, "Missing date"

	try:
		datetime.strptime(date, "%Y-%m-%d")
		return True, None
	except ValueError as e:
		return False, f"Invalid date: {e}"


def validate_record_col(record: dict, col: str) -> tuple:
	if col == "invoice_number":
		return validate_invoice_number(record[col])
	elif col == "customer_name":
		return validate_name(record[col])
	elif col == "amount":
		return validate_amount(record[col])
	elif col == "currency":
		return validate_currency(record[col])
	elif col == "issue_date" or col == "due_date":
		return validate_date(record[col])
	else:
		return False, "Invalid column name"
	
def validate_invoice_date(issue_date: str, due_date: str) -> str:
	"""Validate due_date >= issue_date"""
	try:
		issue = datetime.strptime(issue_date, "%Y-%m-%d")
		due = datetime.strptime(due_date, "%Y-%m-%d")

		if due < issue:
			return f"Due date ({due_date}) cannot be before issue date ({issue_date})"
		else:
			return None
	except ValueError as e:
		return f"Invalid date: {e}"

def validate_records(records: list[dict]) -> tuple:
	"""
	Validate all invoice records
	
	Returns:
		Tuple of (valid_records, all_errors)
	"""
	if not records:
		return (None, None)
	
	valid_records: list[dict] = []
	errors: list[str] = []
	header_cols = [head_col for head_col in records[0]]

	for record in records:
		flag = 1
		for col in header_cols:
			valid, error = validate_record_col(record, col)
			if not valid:
				errors.append({
					'field': col,
					'value': record[col],
					'error': error
				})
				flag = 0
				continue
		error = validate_invoice_date(record["issue_date"], record["due_date"])
		if error:
			errors.append({
					'field': col,
					'value': record[col],
					'error': error
				})
		if flag and not error:
			valid_records.append(record)
	
	return (valid_records, errors)

def ingest_invoices(csv_path: str) -> tuple:
	"""
	Main function to ingest and validate invoices from CSV
	
	Args:
		csv_path: Path to invoice CSV file
		
	Returns:
		Tuple of (valid_records, errors)
	"""
	print(f"Reading invoices from: {csv_path}")
	
	try:
		records = read_csv_lines(csv_path)
		print(f"Found {len(records)} records")
	except Exception as e:
		print(f"Failed to parse CSV: {e}")
		return [], []
	
	print("Validating records...")
	valid_records, errors = validate_records(records)
	
	print(f"Valid records: {len(valid_records)}")
	print(f"Invalid records: {len(errors)}")
	
	if errors:
		print("\nValidation Errors:")
		for error in errors[:10]:
			print(f"  Field '{error['field']}': {error['error']}")
		
		if len(errors) > 10:
			print(f"  ... and {len(errors) - 10} more errors")
	
	return valid_records, errors

def insert_invoices_to_db(valid_records: list[dict], company_id: int = 1) -> dict:
	"""
	Insert validated invoice records into database
	
	Args:
		valid_records: List of validated invoice records
		company_id: Company ID to associate invoices with
		
	Returns:
		Dictionary with statistics
	"""
	from database import Database
	
	db = Database()
	stats = {
		'customers_created': 0,
		'customers_existing': 0,
		'invoices_inserted': 0,
		'errors': []
	}
	
	print(f"\n{'='*50}")
	print(f"Inserting {len(valid_records)} invoices into database...")
	print(f"{'='*50}\n")
	
	for record in valid_records:
		try:
			# 1. Get or create customer
			customer = db.get_customer_by_email(company_id, record['customer_email'])
			
			if customer:
				customer_id = customer['id']
				stats['customers_existing'] += 1
				print(f"  ✓ Found customer: {record['customer_name']}")
			else:
				customer_id = db.insert_customer(
					company_id=company_id,
					name=record['customer_name'],
					email=record['customer_email'],
					phone=None
				)
				stats['customers_created'] += 1
				print(f"  + Created customer: {record['customer_name']}")
			
			# 2. Insert invoice
			invoice_id = db.insert_invoice(
				company_id=company_id,
				customer_id=customer_id,
				invoice_number=record['invoice_number'],
				amount=float(record['amount']),
				currency=record['currency'],
				issue_date=record['issue_date'],
				due_date=record['due_date'],
				status='OPEN'
			)
			stats['invoices_inserted'] += 1
			print(f"  ✓ Inserted invoice: {record['invoice_number']} (${record['amount']})")
			
		except Exception as e:
			error_msg = f"Failed to insert {record['invoice_number']}: {e}"
			stats['errors'].append(error_msg)
			print(f"  ✗ {error_msg}")
	
	return stats


if __name__ == "__main__":
	import os
	
	# Determine CSV path
	if os.path.exists("/app/data/invoices.csv"):
		csv_path = "/app/data/invoices.csv"
	else:
		csv_path = "../data/invoices.csv"
	
	# Step 1: Validate CSV
	valid_records, errors = ingest_invoices(csv_path)
	
	print(f"\n{'='*50}")
	print(f"Validation Summary: {len(valid_records)} valid, {len(errors)} errors")
	print(f"{'='*50}")
	
	stats = insert_invoices_to_db(valid_records)
	
	print(f"\n{'='*50}")
	print("INSERTION SUMMARY")
	print(f"{'='*50}")
	print(f"Customers created:  {stats['customers_created']}")
	print(f"Customers existing: {stats['customers_existing']}")
	print(f"Invoices inserted:  {stats['invoices_inserted']}")
	print(f"Errors:             {len(stats['errors'])}")
	print(f"{'='*50}")