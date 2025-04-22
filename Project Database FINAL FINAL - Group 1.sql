USE master
DROP DATABASE IF EXISTS Covid19Data
CREATE DATABASE Covid19Data;
USE Covid19Data
GO

--STEP 1: LOADING CSV DATA
--Variant table: Check constraints done by Lily
DROP TABLE IF EXISTS Variant
CREATE TABLE Variant (
    VariantID INT IDENTITY(1,1) PRIMARY KEY,
	Country VARCHAR(100) NOT NULL,
    first_detection DATETIME NOT NULL CHECK (first_detection BETWEEN 2020-01-01 AND 2021-12-31),
	last_detection DATETIME NOT NULL CHECK(last_detection BETWEEN 2020-01-01 AND 2021-12-31),
	VariantName VARCHAR(100) NOT NULL,
	TotalCases FLOAT CHECK (TotalCases BETWEEN 0 AND 35979785),
	DeathToll FLOAT CHECK (DeathToll BETWEEN 0 AND 520000)
);

BULK INSERT Variant
FROM 'C:\Users\alpin\Documents\CSV INFO 330\surv_variants.csv'
WITH (
		--FORMAT = 'csv',
		FIELDTERMINATOR = ',',
		FIRSTROW = 2,
		ROWTERMINATOR = '\n',
		BATCHSIZE = 250000,
		MAXERRORS = 5);

SELECT * FROM Variant
--vaccination record (Country-Vaccine) table
DROP TABLE IF EXISTS VaccinationRecord
CREATE TABLE VaccinationRecord (
    VaccinationRecordID INT IDENTITY(1,1) PRIMARY KEY,
	CountryName VARCHAR(500),
    RecordDate DATETIME,
	VaccineName VARCHAR(200),
    DosesAdministered INT
);

--Country table
DROP TABLE IF EXISTS Country
CREATE TABLE Country(
    CountryID INT IDENTITY(1,1) PRIMARY KEY,
	CountryName VARCHAR (500))

INSERT INTO Country
SELECT DISTINCT Country
FROM Variant
UNION
SELECT DISTINCT CountryName
FROM VaccinationRecord

SELECT * FROM Country

DROP TABLE IF EXISTS Vaccine
CREATE TABLE Vaccine (
    VaccineID INT IDENTITY(1,1) PRIMARY KEY,
    VaccineName VARCHAR(100) NOT NULL UNIQUE,
    SideEffects TEXT,
	Manufacturer VARCHAR(100) NOT NULL
);

BULK INSERT Vaccine
FROM 'C:\Users\alpin\Documents\CSV INFO 330\vaccines-MOCK.csv'
WITH (
		--FORMAT = 'csv',
		FIELDTERMINATOR = ',',
		FIRSTROW = 2,
		ROWTERMINATOR = '\n',
		BATCHSIZE = 250000,
		MAXERRORS = 5);

SELECT * FROM Vaccine

--Patient data table: Check constraints done by Minu
DROP TABLE IF EXISTS PatientCase
CREATE TABLE PatientCase (
    CaseID INT IDENTITY(1,1) PRIMARY KEY,
	CDC_Report_Date DATETIME CHECK (CDC_Report_Date BETWEEN 2020-01-01 AND 2021-12-31),
	PositiveTestDate DATETIME CHECK (PositiveTestDate BETWEEN 2020-01-01 AND 2021-12-31),
	OnsetDate DATETIME CHECK (OnsetDate BETWEEN 2020-01-01 AND 2021-12-31),
	CurrentStatus VARCHAR(300) NOT NULL,
	Gender VARCHAR(10) NOT NULL,
	Age_Group VARCHAR(100) NOT NULL,
	Race VARCHAR(150) NOT NULL,
	Ethnicity VARCHAR(150) NOT NULL,
	Hospitalized VARCHAR(50) NOT NULL,
	ICU VARCHAR(50) NOT NULL,
	Death VARCHAR(50) NOT NULL,
	Comorbidity VARCHAR(500) NOT NULL)

BULK INSERT PatientCase
FROM 'C:\Users\alpin\Documents\CSV INFO 330\patient-cases.csv'
WITH (
		--FORMAT = 'csv',
		FIELDTERMINATOR = ',',
		FIRSTROW = 2,
		ROWTERMINATOR = '\n',
		BATCHSIZE = 250000,
		MAXERRORS = 5);

SELECT * FROM PatientCase

--Alt Patient Case table using mock data
DROP TABLE IF EXISTS PatientCase2
CREATE TABLE PatientCase2 (
    CaseID INT IDENTITY(1,1) PRIMARY KEY,
	CDC_Report_Date DATETIME,
	Gender VARCHAR(10),
	Age VARCHAR(100),
	Race VARCHAR(150),
	Hospitalized VARCHAR(50),
	ICU VARCHAR(50),
	Death VARCHAR(50),
	Comorbidity VARCHAR(500),
	Variant VARCHAR(500))

