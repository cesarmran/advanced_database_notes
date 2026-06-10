-- Exercise 1
-- Pregunta: ¿Cuál es la pregunta de negocio?
-- Respuesta: Saber qué equipo termina trabajo más rápido, pero de forma justa entre equipos de distinto tamaño
-- Pregunta: ¿Cuál es la definición exacta?
-- Respuesta: Team velocity es tareas completadas por integrante por día activo, solo cuenta tareas con status completed y completed_at no nulo, se une teams con users y tasks
-- Pregunta: ¿Cuáles son los edge cases?
-- Respuesta: Equipos sin usuarios, equipos sin tareas, tareas sin asignar, tareas canceladas, tareas completadas sin fecha de cierre, divisiones entre cero
-- Pregunta: ¿Cuál es la unidad?
-- Respuesta: Tareas completadas por integrante por día
-- Pregunta: ¿Qué puede hacer engañoso este KPI?
-- Respuesta: No tenemos story points ni dificultad, entonces una tarea simple pesa igual que una tarea crítica
WITH team_base AS (
    SELECT
        t.id AS team_id,
        t.name AS team_name,
        COUNT(DISTINCT u.id) AS team_members,
        COUNT(CASE WHEN ts.status = 'completed' AND ts.completed_at IS NOT NULL THEN 1 END) AS completed_tasks,
        NVL(MAX(TRUNC(CAST(ts.created_at AS DATE))) - MIN(TRUNC(CAST(ts.created_at AS DATE))) + 1, 0) AS active_days
    FROM teams t
    LEFT JOIN users u ON u.team_id = t.id
    LEFT JOIN tasks ts ON ts.assigned_to = u.id
    GROUP BY t.id, t.name
),
team_velocity AS (
    SELECT
        team_name,
        team_members,
        completed_tasks,
        active_days,
        ROUND(completed_tasks / NULLIF(team_members * active_days, 0), 3) AS velocity_tasks_per_member_day
    FROM team_base
),
overall_avg AS (
    SELECT AVG(velocity_tasks_per_member_day) AS avg_velocity
    FROM team_velocity
    WHERE velocity_tasks_per_member_day IS NOT NULL
)
SELECT
    tv.team_name,
    tv.team_members,
    tv.completed_tasks,
    tv.active_days,
    tv.velocity_tasks_per_member_day,
    ROUND(oa.avg_velocity, 3) AS overall_avg_velocity,
    CASE
        WHEN tv.velocity_tasks_per_member_day IS NULL THEN 'No data'
        WHEN tv.velocity_tasks_per_member_day < oa.avg_velocity THEN 'Below average'
        ELSE 'At or above average'
    END AS velocity_flag
FROM team_velocity tv
CROSS JOIN overall_avg oa
ORDER BY tv.velocity_tasks_per_member_day DESC NULLS LAST;

-- Exercise 2
-- Pregunta: ¿Cuál es la pregunta de negocio?
-- Respuesta: Saber si las tareas se entregan dentro de la fecha prometida
-- Pregunta: ¿Cuál es la definición exacta?
-- Respuesta: On time significa completada antes de que termine el día de due_date, se usan solo tareas completed con completed_at y due_date no nulos, se agrupa por prioridad
-- Pregunta: ¿Cuáles son los edge cases?
-- Respuesta: Tareas sin due_date, tareas sin completed_at, tareas canceladas, tareas abiertas, tareas completadas a las 23:59 del due_date, tareas completadas a las 00:01 del día siguiente
-- Pregunta: ¿Cuál es la unidad?
-- Respuesta: Porcentaje de entregas a tiempo y horas promedio de retraso
-- Pregunta: ¿Qué puede hacer engañoso este KPI?
-- Respuesta: Si se excluyen tareas abiertas muy atrasadas, el resultado puede verse mejor de lo real, también puede ocultar diferencias entre prioridades
SELECT
    priority,
    COUNT(*) AS completed_with_due_date,
    SUM(CASE WHEN completed_at < CAST(due_date + 1 AS TIMESTAMP) THEN 1 ELSE 0 END) AS on_time_tasks,
    ROUND(100 * SUM(CASE WHEN completed_at < CAST(due_date + 1 AS TIMESTAMP) THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0), 2) AS on_time_delivery_rate_pct,
    ROUND(AVG(CASE WHEN completed_at >= CAST(due_date + 1 AS TIMESTAMP) THEN (CAST(completed_at AS DATE) - (due_date + 1)) * 24 END), 2) AS avg_lateness_hours_for_late_tasks
FROM tasks
WHERE status = 'completed'
  AND completed_at IS NOT NULL
  AND due_date IS NOT NULL
