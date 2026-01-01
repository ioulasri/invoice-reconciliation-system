-- =====================================================
-- QUERY 1: Outstanding Invoices by Customer
-- =====================================================
-- Shows unpaid invoices grouped by customer
-- Used by: Finance team for collections
-- =====================================================

SELECT
	c.name AS customer_name,
	c.email AS customer_email,
	COUNT(i.id) AS total_invoices,
	SUM(i.amount) AS total_amount_due,
	MIN(i.due_date) AS oldest_due_date,
	MAX(i.due_date) AS newest_due_date

FROM customers c

LEFT JOIN invoices i ON c.id = i.customer_id
	AND i.status IN ('OPEN', 'PARTIALLY_MATCHED', 'OVERDUE')

WHERE c.company_id = 1
GROUP BY c.id, c.name, c.email

HAVING SUM(i.amount) > 0

ORDER BY total_amount_due DESC;
