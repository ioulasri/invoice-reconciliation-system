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

-- =====================================================
-- QUERY 2: Unmatched Payments
-- =====================================================
-- Shows payments that haven't been reconciled yet
-- Used by: Finance team to identify unallocated funds
-- =====================================================

SELECT
	p.external_id,
	p.payment_date,
	c.name AS customer_name,
	p.amount AS payment_amount,
	COALESCE(SUM(r.matched_amount), 0) AS amount_matched,
	p.amount - COALESCE(SUM(r.matched_amount), 0) AS amount_remaining,
	CASE
		WHEN SUM(r.matched_amount) IS NULL THEN 'FULLY_UNMATCHED'
		WHEN p.amount > SUM(r.matched_amount) THEN 'PARTIALLY_MATCHED'
		ELSE 'FULLY_MATCHED'
	END AS match_status

FROM payments p
JOIN customers c ON p.customer_id = c.id
LEFT JOIN reconciliations r on p.id = r.payment_id
	AND r.status != 'REJECTED'
WHERE p.company_id = 1
GROUP BY p.id, p.external_id, p.payment_date, c.name, p.amount
HAVING p.amount > COALESCE(SUM(r.matched_amount), 0)
ORDER BY p.payment_date ASC;

-- =====================================================
-- QUERY 3: Reconciliation Status Report
-- =====================================================
-- Dashboard showing reconciliation performance metrics
-- Used by: Management for KPI tracking
-- =====================================================

SELECT
	TO_CHAR(r.matched_at, 'YYYY-MM') AS month,
	COUNT(*) AS total_reconciliations,
	COUNT(CASE WHEN r.status = 'AUTO_MATCHED' THEN 1 END) AS auto_matched,
	COUNT(CASE WHEN r.status = 'PENDING_REVIEW' THEN 1 END) AS pending_review,
	COUNT(CASE WHEN r.status = 'REJECTED' THEN 1 END) AS rejected,
	ROUND(
		100.0 * COUNT(CASE WHEN r.status = 'AUTO_MATCHED' THEN 1 END) / COUNT(*), 2
	) AS auto_match_rate_percent,
	SUM(r.matched_amount) AS total_amount_reconcilied,
	ROUND(AVG(r.confidence_score), 2) AS avg_confidence_score

FROM reconciliations r
WHERE r.company_id = 1
GROUP BY TO_CHAR(r.matched_at, 'YYYY-MM')
ORDER BY month DESC;
