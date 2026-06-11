BEGIN EXECUTE IMMEDIATE 'DROP TABLE fact_ticket_daily'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE dim_agent'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE ticket_assignments'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE tickets'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

CREATE TABLE tickets (
    ticket_id   NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    title       VARCHAR2(200) NOT NULL,
    status      VARCHAR2(20) NOT NULL,
    priority    VARCHAR2(10) NOT NULL,
    created_at  TIMESTAMP NOT NULL,
    updated_at  TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    resolved_at TIMESTAMP,
    assigned_to NUMBER NOT NULL,
    CONSTRAINT chk_ticket_status CHECK (status IN ('open', 'in_progress', 'resolved', 'cancelled')),
    CONSTRAINT chk_ticket_priority CHECK (priority IN ('low', 'medium', 'high', 'critical'))
);

CREATE TABLE ticket_assignments (
    assignment_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ticket_id     NUMBER NOT NULL REFERENCES tickets(ticket_id),
    assigned_to   NUMBER NOT NULL,
    assigned_by   NUMBER,
    valid_from    TIMESTAMP NOT NULL,
    valid_to      TIMESTAMP
);

CREATE INDEX idx_ticket_assignments_lookup
ON ticket_assignments (ticket_id, valid_from, valid_to);

CREATE OR REPLACE TRIGGER trg_ticket_assignment_log
    AFTER INSERT OR UPDATE OF assigned_to ON tickets
    FOR EACH ROW
DECLARE
    v_change_time TIMESTAMP;
BEGIN
    IF INSERTING THEN
        INSERT INTO ticket_assignments (ticket_id, assigned_to, assigned_by, valid_from, valid_to)
        VALUES (:NEW.ticket_id, :NEW.assigned_to, NULL, :NEW.created_at, NULL);
    ELSIF UPDATING THEN
        v_change_time := COALESCE(:NEW.updated_at, CAST(SYSTIMESTAMP AS TIMESTAMP));

        UPDATE ticket_assignments
           SET valid_to = v_change_time
         WHERE ticket_id = :OLD.ticket_id
           AND valid_to IS NULL;

        INSERT INTO ticket_assignments (ticket_id, assigned_to, assigned_by, valid_from, valid_to)
        VALUES (:NEW.ticket_id, :NEW.assigned_to, NULL, v_change_time, NULL);
    END IF;
END;
/

INSERT INTO tickets (title, status, priority, created_at, updated_at, resolved_at, assigned_to)
VALUES ('Cannot access account', 'resolved', 'high', TIMESTAMP '2026-05-01 09:00:00', TIMESTAMP '2026-05-01 09:00:00', TIMESTAMP '2026-05-02 15:00:00', 1);

INSERT INTO tickets (title, status, priority, created_at, updated_at, resolved_at, assigned_to)
VALUES ('Payment not reflected', 'open', 'critical', TIMESTAMP '2026-05-03 10:00:00', TIMESTAMP '2026-05-03 10:00:00', NULL, 2);

INSERT INTO tickets (title, status, priority, created_at, updated_at, resolved_at, assigned_to)
VALUES ('Update delivery address', 'open', 'medium', TIMESTAMP '2026-05-04 11:00:00', TIMESTAMP '2026-05-04 11:00:00', NULL, 4);

INSERT INTO tickets (title, status, priority, created_at, updated_at, resolved_at, assigned_to)
VALUES ('Refund request', 'resolved', 'medium', TIMESTAMP '2026-05-05 08:30:00', TIMESTAMP '2026-05-05 08:30:00', TIMESTAMP '2026-05-06 13:00:00', 3);

INSERT INTO tickets (title, status, priority, created_at, updated_at, resolved_at, assigned_to)
VALUES ('App crashes on login', 'in_progress', 'high', TIMESTAMP '2026-05-06 12:00:00', TIMESTAMP '2026-05-06 12:00:00', NULL, 1);