GROUP BY priority
ORDER BY CASE priority
    WHEN 'critical' THEN 1
    WHEN 'high' THEN 2
    WHEN 'medium' THEN 3
    WHEN 'low' THEN 4
    ELSE 5
END;

-- Exercise 3
-- Pregunta: ¿Cuál era el problema del KPI original?
-- Respuesta: Contaba todas las tareas y podía hacer ver ocupado a un equipo aunque sus tareas ya estuvieran completadas o canceladas
-- Pregunta: ¿Cuál es la definición corregida?
-- Respuesta: Se muestran tareas totales, tareas activas open in_progress blocked, y completion_rate usando completed dividido entre total sin cancelled
-- Pregunta: ¿Cuáles son los edge cases?
-- Respuesta: Equipos sin tareas, tareas canceladas, equipos sin usuarios, tareas sin asignar
-- Pregunta: ¿Cuál es la unidad?
-- Respuesta: Conteo de tareas y porcentaje de completación
-- Pregunta: ¿Qué puede hacer engañoso este KPI?
-- Respuesta: No mide tamaño ni dificultad de tarea, solo cantidad
WITH team_workload AS (
    SELECT
        t.id AS team_id,
        t.name AS team_name,
        COUNT(ts.id) AS total_tasks,
        SUM(CASE WHEN ts.status IN ('open', 'in_progress', 'blocked') THEN 1 ELSE 0 END) AS active_tasks,
        SUM(CASE WHEN ts.status = 'completed' THEN 1 ELSE 0 END) AS completed_tasks,
        SUM(CASE WHEN ts.status <> 'cancelled' THEN 1 ELSE 0 END) AS valid_tasks
    FROM teams t
    LEFT JOIN users u ON u.team_id = t.id
    LEFT JOIN tasks ts ON ts.assigned_to = u.id
    GROUP BY t.id, t.name
)
SELECT
    team_name,
    total_tasks,
    active_tasks,
    ROUND(100 * completed_tasks / NULLIF(valid_tasks, 0), 2) AS completion_rate_pct,
    CASE
        WHEN active_tasks > 10 THEN 'Overloaded'
        WHEN active_tasks BETWEEN 5 AND 10 THEN 'Healthy'
        ELSE 'Underutilized'
    END AS health_score
FROM team_workload
ORDER BY active_tasks DESC;

-- Exercise 4
-- Pregunta: ¿Cuál era el problema del KPI original?
-- Promediaba todas las tareas completadas juntas y escondía diferencias importantes entre prioridades
-- Pregunta: ¿Cuál es la definición corregida?
-- Resolution time es el tiempo entre created_at y completed_at, solo para tareas completed con completed_at no nulo, agrupado por priority
-- Pregunta: ¿Cuáles son los edge cases?
-- Prioridades con una sola tarea, tareas completadas sin fecha, tareas con fechas raras, promedios afectados por valores extremos
-- Pregunta: ¿Cuál es la unidad?
-- Horas de resolución
-- Pregunta: ¿Qué puede hacer engañoso este KPI?
-- Un promedio puede esconder casos extremos, por eso se agrega mediana mínimo máximo y cantidad de tareas
WITH completed_tasks AS (
    SELECT
        priority,
        EXTRACT(DAY FROM (completed_at - created_at)) * 24 +
        EXTRACT(HOUR FROM (completed_at - created_at)) +
        EXTRACT(MINUTE FROM (completed_at - created_at)) / 60 +
        EXTRACT(SECOND FROM (completed_at - created_at)) / 3600 AS resolution_hours
    FROM tasks
    WHERE status = 'completed'
      AND completed_at IS NOT NULL
      AND created_at IS NOT NULL
),
priority_stats AS (
    SELECT
        priority,
        COUNT(*) AS completed_task_count,
        ROUND(AVG(resolution_hours), 2) AS avg_resolution_hours,
        ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY resolution_hours), 2) AS median_resolution_hours,
        ROUND(MIN(resolution_hours), 2) AS fastest_resolution_hours,
        ROUND(MAX(resolution_hours), 2) AS slowest_resolution_hours
    FROM completed_tasks
    GROUP BY priority
)
SELECT
    priority,
    completed_task_count,
    avg_resolution_hours,
    median_resolution_hours,
    fastest_resolution_hours,
    slowest_resolution_hours,
    CASE priority
        WHEN 'critical' THEN 24
        WHEN 'high' THEN 72
        WHEN 'medium' THEN 168
        WHEN 'low' THEN 336
    END AS target_sla_hours,
    CASE
        WHEN avg_resolution_hours <= CASE priority
            WHEN 'critical' THEN 24
            WHEN 'high' THEN 72
            WHEN 'medium' THEN 168
            WHEN 'low' THEN 336
        END THEN 'Target met'
        ELSE 'Target missed'
    END AS target_met,
    CASE
        WHEN completed_task_count = 1 THEN 'Low sample, read carefully'
        ELSE 'Sample is more useful'
    END AS sample_note
