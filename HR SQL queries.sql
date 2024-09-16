--database creation
CREATE DATABASE HR_project;

--Setting the created database to default.
USE HR_project;

--Query all data after importation
SELECT * FROM hr;

-- This is to check columns description in the table
EXEC sp_help 'hr'

--Date cleaning
EXEC sp_rename 'hr.id', 'emp_id';
EXEC sp_rename 'hr.birthdate', 'birth_date';
EXEC sp_rename 'hr.jobtitle', 'job_title';

UPDATE hr --i have to remove string from termdate before converting it to datatype
SET termdate =
	CASE
		WHEN termdate LIKE ('%UTC')THEN 
		REPLACE(termdate, ' UTC', '') 
		ELSE NULL
		END;
EXEC sp_rename 'hr.termdate', 'term_date';

 --convert birth_date, hire_date and term_date datatype for DATE
ALTER TABLE hr
ALTER COLUMN birth_date DATE;

ALTER TABLE hr
ALTER COLUMN hire_date DATE;

ALTER TABLE hr
ALTER COLUMN term_date DATE;

--needs to generate age column
ALTER TABLE hr 
ADD age INT;

-- insert value into the newly created age column
UPDATE hr
SET age = DATEDIFF(YEAR,birth_date,GETDATE()); 

--checking for outliers in the age column

SELECT 
	MIN(age) AS youngest,
	MAX(age) AS oldest
FROM 
	hr; -- No outliers

-- QUESTIONS
-- 1. What is the gender breakdown of employees in the company?
SELECT
	gender,
	COUNT(*) AS count
FROM 
	hr
WHERE term_date IS NOT NULL
GROUP BY gender;

-- 2. What is the race/ethnicity breakdown of employees in the company?
SELECT 
	race,
	COUNT(*) AS count
FROM hr
WHERE term_date IS NOT NULL
GROUP BY race
ORDER BY COUNT(*) DESC;

-- 3a. What is the age distribution of employees in the company?
SELECT 
	MIN(age) youngest,
	MAX(age) oldest
FROM hr
WHERE term_date IS NOT NULL;

SELECT 
	CASE
		WHEN age >=18 AND age <=24 THEN '18-24'
		WHEN age <=25 AND age <=34 THEN '25-34'
		WHEN age <=35 AND age <=44 THEN '35-44'
		WHEN age <=45 AND age <=54 THEN '45-54'
		ELSE '55+'
		END AS age_group,
		COUNT(*) AS count
FROM hr
WHERE term_date IS NOT NULL 
GROUP BY CASE
		WHEN age >=18 AND age <=24 THEN '18-24'
		WHEN age <=25 AND age <=34 THEN '25-34'
		WHEN age <=35 AND age <=44 THEN '35-44'
		WHEN age <=45 AND age <=54 THEN '45-54'
		ELSE '55+'
		END 
ORDER BY age_group;

-- 3b. What is the age distribution of employees in the company per gender?
SELECT 
	CASE
		WHEN age >=18 AND age <=24 THEN '18-24'
		WHEN age <=25 AND age <=34 THEN '25-34'
		WHEN age <=35 AND age <=44 THEN '35-44'
		WHEN age <=45 AND age <=54 THEN '45-54'
		ELSE '55+'
		END AS age_group,
		gender,
		COUNT(*) AS count
FROM hr
WHERE term_date IS NOT NULL 
GROUP BY CASE
		WHEN age >=18 AND age <=24 THEN '18-24'
		WHEN age <=25 AND age <=34 THEN '25-34'
		WHEN age <=35 AND age <=44 THEN '35-44'
		WHEN age <=45 AND age <=54 THEN '45-54'
		ELSE '55+'
		END, gender 
ORDER BY age_group, gender;


-- 4. How many employees work at headquarters versus remote locations?
SELECT
	[location],
	COUNT(*) AS count
FROM hr
WHERE term_date IS NOT NULL
GROUP BY [location]

-- 5. What is the average length of employment for employees who have been terminated?
SELECT
	AVG(DATEDIFF(YEAR,hire_date,term_date)) AS avg_length_employment 
FROM hr
WHERE term_date IS NOT NULL AND term_date<=GETDATE()


-- 6. How does the gender distribution vary across departments?
SELECT
	gender,
	department,
	COUNT (*) AS count
FROM hr
WHERE term_date IS NOT NULL 
GROUP BY gender, department
ORDER BY department;

-- 7. What is the distribution of job titles across the company?
SELECT 
	job_title,
	COUNT(*) AS count 
FROM hr
WHERE term_date IS NOT NULL 
GROUP BY job_title
ORDER BY job_title;

-- 8. Which department has the highest turnover rate?
SELECT 
	department,
	total_count,
	terminated_count,
	ROUND((terminated_count/total_count),4) AS termination_rate
FROM
	(SELECT 
		department,
		COUNT(*) AS total_count,
		CAST(SUM(CASE
				WHEN term_date IS NOT NULL AND term_date <= GETDATE()
				THEN 1 ELSE 0 END) AS FLOAT) AS terminated_count
	FROM hr
	GROUP BY department) AS subquery
ORDER BY termination_rate DESC;


-- 9. What is the distribution of employees across locations state?
SELECT 
	location_state,
	COUNT(*) AS count
FROM hr
WHERE term_date IS NOT NULL 
GROUP BY location_state
ORDER BY COUNT(*) DESC;

-- 10. How has the company's employee count changed over time based on hire and term dates?
WITH CTE AS	
	(SELECT
		DATEPART(YEAR,hire_date) AS [years],
		COUNT(*) AS hires,
		CAST(SUM(CASE
				WHEN term_date IS NOT NULL AND term_date <= GETDATE()
				THEN 1 ELSE 0 END) AS FLOAT) AS termination
	FROM
		hr
	GROUP BY DATEPART(YEAR,hire_date))
SELECT
	[years],
	hires,
	termination,
	CAST(ROUND(((hires - termination)/hires) * 100,2) AS VARCHAR(25)) + '%' AS change_count
FROM CTE
ORDER BY [years] ASC;

--11. What is the tenure distribution for each department?

SELECT
	department,
	AVG(DATEDIFF(DAY,hire_date,term_date)/365) AS avg_tenure
FROM 
	hr
where term_date IS NOT NULL AND term_date <= GETDATE()
GROUP BY department;
