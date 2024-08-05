-- EDA
SELECT * FROM layoffs_staging2;

-- 1] ANALYSIS ON LAY OFFS
SELECT * FROM layoffs_staging2 
WHERE percentage_laid_off = 1
ORDER BY funds_raised_millions DESC;

SELECT MAX(total_laid_off), MAX(percentage_laid_off)
FROM layoffs_staging2;

SELECT MIN(`date`), MAX(`date`)
FROM layoffs_staging;

-- 1.1] MAX LAID OFFS BY A COMPANY
SELECT 
	company, sum(total_laid_off) as cmp_laid_off
FROM layoffs_staging2
GROUP BY company
ORDER BY 2 desc;

-- 1.2] LAID OFFS BY INDUSTRY
SELECT 
	industry, sum(total_laid_off) as ind_laid_off
FROM layoffs_staging2
GROUP BY 1
ORDER BY 2 DESC;

-- 1.3] LAY OFF BY COUNTRY
SELECT 
	country, sum(total_laid_off) as cnt_laid_off
FROM layoffs_staging2
GROUP BY 1
ORDER BY 2 DESC;

-- 1.4] LAY OFF BY YEAR
SELECT 
	YEAR(`date`), sum(total_laid_off) as yr_laid_off
FROM layoffs_staging2
GROUP BY 1
ORDER BY 1 DESC;

-- 1.5] LAY OFF BY MONTH
SELECT substring(`date`,1,7) `MONTH`, SUM(total_laid_off) as mth_laid_off
FROM layoffs_staging2
WHERE substring(`date`,1,7) IS NOT NULL
GROUP BY 1
ORDER BY 2 DESC;

-- 1.6] CUMULATIVE SUM OF LAY OFF BY DATE
WITH rolling_total as (
	SELECT substring(`date`,1,7) `MONTH`, SUM(total_laid_off) as mth_laid_off
	FROM layoffs_staging2
	WHERE substring(`date`,1,7) IS NOT NULL
	GROUP BY 1
	ORDER BY 1 ASC
)

SELECT `MONTH`, mth_laid_off,
SUM(mth_laid_off) OVER (ORDER BY `MONTH`) AS rolling_tot
FROM rolling_total;

-- 1.7] LAY OFFS BY YEAR BREAKDOWN
SELECT company, YEAR(`date`) AS year, SUM(total_laid_off) as laid_off
FROM layoffs_staging2
GROUP BY company, year
ORDER BY 3 DESC;

-- 1.8] RANKING THE COMPANY BY HUGE LAYOFFS ACROSS DIFFERENT YEARS
WITH company_year (company, years, total_laid_off) AS
(
	SELECT company, YEAR(`date`), 
    SUM(total_laid_off)
	FROM layoffs_staging2
	GROUP BY company, YEAR(`date`)
),
company_year_rnk AS
(
	SELECT * , 
	DENSE_RANK() OVER(PARTITION BY years
	ORDER BY total_laid_off DESC) as rnk
	FROM company_year
	WHERE years IS NOT NULL 
)
SELECT * FROM company_year_rnk
WHERE rnk <= 5;