FROM priority_stats
ORDER BY CASE priority
    WHEN 'critical' THEN 1
    WHEN 'high' THEN 2
    WHEN 'medium' THEN 3
    WHEN 'low' THEN 4
    ELSE 5
END;

-- Exercise 5
-- Pregunta: ¿Cuál era el problema del KPI original?
-- Respuesta: Solo decía cuántas tareas estaban vencidas, pero no mostraba responsable, equipo, prioridad ni gravedad
-- Pregunta: ¿Cuál es la definición corregida?
-- Respuesta: Tarea overdue es una tarea con due_date menor que hoy, status distinto de completed y cancelled, y due_date no nulo
-- Pregunta: ¿Cuáles son los edge cases?
-- Respuesta: Tareas sin due_date, tareas canceladas, tareas completadas tarde, tareas sin usuario, tareas vencidas con distintas prioridades
-- Pregunta: ¿Cuál es la unidad?
-- Respuesta: Días de retraso, conteo de tareas vencidas y promedio de días vencidos
-- Pregunta: ¿Qué puede hacer engañoso este KPI?
-- Respuesta: Un total simple mezcla tareas críticas y tareas menores, por eso se calcula severity
WITH overdue_base AS (
    SELECT
        ts.title AS task_title,
        u.full_name AS assignee,
        t.name AS team_name,
        ts.priority,
        ts.due_date,
        TRUNC(SYSDATE) - ts.due_date AS days_overdue,
        CASE
            WHEN ts.priority = 'critical' AND TRUNC(SYSDATE) - ts.due_date > 0 THEN 'CRITICAL'
            WHEN ts.priority = 'high' AND TRUNC(SYSDATE) - ts.due_date > 2 THEN 'HIGH'
            WHEN ts.priority = 'medium' AND TRUNC(SYSDATE) - ts.due_date > 5 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS severity
    FROM tasks ts
    LEFT JOIN users u ON u.id = ts.assigned_to
    LEFT JOIN teams t ON t.id = u.team_id
    WHERE ts.due_date < TRUNC(SYSDATE)
      AND ts.status NOT IN ('completed', 'cancelled')
      AND ts.due_date IS NOT NULL
),
summary_by_severity AS (
    SELECT
        severity,
        COUNT(*) AS overdue_count,
        ROUND(AVG(days_overdue), 2) AS avg_days_overdue
    FROM overdue_base
    GROUP BY severity
)
SELECT
    'DETAIL' AS row_type,
    task_title,
    assignee,
    team_name,
    priority,
    due_date,
    days_overdue,
    severity,
    CAST(NULL AS NUMBER) AS overdue_count,
    CAST(NULL AS NUMBER) AS avg_days_overdue
FROM overdue_base
UNION ALL
SELECT
    'SUMMARY' AS row_type,
    'Summary for ' || severity AS task_title,
    NULL AS assignee,
    NULL AS team_name,
    NULL AS priority,
    NULL AS due_date,
    NULL AS days_overdue,
    severity,
    overdue_count,
    avg_days_overdue
FROM summary_by_severity
ORDER BY
    CASE row_type WHEN 'DETAIL' THEN 1 ELSE 2 END,
    CASE severity
        WHEN 'CRITICAL' THEN 1
        WHEN 'HIGH' THEN 2
        WHEN 'MEDIUM' THEN 3
        WHEN 'LOW' THEN 4
        ELSE 5
    END,
    days_overdue DESC NULLS LAST;

