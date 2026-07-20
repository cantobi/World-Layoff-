# World-Layoff

Code Red: Analysing Global Layoffs with SQL

Description

This project utilizes SQL for both extensive data cleaning and targeted exploratory data analysis (EDA) of global company workforce reductions between 2020 and 2023. The script transforms a raw, messy dataset into an analytical powerhouse by methodically removing duplicates, backfilling null values, and standardising text formatting. The final section utilizes advanced analytical queries to uncover critical patterns regarding industry impact, temporal acceleration trends, and funding milestones versus corporate survival rates.  


Tech Stack & SQL Architecture

Common Table Expressions (CTEs): Used to isolate duplicates and isolate partitioned records without affecting performance.  

Window Functions: Implemented ROW_NUMBER() for deduplication and DENSE_RANK() to dynamically extract top-ranked records across calendar years.  

String Manipulation: Applied TRIM() and SUBSTRING() to uniform text formatting and standardize timeline horizons.  

Data Type Conversions: Handled type casting using STR_TO_DATE() and ALTER TABLE commands to transition raw strings into structured time series data.  

Self-Joins: Configured table self-joins to cross-reference and backfill missing categorical information based on existing company profiles.  


Project Goals

Remove Duplicates: Establish a secure staging table and eliminate exact duplicate records to secure the accuracy of downstream aggregate metrics.  

Evaluate Null and Blank Values: Clear out records lacking primary metrics entirely and backfill missing data points contextually using identical client indices.  

Standardise the Data: Unify disparate categorical data fields and correct spacing or symbol variations across global regions. 

Data Compression: Remove transient check columns used during processing to return a clean database schema.  


Business Insights Discovered

What is the cumulative (running) total of layoffs over time?

Between March 11, 2020 and March 6, 2023, the tech sector saw a total of 383,659 employees laid off globally. The most intense acceleration occurred in January 2023, marking a record peak of 84,714 layoffs in a single month.  

Which companies laid off 100% of their staff, despite raising over $100M in funding?

High capital investment was no shield against market shifts. Companies like Britishvolt ($2.4B), Quibi ($1.8B), Deliveroo Australia ($1.7B), Katerra ($1.6B), and BlockFi ($1B) collapsed completely, releasing 100% of their personnel despite massive funding reserves.  

Which were the top 5 companies with the most layoffs in each specific year?Major players dominated the yearly layoff metric charts:  

2020: Uber (7,525), Booking.com (4,375), Groupon (2,800), Swiggy (2,250), Airbnb (1,900).  

2021: Bytedance (3,600), Katerra (2,434), Zillow (2,000), Instacart (1,877), WhiteHat Jr (1,800).  

2022: Meta (11,000), Amazon (10,150), Cisco (4,100), Peloton (4,084), Carvana / Philips (4,000).  

2023: Google (12,000), Microsoft (10,000), Ericsson (8,500), Amazon / Salesforce (8,000), Dell (6,650).  

Which funding stage had the most total layoffs, and what was the average?
Publicly traded corporations bore the brunt of market corrections. Post-IPO firms accounted for the vast majority of reductions with 204,132 total layoffs. They also held the highest reduction severity, averaging 663 employees per layoff instance.  

Which industries were hit hardest overall, and how did it change year-over-year?
Overall, Consumer (45,182 total layoffs) and Retail (43,613 total layoffs) were hit hardest. Over time, market stresses shifted fields completely:  

2020: Transportation led the downturn with 14,656 layoffs as global travel froze.  

2021: Consumer services faced the highest exposure (3,600).  

2022: Retail topped the tables with 20,914 layoffs due to changing buying behaviors.  

2023: General business sectors categorized under Other (28,512) and Consumer tech (15,663) experienced the sharpest adjustments.
