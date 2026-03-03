# Concept name


## My understanding
Analytic functions are SQL functions that perform calculations across a set of rows related to the current row, but without grouping the result into fewer rows, this means every original row stays visible while we can calculate things like rankings, running totals, moving averages or comparisons between rows inside the same partition.

## Why it matters
They matter because in real life we often need analysis without losing detail, for example when we want to rank employees by salary but still see each employee, or calculate cumulative sales per day while keeping every transaction, analytic functions let us analyze patterns and trends directly in SQL without needing extra subqueries or external tools.

## Example
SELECT 
    employee_name,
    department,
    salary,
    RANK() OVER (PARTITION BY department ORDER BY salary DESC) AS salary_rank
FROM employees;