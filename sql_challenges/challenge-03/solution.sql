#Lesson 10
-- Find the longest time that an employee has been at the studio 
- SELECT MAX(years_employed) as Max_years_employed FROM employees;

-- For each role, find the average number of years employed by employees in that role
- SELECT role, AVG(years_employed) as Average_years_employed FROM employees GROUP BY role;

-- Find the total number of employee years worked in each building
- SELECT building, SUM(years_employed) as Total_years_employed FROM employees GROUP BY building;

#Part 2
-- Find the number of Artists in the studio (without a HAVING clause)
- SELECT role, COUNT(*) as Number_of_artists FROM employees WHERE role = "Artist";

-- Find the number of Employees of each role in the studio
- SELECT role, COUNT(*) FROM employees GROUP BY role;

-- Find the total number of years employed by all Engineers
- SELECT role, SUM(years_employed) FROM employees GROUP BY role HAVING role = "Engineer";


#Tutorial Solutions
#Try it 1
- select /* TODO */ number_of_shapes,
       /* TODO */ distinct_weight_stddev
from   bricks;



#try it 2
- select shape, /* TODO */ shape_weight
from   bricks
/* TODO */;

#try it 3
- select shape, sum ( weight )
from   bricks
group  by /* TODO */;