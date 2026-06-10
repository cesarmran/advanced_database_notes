DROP TABLE IF EXISTS comments;
DROP TABLE IF EXISTS tasks;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS teams;

CREATE TABLE teams (
    id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR2(50) NOT NULL UNIQUE,
    description VARCHAR2(200),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE users (
    id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    username VARCHAR2(50) NOT NULL UNIQUE,
    email VARCHAR2(100) NOT NULL,
    full_name VARCHAR2(100),
    team_id NUMBER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_users_team FOREIGN KEY (team_id) REFERENCES teams(id)
);

CREATE TABLE tasks (
    id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    title VARCHAR2(200) NOT NULL,
    description VARCHAR2(1000),
    status VARCHAR2(20) DEFAULT 'open',
    priority VARCHAR2(20) DEFAULT 'medium',
    assigned_to NUMBER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP,
    CONSTRAINT fk_tasks_user FOREIGN KEY (assigned_to) REFERENCES users(id),
    CONSTRAINT chk_tasks_priority CHECK (priority IN ('low', 'medium', 'high')),
    CONSTRAINT chk_tasks_status CHECK (status IN ('open', 'in_progress', 'closed'))
);

CREATE TABLE comments (
    id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    task_id NUMBER NOT NULL,
    user_id NUMBER NOT NULL,
    content VARCHAR2(1000) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_comments_task FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE,
    CONSTRAINT fk_comments_user FOREIGN KEY (user_id) REFERENCES users(id),
    CONSTRAINT chk_comments_content CHECK (content <> '')
);

-- Pregunta: What relationships should Comment have? Respuesta: Comment debe conectarse con Task y User porque cada comentario pertenece a una tarea y a un usuario

-- Pregunta: Should Task have a comments relationship? Respuesta: Sí porque una tarea puede tener varios comentarios y eso ayuda a verlos desde la misma tarea

-- Pregunta: What should happen to comments when a task is deleted? Respuesta: Se deberían borrar también para no dejar comentarios sueltos sin tarea

-- Pregunta: What does upgrade() do? Respuesta: Aplica los cambios nuevos a la base como crear la tabla comments

-- Pregunta: What does downgrade() do? Respuesta: Regresa la base al estado anterior quitando lo que agregó la migración

-- Pregunta: What happens if you downgrade this migration? Respuesta: Se elimina la tabla comments y también se pierde lo que estaba guardado ahí

INSERT INTO teams (name, description) VALUES ('Engineering', 'Software development team');
INSERT INTO teams (name, description) VALUES ('Product', 'Product management team');

INSERT INTO users (username, email, full_name, team_id) VALUES ('alice_dev', 'alice@example.com', 'Alice Smith', 1);
INSERT INTO users (username, email, full_name, team_id) VALUES ('bob_dev', 'bob@example.com', 'Bob Jones', 1);
INSERT INTO users (username, email, full_name, team_id) VALUES ('carol_pm', 'carol@example.com', 'Carol White', 2);

INSERT INTO tasks (title, description, status, priority, assigned_to) VALUES ('Fix login bug', 'Users cannot log in with SSO', 'open', 'high', 1);
INSERT INTO tasks (title, description, status, priority, assigned_to) VALUES ('Design new dashboard', 'Create mockups for analytics page', 'in_progress', 'medium', 3);
INSERT INTO tasks (title, description, status, priority, assigned_to) VALUES ('Update dependencies', 'Upgrade numpy and pandas', 'open', 'low', 2);

INSERT INTO comments (task_id, user_id, content) VALUES (1, 1, 'I am checking this bug');
INSERT INTO comments (task_id, user_id, content) VALUES (2, 3, 'The first design is ready');
INSERT INTO comments (task_id, user_id, content) VALUES (3, 2, 'I will update the packages');

INSERT INTO teams (name, description) VALUES ('DevOps', 'Team for operations and deployments');

INSERT INTO users (username, email, full_name, team_id) VALUES ('diana_ops', 'diana@example.com', 'Diana Ops', 3);

INSERT INTO tasks (title, description, status, priority, assigned_to) VALUES ('Configure pipeline', 'Set up the deployment pipeline', 'open', 'high', 4);
INSERT INTO tasks (title, description, status, priority, assigned_to) VALUES ('Check server logs', 'Review logs from the server', 'open', 'medium', 4);
INSERT INTO tasks (title, description, status, priority, assigned_to) VALUES ('Clean old files', 'Remove files that are not needed anymore', 'open', 'low', 4);

SELECT COUNT(*) AS task_count FROM tasks;

UPDATE tasks
SET status = 'closed', updated_at = CURRENT_TIMESTAMP
WHERE title = 'Configure pipeline';

DELETE FROM tasks
WHERE title = 'Clean old files' AND priority = 'low';

SELECT t.title, t.status, t.priority, u.username, tm.name AS team_name
FROM tasks t
JOIN users u ON t.assigned_to = u.id
JOIN teams tm ON u.team_id = tm.id
ORDER BY t.id;

-- Pregunta: What happens to the column? Respuesta: Si se hace rollback la columna estimated_hours se quita de la tabla

-- Pregunta: What happens to the data? Respuesta: Los datos de esa columna se pierden porque la columna ya no existe

ALTER TABLE tasks ADD estimated_hours NUMBER;

ALTER TABLE tasks DROP COLUMN estimated_hours;

-- Pregunta: Why use ORM instead of raw SQL? Respuesta: Porque es más fácil trabajar con clases y objetos sin escribir todo el SQL a mano

-- Pregunta: Why use migrations? Respuesta: Porque ayudan a guardar el historial de cambios de la base y aplicarlos con más orden

-- Pregunta: When would you rollback? Respuesta: Cuando una migración salió mal o metió un cambio que no debía ir

-- Pregunta: Difference between add() and commit()? Respuesta: add() prepara el objeto para guardarlo y commit() ya guarda el cambio en la base

-- Pregunta: Why are relationships useful? Respuesta: Porque permiten conectar tablas y moverse entre datos relacionados de forma más fácil

COMMIT;