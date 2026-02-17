# Lesson 1
-- Find the title of each film
- SELECT title FROM movies;

-- Find the director of each film
- SELECT director FROM movies;

-- Find the title and director of each film
- SELECT title, director FROM movies;

-- Find the title and year of each film
- SELECT title, year FROM movies;

-- Find all the information about each film
- SELECT * FROM movies;

# Lesson 2
-- Find the movie with a row id of 6
- SELECT * FROM movies WHERE id = '6';

-- Find the movies released in the years between 2000 and 2010
- SELECT * FROM movies WHERE year BETWEEN 2000 AND 2010;

-- Find the movies not released in the years between 2000 and 2010
- SELECT * FROM movies WHERE year NOT BETWEEN 2000 AND 2010;

-- Find the first 5 Pixar movies and their release year
- SELECT * FROM movies WHERE year <= 2003;



# Lesson 3
-- Find all the Toy Story movies
- SELECT * FROM movies WHERE title LIKE "Toy Story%";

-- Find all the movies directed by John Lasseter
- SELECT * FROM movies WHERE director LIKE "John Lasseter";

-- Find all the movies (and director) not directed by John Lasseter
- SELECT * FROM movies WHERE director NOT LIKE "John Lasseter";

-- Find all the WALL-* movies
- SELECT * FROM movies WHERE title LIKE "WALL-%";



# Lesson 4
-- List all directors of Pixar movies (alphabetically), without duplicates 
- SELECT DISTINCT director FROM movies ORDER BY director ASC;

-- List the last four Pixar movies released (ordered from most recent to least)
- SELECT * FROM movies ORDER BY year DESC LIMIT 4;

-- List the first five Pixar movies sorted alphabetically
- SELECT * FROM movies ORDER BY title ASC LIMIT 5;

-- List the next five Pixar movies sorted alphabetically
- SELECT * FROM movies ORDER BY title ASC LIMIT 5 OFFSET 5;


# Lesson 5
-- List all the Canadian cities and their populations 
- SELECT city, population FROM north_american_cities WHERE country = "Canada";

-- FOrder all the cities in the United States by their latitude from north to south
- SELECT city, latitude FROM north_american_cities WHERE country = "United States" ORDER BY latitude DESC;

-- List all the cities west of Chicago, ordered from west to east
- SELECT city, longitude FROM north_american_cities WHERE longitude < -87.629798 ORDER BY longitude ASC;

-- List the two largest cities in Mexico (by population)
- SELECT city FROM north_american_cities WHERE country = "Mexico" ORDER BY population DESC LIMIT 2;

-- List the third and fourth largest cities (by population) in the United States and their population
- SELECT city, population FROM north_american_cities WHERE country LIKE "United States" ORDER BY population DESC LIMIT 2 OFFSET 2;