BULK INSERT PatientCase2
FROM 'C:\Users\alpin\Documents\CSV INFO 330\mockpatientdata.csv'
WITH (
		--FORMAT = 'csv',
		FIELDTERMINATOR = ',',
		FIRSTROW = 2,
		ROWTERMINATOR = '\n',
		BATCHSIZE = 250000,
		MAXERRORS = 5);

SELECT * FROM PatientCase2

DROP TABLE IF EXISTS VaccinationRecord
CREATE TABLE VaccinationRecord (
    VaccinationRecordID INT IDENTITY(1,1) PRIMARY KEY,
	CountryName VARCHAR(400),
	RecordDate DATETIME,
	VaccineName VARCHAR(500),
	DosesAdministered INT)

BULK INSERT VaccinationRecord
FROM 'C:\Users\alpin\Documents\CSV INFO 330\country_vaccinations_by_manufacturer.csv'
WITH (
		--FORMAT = 'csv',
		FIELDTERMINATOR = ',',
		FIRSTROW = 2,
		ROWTERMINATOR = '\n',
		BATCHSIZE = 250000,
		MAXERRORS = 5);


ALTER TABLE VaccinationRecord
ADD CountryID INT,
    VaccineID INT;

ALTER TABLE VaccinationRecord
ADD CONSTRAINT FK_VaccinationRecord_Country FOREIGN KEY (CountryID) REFERENCES Country(CountryID),
    CONSTRAINT FK_VaccinationRecord_Vaccine FOREIGN KEY (VaccineID) REFERENCES Vaccine(VaccineID);


UPDATE VaccinationRecord
SET CountryID = c.CountryID,
    VaccineID = v.VaccineID
FROM VaccinationRecord AS vr
LEFT JOIN Country c ON c.CountryName = vr.CountryName
LEFT JOIN Vaccine v ON v.VaccineName = vr.VaccineName;

SELECT * FROM VaccinationRecord

--Country-variant table
DROP TABLE IF EXISTS CountryVariant
CREATE TABLE CountryVariant(
	CountryVariantID INT IDENTITY(1,1) PRIMARY KEY,
	CountryID INT,
	VariantID INT)

INSERT INTO CountryVariant
SELECT VariantID, CountryID
	FROM Variant AS v
	JOIN Country AS c ON v.Country = c.CountryName



SELECT * FROM CountryVariant;



--Indexing
CREATE INDEX idx_CountryName ON Country(CountryName);
CREATE INDEX idx_VaccineName ON Vaccine(VaccineName);
CREATE INDEX idx_VariantName ON Variant(VariantName);
CREATE INDEX idx_PatientCaseDate ON PatientCase(OnsetDate);
GO

--View for aggregated COVID-19 stats per country

CREATE VIEW VirulenceStats AS
	SELECT 
		v.Country,
		COUNT(VariantName) AS TotalVariants,
		SUM(TotalCases) AS TotalInfected,
		AVG(DeathToll/TotalCases) AS AvgMortalityRate
	FROM Variant AS v
	GROUP BY Country;
	GO

-- View for tracking vaccination progress
CREATE VIEW VaccinationProgress AS
SELECT 
    c.CountryName, v.VaccineName, vr.RecordDate, vr.DosesAdministered
FROM VaccinationRecord vr
JOIN Country c ON vr.CountryID = c.CountryID
JOIN Vaccine v ON vr.VaccineID = v.VaccineID;
GO

-- Default constraint for CurrentStatus: Lily
ALTER TABLE PatientCase ADD CONSTRAINT df_CurrentStatus DEFAULT 'Under Treatment' FOR CurrentStatus;

--Default constraint: Minu
ALTER TABLE Vaccine ADD CONSTRAINT df_VaccineName DEFAULT 'Other provider' FOR VaccineName;

--Default constraint: Manuel

-- Check if the column MortalityRate
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS 
               WHERE TABLE_NAME = 'Variant' AND COLUMN_NAME = 'MortalityRate')
BEGIN
    ALTER TABLE Variant
    ADD MortalityRate AS 
        (CASE 
            WHEN TotalCases > 0 THEN (DeathToll / TotalCases) * 100
            ELSE 0 
        END);
END

-- Check if the column ActiveCases exists
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS 
               WHERE TABLE_NAME = 'Variant' AND COLUMN_NAME = 'ActiveCases')
BEGIN
    ALTER TABLE Variant
    ADD ActiveCases AS (TotalCases - DeathToll);
END

SELECT * FROM Variant;
SELECT * FROM VaccinationRecord;
SELECT * FROM CountryVariant;
SELECT * FROM PatientCase;
SELECT * FROM PatientCase2;
SELECT * FROM Country;
SELECT * FROM Vaccine