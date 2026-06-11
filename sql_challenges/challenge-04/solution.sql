# Try it 1

- select b.*,
       count(*) over (
         partition by shape
       ) bricks_per_shape,
       median(weight) over (
         partition by shape
       ) median_weight_per_shape
from bricks b
order by shape, weight, brick_id;


# Try it 2
-select b.brick_id,
       b.weight,
       round(
         avg(weight) over (
           order by brick_id
         ),
         2
       ) running_average_weight
from bricks b
order by brick_id;

#Try it 3
- select b.*,
       min(colour) over (
         order by brick_id
         rows between 2 preceding and 1 preceding
       ) first_colour_two_prev,
       count(*) over (
         order by weight
         range between current row and 1 following
       ) count_values_this_and_next
from bricks b
order by weight;


#Try it 4

- with totals as (
  select b.*,
         sum(weight) over (
           partition by shape
         ) weight_per_shape,
         sum(weight) over (
           order by brick_id, weight
           rows between unbounded preceding and current row
         ) running_weight_by_id
  from bricks b
)
select *
from totals
where weight_per_shape > 4
  and running_weight_by_id > 4
order by brick_id;


#Data Lemur Challenge
- WITH ranked AS (
  SELECT
    e.name,
    e.salary,
    e.department_id,
    DENSE_RANK() OVER (
      PARTITION BY e.department_id
      ORDER BY e.salary DESC
    ) AS salary_rank
  FROM employee e
)
SELECT
  d.department_name,
  r.name,
  r.salary
FROM ranked r
JOIN department d
  ON r.department_id = d.department_id
WHERE r.salary_rank <= 3
ORDER BY
  d.department_name ASC,
  r.salary DESC,
  r.name ASC;