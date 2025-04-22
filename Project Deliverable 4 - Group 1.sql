
USE Covid19Data
GO
/*
Flag refers to a reported value that is of concerning magnitude.

--Query 1 Minu (Variant Risk by Country)
Write a query that returns VariantName, CountryName, and mortality rate (death toll/total cases),
ranked by mortality rate for each variant, for variants with mortality rate greater than the average
mortality rate (flag countries) that were tracked within the year 2020.
*/
WITH twentymortrate AS(
	SELECT AVG(DeathToll/TotalCases) AS avg_mortality_rate
	FROM Variant
	WHERE first_detection BETWEEN '2020-01-01' AND '2020-12-31'
		AND last_detection BETWEEN '2020-01-01' AND '2020-12-31'
	),
mortality_rate_by_country AS(
	SELECT VariantName, Country, (DeathToll/TotalCases) AS mortality_rate
	FROM Variant
	)
SELECT
	ROW_NUMBER() OVER(PARTITION BY VariantName ORDER BY mortality_rate DESC) AS risk,
	VariantName, Country, mortality_rate
FROM mortality_rate_by_country
	CROSS JOIN twentymortrate
WHERE mortality_rate > avg_mortality_rate
GO

/*
-- Query 2 Minu (Age Risk)
Write a query that takes an input age and sorts the age to an age group then
returns percentage of patients who have comorbidities out of the age group and risk of that
age group.
*/

CREATE PROCEDURE GetComorbidityRisk
    @Age INT
AS
BEGIN
WITH age_group AS(
SELECT *,
	CASE
	WHEN Age <= 10 THEN '0-10 Years'
	WHEN Age BETWEEN 11 AND 20 THEN '11-20 Years'
	WHEN Age BETWEEN 21 AND 30 THEN '21-30 Years'
	WHEN Age BETWEEN 31 AND 40 THEN '31-40 Years'
	WHEN Age BETWEEN 41 AND 50 THEN '41-50 Years'
	WHEN Age BETWEEN 51 AND 60 THEN '51-60 Years'
	WHEN Age BETWEEN 61 AND 70 THEN '61-70 Years'
	WHEN Age BETWEEN 71 AND 80 THEN '71-80 Years'
	WHEN Age BETWEEN 81 AND 90 THEN '81-90 Years'
	WHEN Age BETWEEN 91 AND 100 THEN '91-100 Years'
	ELSE 'Unknown'
	END AS Age_Group
FROM PatientCase2
),
perc_comorbids AS(
SELECT
	age_group,
	COUNT(CASE WHEN Comorbidity = 'TRUE' THEN 1 END)*1.0/COUNT(*) AS percent_comorbid
FROM age_group
GROUP BY Age_Group
),
total_comorbids AS(
SELECT
	ROW_NUMBER () OVER(ORDER BY percent_comorbid DESC) AS risk,
	age_group,
	percent_comorbid
FROM perc_comorbids
)
SELECT *
FROM total_comorbids
WHERE
	Age_Group = (
	CASE WHEN @Age <= 10 THEN '0-10 Years'
	WHEN @Age BETWEEN 11 AND 20 THEN '11-20 Years'
	WHEN @Age BETWEEN 21 AND 30 THEN '21-30 Years'
	WHEN @Age BETWEEN 31 AND 40 THEN '31-40 Years'
	WHEN @Age BETWEEN 41 AND 50 THEN '41-50 Years'
	WHEN @Age BETWEEN 51 AND 60 THEN '51-60 Years'
	WHEN @Age BETWEEN 61 AND 70 THEN '61-70 Years'
	WHEN @Age BETWEEN 71 AND 80 THEN '71-80 Years'
	WHEN @Age BETWEEN 81 AND 90 THEN '81-90 Years'
	WHEN @Age BETWEEN 91 AND 100 THEN '91-100 Years'
	ELSE 'Unknown'
	END)
END;
GO
EXEC GetComorbidityRisk @Age = 13
GO

/*
--Query 3 Minu (Adverse Reactions)
For all vaccines that have "dry mouth" as a side effect, return top 5 countries with maximum doses administered
of this vaccine type in the month of March 2021 ordered maximum. Determines the upper bound of the number of people
affected by a vaccine with an adverse side effect by country.
*/
WITH selected_vaccines AS(
	SELECT VaccineName, VaccineID
	FROM Vaccine
	WHERE SideEffects LIKE '%dry mouth%'
),
upper_bound AS(
SELECT CountryName,
		MAX(CASE WHEN (sv.VaccineID IS NOT NULL) THEN DosesAdministered END) AS TotalDoses
FROM VaccinationRecord AS vr
	LEFT JOIN selected_vaccines AS sv ON sv.VaccineID = vr.VaccineID
WHERE RecordDate BETWEEN '2021-03-01' AND '2021-03-31'
GROUP BY CountryName
)
SELECT *
FROM upper_bound
WHERE TotalDoses >= 0
GO

