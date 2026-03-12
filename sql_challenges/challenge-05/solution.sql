# SQL Challenge 01 – Set Operators

## Problem
Use SQL set operators to compare data from two brick collections.

## Schema
```sql
CREATE TABLE my_brick_collection (
  colour VARCHAR2(10),
  shape  VARCHAR2(10),
  weight INTEGER
);

CREATE TABLE your_brick_collection (
  height INTEGER,
  width  INTEGER,
  depth  INTEGER,
  colour VARCHAR2(10),
  shape  VARCHAR2(10)
);```

## Goal
Practice how to use UNION and INTERSECT with simple queries.

##Exercises
Return all colours from both tables without duplicates.
Return only the shapes that appear in both tables.

##Solution to try it 1

```select colour from my_brick_collection
union
select colour from your_brick_collection
order by colour;```

Complete the following query to return a list of all the shapes in both tables. There must show one row for each row in the source tables:
```select shape from my_brick_collection
union all
select shape from your_brick_collection
order by shape;```


##Solution to try it 2

```select shape from my_brick_collection
intersect
select shape from your_brick_collection
order by shape;```

Complete the following query to return a list of all the colours that are in both tables:
```select colour from my_brick_collection
intersect
select colour from your_brick_collection
order by colour;```