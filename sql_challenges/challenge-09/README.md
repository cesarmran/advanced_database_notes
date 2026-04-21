![alt text](image.png)
![alt text](image-1.png)
![alt text](image-2.png)
![alt text](image-3.png)

Today's Class Material
--- 01_setup.sql

-- Lesson 04: Setup
-- Create a simple accounts table for the transfer demo

DROP TABLE accounts PURGE;

CREATE TABLE accounts (
    account_id   NUMBER PRIMARY KEY,
    owner_name   VARCHAR2(50) NOT NULL,
    balance      NUMBER(10,2) NOT NULL CHECK (balance >= 0)
);

INSERT INTO accounts VALUES (1, 'Alice',  1000.00);
INSERT INTO accounts VALUES (2, 'Bob',     500.00);
INSERT INTO accounts VALUES (3, 'Charlie', 250.00);
COMMIT;

-- Verify starting state
SELECT account_id, owner_name, balance FROM accounts ORDER BY account_id;
-- Expected: Alice=1000, Bob=500, Charlie=250

 

---  02_no_transaction.sql

-- Lesson 04: The Broken Transfer — What Happens Without a Transaction
-- Run this to show the problem. Imagine the server crashes after line 1.

-- Step 1: Debit Alice
UPDATE accounts SET balance = balance - 500 WHERE account_id = 1;

-- >>> IMAGINE THE SERVER CRASHES HERE <<<
-- The UPDATE above is pending (not committed).
-- But in Oracle, DDL statements auto-commit. If something triggers a commit
-- before ROLLBACK, Alice loses $500 that never reaches Bob.

-- Step 2: Credit Bob (never runs if crash happens)
UPDATE accounts SET balance = balance + 500 WHERE account_id = 2;

-- Without wrapping this in a transaction:
-- - If step 1 commits but step 2 never runs → $500 disappears
-- - The database is in an INCONSISTENT state

-- Check current state (run after simulating crash)
SELECT account_id, owner_name, balance FROM accounts ORDER BY account_id;

-- Clean up for next demo
ROLLBACK;
SELECT account_id, owner_name, balance FROM accounts ORDER BY account_id;
-- Balances should be back to starting values

 

--  03_with_transaction.sql

-- Lesson 04: Transactions — COMMIT, ROLLBACK, SAVEPOINT

-- ============================================================
-- DEMO 1: Successful transfer with COMMIT
-- ============================================================

-- Start point
SELECT account_id, owner_name, balance FROM accounts ORDER BY account_id;

-- Transfer $200 from Alice to Bob
UPDATE accounts SET balance = balance - 200 WHERE account_id = 1;
UPDATE accounts SET balance = balance + 200 WHERE account_id = 2;

-- Verify before committing (only visible in this session)
SELECT account_id, owner_name, balance FROM accounts ORDER BY account_id;
-- Alice: 800, Bob: 700

-- Make it permanent
COMMIT;

-- Now everyone can see it
SELECT account_id, owner_name, balance FROM accounts ORDER BY account_id;


-- ============================================================
-- DEMO 2: ROLLBACK — undo everything
-- ============================================================

-- Try to transfer $300 from Alice to Bob, then change mind
UPDATE accounts SET balance = balance - 300 WHERE account_id = 1;
UPDATE accounts SET balance = balance + 300 WHERE account_id = 2;

-- Check state (not committed yet)
SELECT account_id, owner_name, balance FROM accounts ORDER BY account_id;
-- Alice: 500, Bob: 1000

-- Undo it — ROLLBACK takes us back to the last COMMIT
ROLLBACK;

SELECT account_id, owner_name, balance FROM accounts ORDER BY account_id;
-- Alice: 800, Bob: 700 — back to post-COMMIT state


-- ============================================================
-- DEMO 3: SAVEPOINT — partial rollback
-- ============================================================

-- Multi-step workflow: update Alice, set a savepoint, update Bob, decide to undo only Bob
UPDATE accounts SET balance = balance - 100 WHERE account_id = 1;

SAVEPOINT after_alice;

UPDATE accounts SET balance = balance + 100 WHERE account_id = 3;  -- Charlie, not Bob

-- Actually no — wrong account. Roll back to savepoint, not the beginning.
ROLLBACK TO SAVEPOINT after_alice;

-- Alice's change is still pending, Charlie's is undone
SELECT account_id, owner_name, balance FROM accounts ORDER BY account_id;
-- Alice: 700 (pending), Bob: 700, Charlie: 250 (restored)

-- Now do the right update
UPDATE accounts SET balance = balance + 100 WHERE account_id = 2;

SELECT account_id, owner_name, balance FROM accounts ORDER BY account_id;
-- Alice: 700, Bob: 800, Charlie: 250

COMMIT;