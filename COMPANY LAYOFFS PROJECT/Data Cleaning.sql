-- DATA CLEANING
SELECT * 
FROM world_layoffs.layoffs;

-- CREATING A COPY OF THE LAYOFF TABLE
CREATE TABLE world_layoffs.layoffs_staging
LIKE world_layoffs.layoffs;

-- INSERTING VALUES INTO LAYOFFS_STAGING
INSERT world_layoffs.layoffs_staging 
SELECT * FROM
world_layoffs.layoffs;

SELECT * FROM world_layoffs.layoffs_staging;

-- 2.1] IDENTIFYING DUPLICATES
WITH duplicate_cte as (
	SELECT  *,
    ROW_NUMBER() OVER(PARTITION BY company, location, industry,
    total_laid_off, percentage_laid_off, `date`, stage, 
    country, funds_raised_millions) AS row_num
    FROM world_layoffs.layoffs_staging
)
SELECT * FROM duplicate_cte
WHERE row_num > 1;

SELECT * FROM world_layoffs.layoffs_staging
WHERE company = "Casper";
 
 -- 2.2] REMOVING DUPLICATES
 -- CREATING A NEW TABLE AND REMOVING THE DUPLICATES IN THE CREATED TABLE
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
  `row_num` int
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

SELECT * FROM layoffs_staging2;

INSERT INTO layoffs_staging2
	SELECT  *,
    ROW_NUMBER() OVER(PARTITION BY company, location, industry,
    total_laid_off, percentage_laid_off, `date`, stage, 
    country, funds_raised_millions) AS row_num
    FROM layoffs_staging;

-- 2.3] DELETED DUPLICATES
DELETE FROM layoffs_staging2
WHERE row_num > 1;

SELECT* FROM layoffs_staging2;

-- 3] STANDARDIZING DATA
-- 3.1] REMOVING UNNECESSARY SPACES
SELECT company, TRIM(company)
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET company = TRIM(company);

-- 3.2] REMOVING DUPLICATE INDUSTRY
SELECT DISTINCT industry 
FROM layoffs_staging2
ORDER BY 1;

SELECT * FROM layoffs_staging2
WHERE industry LIKE 'Crypto%';

UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

-- 3.3] REPEATED COUNTRY NAMES
SELECT DISTINCT country
FROM layoffs_staging2
ORDER BY 1;

SELECT DISTINCT country, TRIM(TRAILING '.' FROM country )
FROM layoffs_staging2
ORDER BY 1; 

UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

-- 3.4] CONVERTING DATA TYPE OF DATE
SELECT `date`, str_to_date(`date`,'%m/%d/%Y')
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET `date` = str_to_date(`date`,'%m/%d/%Y');

ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;

-- 4] DEALING WITH NULL VALUES
-- 4.1] IMPUTING THE INDUSTRY NAME
SELECT * FROM layoffs_staging2
WHERE industry IS NULL ;

SELECT  t1.industry, t2.industry
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company 
WHERE (t1.industry IS NULL OR t1.industry = '')
AND t2.industry IS NOT NULL;

-- THIS IS DONE BECAUSE DATA HAD BLANK VALUES
-- AND IT WAS NOT POSSIBLE TO IMPUTE VALUES
UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = '';

UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1.company = t2.company 
SET t1.industry = t2.industry 
WHERE t1.industry IS NULL 
AND t2.industry IS NOT NULL;

-- 4.2] NULL VALUES IN TOTAL LAID OFF AND PERCENTAGE LAID OFF
SELECT * FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

DELETE FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

SELECT * FROM layoffs_staging2;

ALTER TABLE layoffs_staging2
DROP COLUMN row_num;