
-- Lesson 03 — Indexes: Class Exercises
-- Exercise 1 — Find the slow query


SELECT * FROM patient_visits WHERE site_id = 3;

-- a) What scan type do you see? Why?
-- Answer:
-- The scan type is usually a FULL TABLE SCAN,
-- because site_id has low cardinality and many rows match the condition.

-- b) site_id has values 1–5. Is this high or low cardinality?
-- Answer:
-- It is low cardinality,
-- because it only has a few possible values.

-- c) Would adding an index on site_id help? Why or why not?
-- Answer:
-- Usually no, because too many rows have the same value,
-- so the index is not very selective,
-- and Oracle may prefer a full table scan.


-- Exercise 2 — Create an index and see if it helps

-- Step 1  Create it
CREATE INDEX idx_pv_visit_date ON patient_visits(visit_date);

-- Step 2 Gather stats
BEGIN
    DBMS_STATS.GATHER_TABLE_STATS(USER, 'PATIENT_VISITS', cascade => TRUE);
END;
/

-- Step 3: Run the range query and check the plan
SELECT * FROM patient_visits
WHERE visit_date BETWEEN SYSDATE - 30 AND SYSDATE;

-- a) Does Oracle use the index for this range?
-- Answer: It may use the index, especially if the range returns a smaller part of the table.

-- b) Change the range to the last 7 days. Does the plan change?
SELECT * FROM patient_visits
WHERE visit_date BETWEEN SYSDATE - 7 AND SYSDATE;

-- Answer: Yes, Oracle is more likely to use the index, because fewer rows are returned.

-- c) Change to the last 700 days. What happens?
SELECT * FROM patient_visits
WHERE visit_date BETWEEN SYSDATE - 700 AND SYSDATE;

-- Answer: Oracle may switch to a FULL TABLE SCAN, because the query returns too many rows.

-- d) Why does the range size affect whether Oracle uses the index?
-- Answer: Because indexes are more useful when Oracle needs only a small portion of the table, if the query needs many rows, reading the full table can be faster.


-- Exercise 3 — Composite index

CREATE INDEX idx_pv_patient_date ON patient_visits(patient_id, visit_date);

BEGIN
    DBMS_STATS.GATHER_TABLE_STATS(USER, 'PATIENT_VISITS', cascade => TRUE);
END;
/

SELECT * FROM patient_visits
WHERE patient_id = 1234
  AND visit_date > SYSDATE - 90;

-- a) Does the plan use the composite index?
-- Answer: Yes, it should use the composite index, because both columns are included in the query.

-- b) Now try querying ONLY on visit_date (no patient_id).
--    Does the composite index get used? Why not?
SELECT * FROM patient_visits WHERE visit_date > SYSDATE - 90;

-- Answer: Usually no, because visit_date is the second column in the index,and Oracle uses composite indexes starting from the leftmost column.

-- c) What's the rule about column order in composite indexes?
-- Answer: Column order matters, Oracle can use the index efficiently starting from the first column on the left.

SELECT * FROM patient_visits WHERE patient_id = 1234;

-- This query can use the composite index, because patient_id is the first column.



-- Exercise 4 — Function that breaks an index

-- This query CAN use the index:
SELECT * FROM patient_visits WHERE patient_id = 5432;

-- This one cannot — why?
SELECT * FROM patient_visits WHERE TO_CHAR(patient_id) = '5432';

-- a) What scan type did the second query use?
-- Answer: It usually uses a FULL TABLE SCAN.

-- b) Why does wrapping a column in a function break index use?
-- Answer: Because the function changes the indexed expression, so the normal index on patient_id no longer matches the query.

-- c) How would you rewrite the second query to allow index use?
-- Answer:
SELECT * FROM patient_visits WHERE patient_id = 5432;



-- Exercise 5 — Discussion: real-world scenarios

-- A reporting table gets loaded once per night (batch ETL).
-- During the day, analysts run SELECT queries by date range, the table has 50 million rows.
-- → Index on date? Yes/No, why?

-- a) Would you add an index?
-- Answer: Yes.

-- b) On which column(s)?
-- Answer: On the date column.

-- c) Any concerns?
-- Answer: Indexes use extra space and need maintenance, but since the table is loaded in batch, the cost is more acceptable, and the index can help date range queries a lot.


-- Scenario B:
-- An OLTP orders table gets 10,000 inserts per minute.
-- Support staff look up orders by customer_id or order_status.
-- order_status has 4 values: pending, processing, shipped, cancelled.
-- What indexes would you add?

-- a) Would you add an index?
-- Answer: Yes.

-- b) On which column(s)?
-- Answer: On customer_id.

-- c) Any concerns?
-- Answer: I would be careful with order_status, because it has very low cardinality and may not help much alone, also, too many indexes slow down inserts.


-- Scenario C:
-- A patient table has an email column (unique per patient).
-- There are 5 million patients.
-- The app frequently does: WHERE email = 'user@example.com'
-- What kind of index would be best here?

-- a) Would you add an index?
-- Answer: Yes.

-- b) On which column(s)?
-- Answer: On email.

-- c) Any concerns?
-- Answer: A UNIQUE INDEX would be the best choice, because email is unique, highly selective, and frequently searched.



-- Cleanup — remove indexes created in these exercises
DROP INDEX idx_pv_patient_date;
DROP INDEX idx_pv_visit_date;