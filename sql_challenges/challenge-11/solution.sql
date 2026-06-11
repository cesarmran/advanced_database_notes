-- Exercise 1 / Exercise 2
-- Create comments table
-- Each comment belongs to one task and one user.

CREATE TABLE comments (
    id          NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    task_id     NUMBER NOT NULL,
    user_id     NUMBER NOT NULL,
    content     VARCHAR2(1000) NOT NULL,
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_comments_task
        FOREIGN KEY (task_id) REFERENCES tasks(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_comments_user
        FOREIGN KEY (user_id) REFERENCES users(id),

    CONSTRAINT ck_comments_content_not_empty
        CHECK (content <> '')
);

-- Optional verification


SELECT table_name
FROM user_tables
WHERE table_name = 'COMMENTS';


-- Exercise 4
-- Example of the bad migration: adding estimated_hours


ALTER TABLE tasks
ADD estimated_hours NUMBER;

-- SQL equivalent of rollback for the bad column
-- This removes the column and its data.

ALTER TABLE tasks
DROP COLUMN estimated_hours;

COMMIT;

-- 1. Se usa ORM porque permite trabajar con clases y objetos de Python en lugar de escribir todo el SQL manualmente.

-- 2. Se usan migraciones porque ayudan a guardar el historial de cambios de la base de datos y aplicarlos de forma ordenada.

-- 3. Haría rollback cuando una migración salió mal, rompió algo o agregó un cambio que no debía ir.

-- 4. add() prepara un objeto para guardarlo en la sesión, pero commit() confirma y guarda los cambios en la base de datos.

-- 5. Las relaciones son útiles porque permiten conectar objetos relacionados, por ejemplo obtener las tareas de un usuario o los comentarios de una tarea sin escribir joins manuales.