INSERT INTO tickets (title, status, priority, created_at, updated_at, resolved_at, assigned_to)
VALUES ('Wrong invoice data', 'resolved', 'low', TIMESTAMP '2026-05-07 09:30:00', TIMESTAMP '2026-05-07 09:30:00', TIMESTAMP '2026-05-08 17:00:00', 2);

UPDATE tickets
   SET assigned_to = 3,
       updated_at = TIMESTAMP '2026-05-04 10:00:00'
 WHERE ticket_id = 2;

UPDATE tickets
   SET status = 'resolved',
       resolved_at = TIMESTAMP '2026-05-05 16:00:00',
       updated_at = TIMESTAMP '2026-05-05 16:00:00'
 WHERE ticket_id = 2;

COMMIT;

SELECT t.ticket_id,
       t.title,
       t.assigned_to AS current_agent,
       ta.assigned_to AS historical_agent,
       ta.valid_from,
       ta.valid_to
FROM tickets t
JOIN ticket_assignments ta ON ta.ticket_id = t.ticket_id
WHERE t.ticket_id = 2
ORDER BY ta.valid_from;

CREATE TABLE dim_agent (
    agent_key  NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    agent_name VARCHAR2(100) NOT NULL,
    team       VARCHAR2(50) NOT NULL
);

CREATE TABLE fact_ticket_daily (
    fact_key         NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    date_key         NUMBER NOT NULL,
    agent_key        NUMBER NOT NULL REFERENCES dim_agent(agent_key),
    status           VARCHAR2(20) NOT NULL,
    priority         VARCHAR2(10) NOT NULL,
    tickets_created  NUMBER DEFAULT 0 NOT NULL,
    tickets_resolved NUMBER DEFAULT 0 NOT NULL,
    CONSTRAINT uq_fact_ticket_daily UNIQUE (date_key, agent_key, status, priority)
);

INSERT INTO dim_agent (agent_name, team) VALUES ('Ana Torres', 'Support');
INSERT INTO dim_agent (agent_name, team) VALUES ('Bruno Garcia', 'Billing');
INSERT INTO dim_agent (agent_name, team) VALUES ('Carla Ruiz', 'Billing');
INSERT INTO dim_agent (agent_name, team) VALUES ('Diego Flores', 'Support');
COMMIT;

DELETE FROM fact_ticket_daily;

INSERT INTO fact_ticket_daily (
    date_key,
    agent_key,
    status,
    priority,
    tickets_created,
    tickets_resolved
)
WITH ticket_events AS (
    SELECT TO_NUMBER(TO_CHAR(t.created_at, 'YYYYMMDD')) AS date_key,
           ta.assigned_to AS agent_key,
           t.status,
           t.priority,
           1 AS tickets_created,
           0 AS tickets_resolved
    FROM tickets t
    JOIN ticket_assignments ta
      ON ta.ticket_id = t.ticket_id
     AND ta.valid_from <= t.created_at
     AND (ta.valid_to IS NULL OR ta.valid_to > t.created_at)

    UNION ALL

    SELECT TO_NUMBER(TO_CHAR(t.resolved_at, 'YYYYMMDD')) AS date_key,
           ta.assigned_to AS agent_key,
           t.status,
           t.priority,
           0 AS tickets_created,
           1 AS tickets_resolved
    FROM tickets t
    JOIN ticket_assignments ta
      ON ta.ticket_id = t.ticket_id
     AND ta.valid_from <= t.resolved_at
     AND (ta.valid_to IS NULL OR ta.valid_to > t.resolved_at)
    WHERE t.resolved_at IS NOT NULL
)
SELECT date_key,
       agent_key,
       status,
       priority,
       SUM(tickets_created),
       SUM(tickets_resolved)
FROM ticket_events
GROUP BY date_key, agent_key, status, priority;

COMMIT;

SELECT f.date_key,
       da.agent_name,
       da.team,
       f.status,
       f.priority,
       f.tickets_created,
       f.tickets_resolved
FROM fact_ticket_daily f
JOIN dim_agent da ON da.agent_key = f.agent_key
ORDER BY f.date_key, da.agent_name, f.status, f.priority;