-- Exercise 6
-- Pregunta: ¿Qué está mal con el productivity_score?
-- Respuesta: Cuenta tareas asignadas, no tareas terminadas, no considera prioridad ni tiempo, y puede premiar cantidad aunque no haya avance real
-- Pregunta: ¿Cuál es la definición corregida?
-- Respuesta: Productividad es tareas completadas por día activo, ponderadas por prioridad, critical vale 4, high 3, medium 2, low 1
-- Pregunta: ¿Cuáles son los edge cases?
-- Respuesta: Usuarios sin tareas completadas, tareas sin completed_at, usuarios con pocas tareas, tareas de dificultad distinta aunque tengan la misma prioridad
-- Pregunta: ¿Cuál es la unidad?
-- Respuesta: Puntos ponderados completados por día activo
-- Pregunta: ¿Qué puede hacer engañoso este KPI?
-- Respuesta: La prioridad no siempre equivale a dificultad, entonces sigue siendo una aproximación
WITH user_completed AS (
    SELECT
        u.id AS user_id,
        u.full_name,
        COUNT(ts.id) AS completed_tasks,
        SUM(CASE ts.priority
            WHEN 'critical' THEN 4
            WHEN 'high' THEN 3
            WHEN 'medium' THEN 2
            WHEN 'low' THEN 1
            ELSE 0
        END) AS weighted_completed_points,
        NVL(MAX(TRUNC(CAST(ts.completed_at AS DATE))) - MIN(TRUNC(CAST(ts.completed_at AS DATE))) + 1, 0) AS active_completion_days
    FROM users u
    LEFT JOIN tasks ts ON ts.assigned_to = u.id
        AND ts.status = 'completed'
        AND ts.completed_at IS NOT NULL
    GROUP BY u.id, u.full_name
)
SELECT
    full_name,
    completed_tasks,
    weighted_completed_points,
    active_completion_days,
    ROUND(weighted_completed_points / NULLIF(active_completion_days, 0), 2) AS weighted_completed_points_per_day
FROM user_completed
ORDER BY weighted_completed_points_per_day DESC NULLS LAST;

-- Exercise 7
-- Pregunta: ¿Qué está mal con avg_task_id?
-- Respuesta: El ID de una tarea no mide eficiencia, es solo un identificador, promediarlo no tiene significado de negocio
-- Pregunta: ¿Cuál es la definición corregida?
-- Respuesta: Team efficiency es completed dividido entre total válido, excluyendo cancelled, por equipo
-- Pregunta: ¿Cuáles son los edge cases?
-- Respuesta: Equipos sin tareas, equipos con solo tareas canceladas, tareas sin asignar, equipos pequeños con pocos datos
-- Pregunta: ¿Cuál es la unidad?
-- Respuesta: Porcentaje de eficiencia
-- Pregunta: ¿Qué puede hacer engañoso este KPI?
-- Respuesta: Un equipo puede tener eficiencia alta con pocas tareas simples, por eso conviene leerlo junto con volumen y prioridad
WITH team_efficiency AS (
    SELECT
        t.id AS team_id,
        t.name AS team_name,
        SUM(CASE WHEN ts.status = 'completed' THEN 1 ELSE 0 END) AS completed_tasks,
        SUM(CASE WHEN ts.status <> 'cancelled' THEN 1 ELSE 0 END) AS valid_tasks
    FROM teams t
    LEFT JOIN users u ON u.team_id = t.id
    LEFT JOIN tasks ts ON ts.assigned_to = u.id
    GROUP BY t.id, t.name
)
SELECT
    team_name,
    completed_tasks,
    valid_tasks,
    ROUND(100 * completed_tasks / NULLIF(valid_tasks, 0), 2) AS team_efficiency_pct
FROM team_efficiency
ORDER BY team_efficiency_pct DESC NULLS LAST;

-- Exercise 8
-- Pregunta: ¿Qué está mal con el urgency_index original?
-- Respuesta: priority es texto y no se puede multiplicar de forma lógica, due_date es fecha y no se debe sumar como si fuera número de negocio
-- Pregunta: ¿Cuál es la definición corregida?
-- Respuesta: Urgency score usa peso numérico por prioridad y días hasta vencimiento, si está vencida sube la urgencia
-- Pregunta: ¿Cuáles son los edge cases?
-- Respuesta: Tareas sin due_date, tareas completadas, tareas canceladas, fechas pasadas, prioridades desconocidas
-- Pregunta: ¿Cuál es la unidad?
-- Respuesta: Puntaje de urgencia
-- Pregunta: ¿Qué puede hacer engañoso este KPI?
-- Respuesta: Es una regla simple, no mide impacto económico ni esfuerzo real
SELECT
    title,
    priority,
    due_date,
    status,
    CASE priority
        WHEN 'critical' THEN 4
        WHEN 'high' THEN 3
        WHEN 'medium' THEN 2
        WHEN 'low' THEN 1
        ELSE 0
    END AS priority_weight,
    due_date - TRUNC(SYSDATE) AS days_until_due,
    CASE
        WHEN due_date IS NULL THEN NULL
        ELSE
            CASE priority
                WHEN 'critical' THEN 4
                WHEN 'high' THEN 3
                WHEN 'medium' THEN 2
                WHEN 'low' THEN 1
                ELSE 0
            END * 10 - (due_date - TRUNC(SYSDATE))
    END AS urgency_score
FROM tasks
WHERE status NOT IN ('completed', 'cancelled')
ORDER BY urgency_score DESC NULLS LAST;