/* Query 4 Minu: (Mortality Rates among the Delta Variants by Gender) */
/*
What is the mortality rate of patients affected by the Delta variant distributed by gender in the patients sampled,
compared to the true population mortality rate? Report variant name, gender, sample mortality rate, and population
mortality rate, and signficant difference. A mortality rate of 1 in the sample represents all patients affected
passing due to the variant. Can be used to conduct a statistical test to evaluate if the sample of patients used
in the input dataset accurately represents the population or if user needs to reframe the data.
*/
WITH population_mortality_by_variant AS(
	SELECT VariantName, AVG(DeathToll/TotalCases) AS population_mortality_rate
	FROM Variant
	GROUP BY VariantName
),
statistic_calc AS(
SELECT 
	Variant,
	Gender,
	SUM(CASE WHEN Death = 'TRUE' THEN 1 ELSE 0 END)*1.0/COUNT(CaseID) AS sample_mortality_rate,
	population_mortality_rate
FROM PatientCase2 AS pc2
	LEFT JOIN population_mortality_by_variant AS pmbv ON pmbv.VariantName = pc2.Variant
WHERE Variant LIKE '%Delta%'
GROUP BY Variant, Gender, population_mortality_rate
)
SELECT *,
	(sample_mortality_rate - population_mortality_rate) AS significant_difference
FROM statistic_calc


--Query 5: Lily
-- Stored Procedure to Get COVID-19 Variant Case Details for a Given Country and Date Range
/*
This stored procedure retrieves details about COVID-19 variant cases in a specified country within a given date range.
Helps governments track the spread of variants and take timely interventions.
*/
CREATE PROCEDURE GetVariantCases (
    @input_country VARCHAR(255),
    @start_date DATE,
    @end_date DATE
)
AS
BEGIN
    SELECT v.VariantName, 
           v.Country, 
           v.first_detection, 
           v.last_detection, 
           v.TotalCases,
           v.DeathToll
    FROM Variant v
    WHERE v.Country = @input_country
          AND v.first_detection BETWEEN @start_date AND @end_date;
END;
EXEC GetVariantCases @input_country = 'Sweden', @start_date = '2020-03-01', @end_date = '2020-03-31'
GO


/* Query 6 Lily: Retrieving Top 10 Countries by Active COVID-19 Cases */
/*
This query retrieves the top 10 countries with the highest number of active COVID-19 cases.
Identifies countries under the most significant COVID-19 stress, allowing focused efforts to contain the spread.
*/
SELECT 
    TOP 10 c.CountryName,
    SUM(TotalCases) AS TotalCases
FROM 
    Variant v
JOIN 
    Country c ON v.Country = c.CountryName
GROUP BY 
    c.CountryName
ORDER BY 
    TotalCases DESC;
GO


/* Query 7 - Summarizing COVID-19 Variants Per Country (Manuel)*/ 
/*
	This query is a summary of COVID-19 variants per country and the total number of variants, total cases,
	total deaths, and average mortality rate. The results of this query help identify countries with more 
	variants and infection rates, allowing for isolating targets and resource allocation.
*/
SELECT 
    CountryName,
    COUNT(DISTINCT VariantID) AS TotalVariants,
    SUM(TotalCases) AS TotalCases,
    SUM(DeathToll) AS TotalDeaths,
    AVG(CASE WHEN TotalCases > 0 THEN (DeathToll / NULLIF(TotalCases, 0)) * 100 ELSE 0 END) AS AvgMortalityRate
FROM 
    Variant v
JOIN 
    Country c ON v.Country = c.CountryName
GROUP BY 
    CountryName
ORDER BY 
    TotalCases DESC, AvgMortalityRate DESC;
GO

/* Query 8 - Stored Procedure for Vaccination Progress per Country (Manuel)*/ 
/*
	This  procedure gets the vaccination progress for a given country, including total doses
	given and the list of vaccines used. The results of this  procedure allow  authorities to
	monitor vaccinations, identify trends, and plan future vaccination campaigns.
*/

CREATE PROCEDURE GetVaccinationProgress
    @CountryName VARCHAR(500)
AS
BEGIN
    SELECT 
        c.CountryName,
        v.VaccineName,
        vr.RecordDate,
        SUM(vr.DosesAdministered) AS TotalDosesAdministered
    FROM 
        VaccinationRecord vr
    JOIN 
        Country c ON vr.CountryID = c.CountryID
    JOIN 
        Vaccine v ON vr.VaccineID = v.VaccineID
    WHERE 
        c.CountryName = @CountryName
    GROUP BY 
        c.CountryName, v.VaccineName, vr.RecordDate
    ORDER BY 
        vr.RecordDate DESC, TotalDosesAdministered DESC;
END;
EXEC GetVaccinationProgress @CountryName = 'Japan'

/* Query 9 (Bonus) - Retrieving Top 10 Countries by Vaccination Rate (Manuel) */
/* 
   This query retrieves the top 10 countries with the best vaccination rates.
   The results help identify which countries have been the best in their vaccination efforts, showing insights into vaccination numbers.
*/

SELECT 
    TOP 10 c.CountryName,
    SUM(vr.DosesAdministered) AS TotalDosesAdministered,
    (SUM(vr.DosesAdministered) / CAST(1000000 AS FLOAT)) AS VaccinationRate -- I made a small "rate" so it can be used to read the vaccinations easier
FROM 
    VaccinationRecord vr
JOIN 
    Country c ON vr.CountryID = c.CountryID
GROUP BY 
    c.CountryName
ORDER BY 
    VaccinationRate DESC;
GO