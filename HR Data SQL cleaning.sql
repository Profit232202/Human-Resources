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