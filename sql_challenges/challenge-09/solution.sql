-- Lesson 04 Solution: Transactions in Oracle
-- Topics: COMMIT, ROLLBACK, SAVEPOINT

-- Part 1. VERIFY INITIAL STATE
-- What does the accounts table look like at the start?


SELECT account_id, owner_name, balance
FROM accounts
ORDER BY account_id;


-- PART 2. SUCCESSFUL TRANSFER WITH COMMIT
-- Transfer $200 from Alice to Bob and make it permanent

UPDATE accounts
SET balance = balance - 200
WHERE account_id = 1;

UPDATE accounts
SET balance = balance + 200
WHERE account_id = 2;

-- Check balances before COMMIT
SELECT account_id, owner_name, balance
FROM accounts
ORDER BY account_id;

COMMIT;

SELECT account_id, owner_name, balance
FROM accounts
ORDER BY account_id;


-- PART 3. TRANSFER WITH ROLLBACK
-- Try to transfer $300 from Alice to Bob, then undo it

UPDATE accounts
SET balance = balance - 300
WHERE account_id = 1;

UPDATE accounts
SET balance = balance + 300
WHERE account_id = 2;

SELECT account_id, owner_name, balance
FROM accounts
ORDER BY account_id;


ROLLBACK;


-- PART 4. SAVEPOINT
-- Undo only part of the work, not the whole transaction

UPDATE accounts
SET balance = balance - 100
WHERE account_id = 1;

SAVEPOINT after_alice;

UPDATE accounts
SET balance = balance + 100
WHERE account_id = 3;

-- Wrong destination account, undo only the change after the savepoint
ROLLBACK TO SAVEPOINT after_alice;

-- Check state after partial rollback
SELECT account_id, owner_name, balance
FROM accounts
ORDER BY account_id;


-- Now apply the correct credit to Bob
UPDATE accounts
SET balance = balance + 100
WHERE account_id = 2;

SELECT account_id, owner_name, balance
FROM accounts
ORDER BY account_id;


COMMIT;




-- PART 5. FINAL ANSWER / CONCLUSION
-- What does this activity show?


-- 1. COMMIT makes changes permanent.
-- 2. ROLLBACK undoes all changes since the last COMMIT.
-- 3. SAVEPOINT allows a partial rollback inside one transaction.
-- 4. Transactions are important because they keep the database consistent.
-- 5. In a money transfer, both updates must happen together, if one part fails and there is no proper transaction control, the data can become inconsistent.