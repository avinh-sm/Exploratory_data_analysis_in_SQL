/*Start exploring a database by identifying the tables and the foreign keys that link them. Look for missing values, count the number of observations, and join tables to understand how they're related. Coalesce and cast data along the way.

/*COUNTING MISSING VALUES*/

-- Select the count of the number of rows
SELECT COUNT(*)
  FROM fortune500;

-- Select the count of ticker, sector, industry, employees, revenues, revenues_change, profits, profits_change, assets, equity

SELECT 
    COUNT(*) - COUNT(ticker) AS missing_ticker,
    COUNT(*) - COUNT(sector) AS missing_sector,
    COUNT(*) - COUNT(industry) AS missing_industry,
    COUNT(*) - COUNT(employees) AS missing_employees,
    COUNT(*) - COUNT(revenues) AS missing_revenues,
    COUNT(*) - COUNT(revenues_change) AS missing_revenues_change,
    COUNT(*) - COUNT(profits) AS missing_profits,
    COUNT(*) - COUNT(profits_change) AS missing_profits_change,
    COUNT(*) - COUNT(assets) AS missing_assets,
    COUNT(*) - COUNT(equity) AS missing_equity
FROM fortune500

/*JOIN TABLES*/

-- Part of exploring a database is figuring out how tables relate to each other. The company and fortune500 tables don't have a formal relationship between them in the database, but there is a relantionship between them: 

SELECT company.name
-- Table(s) to select from
  FROM company
       INNER JOIN fortune500
       ON company.ticker=fortune500.ticker;

--The information we need is sometimes split across multiple tables in the database. For example, what is the most common stackoverflow tag_type? What companies have a tag of that type?

-- Count the number of tags with each type
SELECT type, COUNT(type) AS count
  FROM tag_type
 -- To get the count for each type
 GROUP BY type
 -- Order the results with the most common tag types listed first
 ORDER BY count DESC;

 --We can see that the most common type is cloud with 31, followed by database with 6. The least common type is identity.

 -- Select the 3 columns desired
SELECT company.name, tag_type.tag, tag_type.type
  FROM company
  	   -- Join to the tag_company table
       INNER JOIN tag_company 
       ON company.id = tag_company.company_id
       -- Join to the tag_type table
       INNER JOIN tag_type
       ON tag_company.tag = tag_type.tag
  -- Filter to most common type
  WHERE type='cloud';

  --We can see that the companies with a tag of that type (cloud) are Amazon Web Services, Microsoft Corp. and Dropbox. 

/*SPECIFYING A DEFAULT OR BACKUP VALUE*/
-- Using coalesce to select the first non-NULL value from industry, sector, or 'Unknown' as a fallback value.
SELECT COALESCE(industry, sector, 'Unknown') AS industry2,
       COUNT(*)
  FROM fortune500
-- Group by what we are counting by
 GROUP BY industry2
-- Order results to see most common first
 ORDER BY count DESC
-- Limit results to get just the one value
 LIMIT 1;

 --Now, we will include companies from 'company' that are subsidiaries of Fortune 500 companies. To include subsidiaries, we will need to join 'company' to itself to associate a subsidiary with its parent company's information.

 SELECT company_original.name, title, rank
  -- Start with original company information
  FROM company AS company_original
       -- Join to another copy of company with parent company information
	   LEFT JOIN company AS company_parent
       ON company_original.parent_id = company_parent.id 
       -- Join to fortune500, only keep rows that match
       INNER JOIN fortune500 
       -- Use parent ticker if there is one, otherwise original ticker
       ON coalesce(company_parent.ticker, company_original.ticker) = fortune500.ticker
 -- For clarity, order by rank
 ORDER BY rank; 

 /*SUMMARIZE THE DISTRIBUTION OF NUMERIC VALUES*/
 --Was 2017 a good or bad year for revenue of Fortune 500 companies? We examine how revenue changed from 2016 to 2017 by first looking at the distribution of revenues_change and then counting companies whose revenue increased.

 -- Select the count of each revenues_change integer value (we cast to reduce the number of different values and facilitate the analysis).
SELECT revenues_change::integer, count(*)
  FROM fortune500
 GROUP BY revenues_change::integer
 -- order by the values of revenues_change
 ORDER BY revenues_change;

 -- How many of the Fortune 500 companies had revenues increase in 2017 compared to 2016?
 -- Count rows 
