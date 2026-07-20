-- ============================================================
-- LAYOFFS PROJECT: DATA CLEANING + EXPLORATORY DATA ANALYSIS
-- ============================================================

-- Goals for this project
-- 1. Remove duplicates
-- 2. Evaluate null and blank values
-- 3. Standardise the data
-- 4. Remove columns/rows when necessary

-- Preview the raw data
Select *
From layoffs;

-- Create a staging table so we never touch the raw data directly
CREATE TABLE layoffs_staging
like layoffs;

Select *
From layoffs_staging;

insert layoffs_staging
Select *
From layoffs;

Select *
From layoffs_staging;

-- ------------------------------------------------------------
-- 1. REMOVE DUPLICATES
-- ------------------------------------------------------------

-- Which rows are exact duplicates (same values across every column)?
with duplicate_cte as
(
select *,
ROW_NUMBER() OVER(
Partition by company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) as row_num
From layoffs_staging
)
select *
from duplicate_cte
where row_num > 1;

CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Sanity check: table should be empty at this point, so no duplicates yet
Select *
From layoffs_staging2
WHERE row_num > 1;

INSERT INTO layoffs_staging2
SELECT *,
ROW_NUMBER() OVER(
Partition by company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) as row_num
From layoffs_staging;

-- Remove the actual duplicate rows, keeping only the first occurrence of each
delete
From layoffs_staging2
WHERE row_num > 1;

-- ------------------------------------------------------------
-- 2. EVALUATE NULL AND BLANK VALUES
-- ------------------------------------------------------------

-- Which rows have no layoff numbers at all (useless for analysis)?
select *
from layoffs_staging2
where total_laid_off is NULL
and percentage_laid_off is NULL;

-- Remove rows with no layoff data whatsoever
delete
from layoffs_staging2
where total_laid_off is NULL
and percentage_laid_off is NULL;

-- Which rows are missing an industry value (NULL or blank)?
select *
from layoffs_staging2
where industry is NULL
OR industry = '';

-- Does this company (Airbnb) have any other rows with industry filled in?
select *
from layoffs_staging2
where company = 'Airbnb';

-- Can we backfill a missing industry using another row from the same company/location?
select *
from layoffs_staging2 t1
join layoffs_staging2 t2
	on t1.company = t2.company
    and t1.location = t2.location
where (t1.industry is NULL or t1.industry = '')
and t2.industry is not null;

-- Convert blank industry strings into true NULLs first
update layoffs_staging2
set industry = null
where industry = '';

-- Backfill NULL industry values using another row for the same company
update layoffs_staging2 t1
join layoffs_staging2 t2
	on t1.company = t2.company
set t1.industry = t2.industry
where (t1.industry is NULL or t1.industry = '')
and t2.industry is not null;

select *
from layoffs_staging2;

-- Drop the helper column now that duplicates have been removed
alter table layoffs_staging2
drop column row_num;

-- ------------------------------------------------------------
-- 3. STANDARDISE THE DATA
-- ------------------------------------------------------------

-- Do any company names have leading/trailing whitespace?
select company, trim(company)
From layoffs_staging2;

-- Remove whitespace from company names
update layoffs_staging2
set company = trim(company);

-- Are there inconsistent "Crypto" industry labels (e.g. "Crypto Currency")?
Select *
From layoffs_staging2
WHERE industry like 'Crypto%';

-- Standardise all crypto-related industry values to "Crypto"
Update layoffs_staging2
set industry = 'Crypto'
where industry like 'Crypto%';

-- Are there inconsistent country names (e.g. "United States" vs "United States.")?
select distinct country, Trim(trailing '.' from country)
from layoffs_staging2
order by 1;

-- Preview converting the date column from text to a real DATE
select `date`,
STR_TO_DATE(`date`, '%m/%d/%Y')
from layoffs_staging2;

-- Fix the trailing period on "United States."
Update layoffs_staging2
set country = Trim(trailing '.' from country)
where country like 'United States%';