SELECT count(*)
  FROM fortune500
 -- Where...
 WHERE revenues_change > 0;
--298 companies had revenues increase in 2017 compared to 2016.

 /*AVERAGE REVENUE PER EMPLOYEE*/
 -- Select average revenue per employee by sector
SELECT sector, 
       AVG(revenues/employees::numeric) AS avg_rev_employee
  FROM fortune500
 GROUP BY sector
 -- Use the column alias to order the results
 ORDER BY avg_rev_employee;
 --Hotels, Restaurants & Leisure was the sector with min avg_rev_employee and  Materials with the max.

 /* SUMMARIZE NUMERIC COLUMNS */
 -- Select min, avg, max, and stddev of fortune500 profits
SELECT MIN(profits),
       AVG(profits),
       MAX(profits),
       STDDEV(profits)
  FROM fortune500;

  -- Select sector and summary measures of fortune500 profits
SELECT sector,
       MIN(profits),
       AVG(profits),
       MAX(profits),
       STDDEV(profits)
  FROM fortune500
 GROUP BY sector
 ORDER BY AVG;

 /* SUMMARIZE GROUP STATISTICS */
 --What is the standard deviation across tags in the maximum number of Stack Overflow questions per day? What about the mean, min, and max of the maximums as well?
 -- Compute standard deviation of maximum values
SELECT stddev(maxval),
	   -- min
       min(maxval),
       -- max
       max(maxval),
       -- avg
       avg(maxval)
  -- Subquery to compute max of question_count by tag
  FROM (SELECT MAX(question_count) AS maxval
          FROM stackoverflow
         -- Compute max by...
         GROUP BY tag) AS max_results;

--Using trunc() to examine the distributions of attributes of the Fortune 500 companies.
--For explample, to truncate employees to the 100,000s:
-- Truncate employees
SELECT trunc(employees, -5)  AS employee_bin,
       -- Count number of companies with each truncated value
       count(name)
  FROM fortune500
 GROUP BY employee_bin
 ORDER BY employee_bin;
 

 --Now for companies with < 100,000 employees (most common). This time, we truncate employees to the 10,000s place.
 -- Truncate employees
SELECT trunc(employees, -4)  AS employee_bin,
       -- Count number of companies with each truncated value
       Count(name)
  FROM fortune500
 WHERE employees < 100000
 GROUP BY employee_bin
 ORDER BY employee_bin;

--Summarizing the distribution of the number of questions with the tag "dropbox" on Stack Overflow per day by binning the data.
--To know the range of values to cover with the bins:
-- Select the min and max of question_count
SELECT min(question_count), 
       max(question_count)
  FROM stackoverflow
 -- For tag dropbox
 WHERE tag = 'dropbox';

-- Create bins of size 50 from 2200 to 3100.
WITH bins AS (
      SELECT generate_series(2200, 3050, 50) AS lower,
             generate_series(2250, 3100, 50) AS upper),
     -- Subset stackoverflow to just tag dropbox
     dropbox AS (
      SELECT question_count 
        FROM stackoverflow
       WHERE tag='dropbox') 
-- Select columns for result (column we are counting to summarize)
SELECT lower, upper, count(question_count) 
  FROM bins  -- Created above
       -- Join to dropbox (created above), 
       -- keeping all rows from the bins table in the join
       LEFT JOIN dropbox
       -- Compare question_count to lower and upper
         ON question_count >= lower 
        AND question_count < upper
 -- Group by lower and upper to count values in each bin
 GROUP BY lower, upper
 -- Order by lower to put bins in order
 ORDER BY lower;

 /*CORRELATION*/
 --What's the relationship between a company's revenue and its other financial attributes?
 -- Correlation between revenues and profit
SELECT corr(revenues, profits) AS rev_profits,
	   -- Correlation between revenues and assets
       corr(revenues, assets) AS rev_assets,
       -- Correlation between revenues and equity
       corr(revenues, equity) AS rev_equity 
  FROM fortune500;

/*MEAN AND MEDIAN*/
--Computing the mean and median assets of Fortune 500 companies by sector.
SELECT sector,
       -- Select the mean of assets 
       avg(assets) AS mean,
       -- Select the median
       percentile_disc(0.5) WITHIN GROUP (ORDER BY assets) AS median
  FROM fortune500
 GROUP BY sector
 ORDER BY mean;

 /*CREATING A TEMP TABLE*/
 --Find the Fortune 500 companies that have profits in the top 20% for their sector (compared to other Fortune 500 companies). To do this, first, we find the 80th percentile of profit for each sector:
 
-- To clear table if it already exists; fill in name of temp table
DROP TABLE IF EXISTS profit80;

CREATE TEMP TABLE profit80 AS
  SELECT sector, 
         percentile_disc(0.8) WITHIN GROUP (ORDER BY profits) AS pct80
    FROM fortune500 
   GROUP BY sector;

SELECT title, fortune500.sector, 
       profits, profits/pct80 AS ratio  
  FROM fortune500 
       LEFT JOIN profit80
       ON fortune500.sector=profit80.sector
 WHERE profits > pct80;

 --Compute the correlations between each pair of profits, profits_change, and revenues_change from the Fortune 500 data.
 DROP TABLE IF EXISTS correlations;

CREATE TEMP TABLE correlations AS
SELECT 'profits'::varchar AS measure,
        -- Select each correlation
       corr(profits, profits) AS profits,
       corr(profits, profits_change) AS profits_change,
       corr(profits, revenues_change) AS revenues_change
  FROM fortune500;

INSERT INTO correlations
SELECT 'profits_change'::varchar AS measure,
        -- Select each correlation
       corr(profits_change, profits) AS profits,
       corr(profits_change, profits_change) AS profits_change,
       corr(profits_change, revenues_change) AS revenues_change
  FROM fortune500;

INSERT INTO correlations
SELECT 'revenues_change'::varchar AS measure,
        -- Select each correlation
       corr(revenues_change, profits) AS profits,
       corr(revenues_change, profits_change) AS profits_change,
       corr(revenues_change, revenues_change) AS revenues_change
  FROM fortune500;

-- Select each column, rounding the correlations
SELECT measure, 
       ROUND(profits::numeric, 2) AS profits,
       ROUND(profits_change::numeric, 2) AS profits_change,
       ROUND(revenues_change::numeric, 2) AS revenues_change
  FROM correlations;

--Now let's work with the Evanston 311 data in table evanston311. This is data on help requests submitted to the city of Evanston, IL.
--This data has several character columns. Let's start by examining the most frequent values in some of these columns to get familiar with the common categories.

--How many rows does each priority level have?
-- Select the count of each level of priority
SELECT priority, Count(*)
FROM evanston311
GROUP BY priority;

-- How many distinct values of zip appear in at least 100 rows?
SELECT zip, count(*)
  FROM evanston311
 GROUP BY zip
HAVING count(*) >= 100; 

--How many distinct values of source appear in at least 100 rows?
SELECT source, count(*)
  FROM evanston311
 GROUP BY source
HAVING count(*) >= 100;

--Five most common values of street and the count of each.
SELECT street, count(*)
  FROM evanston311
 GROUP BY street
 ORDER BY count DESC
 LIMIT 5;

 /*CLEANING TEXT DATA*/
-- Some of the street values in evanston311 include house numbers with # or / in them. In addition, some street values end in a '.'. Let's remove the house numbers, extra punctuation, and any spaces from the beginning and end of the street values as a first attempt at cleaning up the values.
SELECT distinct street,
       -- Trim off unwanted characters from street
       trim(street, '0123456789#/. ') AS cleaned_street
  FROM evanston311
 ORDER BY street;

 --The description column of evanston311 has the details of the inquiry, while the category column groups inquiries into different types. How well does the category capture what's in the description?

--Count rows where the description includes 'trash' or 'garbage' but the category does not.
 SELECT count(*)
  FROM evanston311 
 -- description contains trash or garbage (any case)
 WHERE (description ILIKE '%trash%'
    OR description ILIKE '%garbage%') 
 -- category does not contain Trash or Garbage
   AND category NOT LIKE '%Trash%'
   AND category NOT LIKE '%Garbage%';
--570 descriptions are not capture by the category.