-- Convert the date text values into real dates
Update layoffs_staging2
set `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

-- Change the date column's data type from text to DATE
ALTER TABLE layoffs_staging2
modify column `date` DATE;

-- Confirm the date column converted correctly
select `date`
from layoffs_staging2;

-- ============================================================
-- EXPLORATORY DATA ANALYSIS
-- ============================================================

-- What is the single largest layoff event, and the highest percentage of staff laid off?
select max(total_laid_off), max(percentage_laid_off)
from layoffs_staging2;

-- Which companies laid off 100% of staff (went out of business), ranked by funding raised?
select *
from layoffs_staging2
where percentage_laid_off = 1
order by funds_raised_millions desc;

-- Which companies had the most total layoffs overall?
select company, sum(total_laid_off)
from layoffs_staging2
group by company
order by 2 desc;

-- What date range does this dataset cover?
select min(`date`), max(`date`)
from layoffs_staging2;

-- Which industries were hit hardest by layoffs overall?
select industry, sum(total_laid_off)
from layoffs_staging2
group by industry
order by 2 desc;

-- Which countries had the most layoffs overall?
select country, sum(total_laid_off)
from layoffs_staging2
group by country
order by 2 desc;

-- How many layoffs happened in each year?
select year(`date`), sum(total_laid_off)
from layoffs_staging2
group by year(`date`)
order by 1 desc;

-- Which funding stage (Series A, Post-IPO, etc.) had the most total layoffs?
select stage, sum(total_laid_off)
from layoffs_staging2
group by stage
order by 1 desc;

-- How did total layoffs trend month by month?
select substring(`date`, 1 ,7) as `Month`, sum(total_laid_off)
from layoffs_staging2
where substring(`date`, 1 ,7) is not null
group by `Month`
order by 1 asc;

-- What is the cumulative (running) total of layoffs over time?
with Rolling_total as
(
select substring(`date`, 1 ,7) as `Month`, sum(total_laid_off) as total_layoff
from layoffs_staging2
where substring(`date`, 1 ,7) is not null
group by `Month`
order by 1 asc
)
select `Month`,
total_layoff,
sum(total_layoff) over(order by `Month`) as rolling_total
from Rolling_total;

-- Which were the top 5 companies with the most layoffs, in each year?
with company_year (company, industry, country, year, total_layoff) as
(
select company, industry, country, year(`date`), sum(total_laid_off)
from layoffs_staging2
group by company, industry, country, year(`date`)
),
company_year_rank as
(
select *, dense_rank() over (partition by year order by total_layoff desc) as layoff_ranking
from company_year
where year is not null
)
select *
from company_year_rank
where layoff_ranking <= 5
;

-- Which companies raised the most funding in each year, and how many people did they lay off?
with company_year as (
  select company, year(`date`) as yr,
         sum(total_laid_off) as total_laid_off,
         sum(funds_raised_millions) as total_funds
  from layoffs_staging2
  group by company, year(`date`)
)
select *,
       dense_rank() over (partition by yr order by total_funds desc) as funding_rank
from company_year
where (total_laid_off is not null or '') and yr is not null
order by yr, funding_rank
limit 50;

-- Which companies had 100% of staff laid off, despite raising over $100M in funding?
select company, percentage_laid_off, funds_raised_millions
from layoffs_staging2
where percentage_laid_off = 1
and funds_raised_millions > 100
order by funds_raised_millions desc;

-- What is the average number of people laid off per company, broken down by funding stage?
select stage, avg(total_laid_off)
from layoffs_staging2
where stage is not null
group by stage
order by 2 desc;

-- Which industry had the worst layoffs in each specific year?
with industry_year as (
  select industry, year(`date`) as yr,
         sum(total_laid_off) as total_laid_off,
         sum(funds_raised_millions) as total_funds
  from layoffs_staging2
  group by industry, year(`date`)
),
industry_rank as (
  select *,
         dense_rank() over (partition by yr order by total_laid_off desc) as industry_rank_layoffs
  from industry_year
  where total_laid_off is not null and yr is not null
)
select *
from industry_rank
where industry_rank_layoffs <= 5
order by yr, industry_rank_layoffs;