/*SHORTEN LONG STRINGS*/
--The description column of evanston311 can be very long. For displaying or quickly reviewing the data, we might want to only display the first few characters.
-- Select the first 50 chars when length is greater than 50
SELECT CASE WHEN length(description) > 50
            THEN left(description, 50) || '...'
       -- otherwise just select description
       ELSE description
       END
  FROM evanston311
 -- limit to descriptions that start with the word I
 WHERE description LIKE 'I %'
 ORDER BY description;

 /*CREATE OTHER CATEGORY*/
 --If we want to summarize Evanston 311 requests by zip code, it would be useful to group all of the low frequency zip codes together in an "other" category.
 SELECT CASE WHEN zipcount < 100 THEN 'other'
       ELSE zip
       END AS zip_recoded,
       sum(zipcount) AS zipsum
  FROM (SELECT zip, count(*) AS zipcount
          FROM evanston311
         GROUP BY zip) AS fullcounts
 GROUP BY zip_recoded
 ORDER BY zipsum DESC;

 /*GROUP AND RECODE VALUES*/
 --There are almost 150 distinct values of evanston311.category. But some of these categories are similar, with the form "Main Category - Details". We can get a better sense of what requests are common if we aggregate by the main category.
 --To do this, create a temporary table recode mapping distinct category values to new, standardized values. Make the standardized values the part of the category before a dash ('-').
 -- Code from previous step
DROP TABLE IF EXISTS recode;

CREATE TEMP TABLE recode AS
  SELECT DISTINCT category, 
         rtrim(split_part(category, '-', 1)) AS standardized
    FROM evanston311;
  
UPDATE recode SET standardized='Trash Cart' 
 WHERE standardized LIKE 'Trash%Cart';

UPDATE recode SET standardized='Snow Removal' 
 WHERE standardized LIKE 'Snow%Removal%';

-- Update to group unused/inactive values
UPDATE recode 
   SET standardized='UNUSED' 
 WHERE standardized IN ('THIS REQUEST IS INACTIVE...Trash Cart', 
               '(DO NOT USE) Water Bill',
               'DO NOT USE Trash', 
               'NO LONGER IN USE');

-- Examine effect of updates
SELECT DISTINCT standardized 
  FROM recode
 ORDER BY standardized;

 /*COMPLETION TIME BY CATEGORY*/
 --Which category of Evanston 311 requests takes the longest to complete?
-- Select the category and the average completion time by category
SELECT category, 
       AVG(date_completed - date_created) AS completion_time
  FROM evanston311
 GROUP BY category
 ORDER BY completion_time DESC;
--Rodents- Rats takes the longest to complete.

--How many requests are created in each of the 12 months during 2016-2017?
-- Extract the month from date_created and count requests
SELECT date_part('month', date_created) AS month, 
       count(*)
  FROM evanston311
 -- Limit the date range
 WHERE date_part('year', date_created) >=2016
   AND date_part('year', date_created) <=2017
 GROUP BY month;

 --What is the most common hour of the day for requests to be created?
-- Get the hour and count requests
SELECT date_part('hour', date_created) AS hour,
       count(*)
  FROM evanston311
 GROUP BY hour
 -- Order results to select most common
 ORDER BY count DESC
 LIMIT 1;

 --During what hours are requests usually completed?
 -- Count requests completed by hour
SELECT date_part('hour', date_completed) AS hour,
       Count(*)
  FROM evanston311
 GROUP BY hour
 ORDER BY hour;

 --Does the time required to complete a request vary by the day of the week on which the request was created?
 -- Select name of the day of the week the request was created 
SELECT to_char(date_created, 'day') AS day, 
       -- Select avg time between request creation and completion
       AVG(date_completed - date_created) AS duration
  FROM evanston311 
 -- Group by the name of the day of the week and integer value of day of week the request was created
 GROUP BY day, EXTRACT(DOW FROM date_created)
 ORDER BY EXTRACT(DOW FROM date_created);

 --Finding the average number of Evanston 311 requests created per day for each month of the data. Ignoring days with no requests when taking the average.
 -- Aggregate daily counts by month
SELECT date_trunc('month', day) AS month,
       AVG(count)
  -- Subquery to compute daily counts
  FROM (SELECT date_trunc('day', date_created) AS day,
               count(*) AS count
          FROM evanston311
         GROUP BY day) AS daily_count
 GROUP BY month
 ORDER BY month;

/*FINFING MISSING DATES*/
--Are there any days in the Evanston 311 data where no requests were created?
 SELECT day
-- Subquery to generate all dates from min to max date_created
  FROM (SELECT generate_series(min(date_created),
                               max(date_created),
                               '1 day'::interval)::date AS day
          FROM evanston311) AS all_dates
-- Select dates (day from above) that are NOT IN the subquery
 WHERE day NOT IN 
       --Subquery to select all date_created values as dates
       (SELECT date_created::date
          FROM evanston311);

/*CUSTUM AGGREGATIOIN PERIODS*/
--Median number of Evanston 311 requests per day in each six month period from 2016-01-01 to 2018-06-30.
-- Generate 6 month bins covering 2016-01-01 to 2018-06-30

-- Generate 6 month bins covering 2016-01-01 to 2018-06-30
WITH bins AS (
            -- Create lower bounds of bins
	 SELECT generate_series('2016-01-01', -- First bin lower value
                            '2018-01-01', -- Last bin lower value
                            '6 months'::interval) AS lower,
            -- Create upper bounds of bins
            generate_series('2016-07-01',
                            '2018-07-01',
                            '6 months'::interval) AS upper),
-- Count number of requests made per day
     daily_counts AS (
     SELECT day, count(date_created) AS count
     -- Use a daily series from 2016-01-01 to 2018-06-30 to include days with no requests
       FROM (SELECT generate_series('2016-01-01', -- series start date
                                    '2018-06-30', -- series end date
                                    '1 day'::interval)::date AS day) AS daily_series
            LEFT JOIN evanston311
            -- match day from above (which is a date) to date_created
            ON day = date_created::date
      GROUP BY day)
-- Select bin bounds 
SELECT lower, 
       upper, 
       -- Compute median of count for each bin
       percentile_disc(0.5) WITHIN GROUP (ORDER BY count) AS median
  -- Join bins and daily_counts
  FROM bins
       LEFT JOIN daily_counts
       -- Where the day is between the bin bounds
       ON day >= lower
          AND day < upper
 -- Group by bin bounds
 GROUP BY lower, upper
 ORDER BY lower;

 /*LONGEST GAP*/
 --What is the longest time between Evanston 311 requests being submitted?
 -- Compute the gaps
WITH request_gaps AS (
        SELECT date_created,
               -- lead or lag
               lag(date_created) OVER (ORDER BY date_created) AS previous,
               -- compute gap as date_created minus lead or lag
               date_created - lag(date_created) OVER (ORDER BY date_created) AS gap
          FROM evanston311)
-- Select the row with the maximum gap
SELECT *
  FROM request_gaps
-- Subquery to select maximum gap from request_gaps
 WHERE gap = (SELECT MAX(gap)
                FROM request_gaps);

--Requests in category "Rodents- Rats" average over 64 days to resolve. Why?

--Do requests made in busy months take longer to complete?
-- Let's compute correlation (corr) between avg_completion time and count from the subquery
SELECT corr(avg_completion, count)
  -- Convert date_created to its month with date_trunc
  FROM (SELECT date_trunc('month', date_created) AS month, 
               -- Compute average completion time in number of seconds           
               AVG(EXTRACT(epoch FROM date_completed - date_created)) AS avg_completion, 
               -- Count requests per month
               count(*) AS count
          FROM evanston311
         -- Limit to rodents
         WHERE category='Rodents- Rats' 
         -- Group by month, created above
         GROUP BY month) 
         -- Required alias for subquery 
         AS monthly_avgs;

-- Now, let's compare the number of requests created per month to the number completed.
-- Compute monthly counts of requests created
WITH created AS (
       SELECT date_trunc('month', date_created) AS month,
              count(*) AS created_count
         FROM evanston311
        WHERE category='Rodents- Rats'
        GROUP BY month),
-- Compute monthly counts of requests completed
      completed AS (
       SELECT date_trunc('month', date_completed) AS month,
              count(*) AS completed_count
         FROM evanston311
        WHERE category='Rodents- Rats'
        GROUP BY month)
-- Join monthly created and completed counts
SELECT created.month,
       created_count, 
       completed_count
  FROM created
       INNER JOIN completed
       ON created.month=completed.month
 ORDER BY created.month;
--There is a slight correlation between completion times and the number of requests per month. But the bigger issue is the disproportionately large number of requests completed in November 2017.