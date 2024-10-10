--#region 1.0 Drop Columns not needed
-- Remove the 'Records' column from Content, Reactions, and ReactionTypes tables
-- This step is likely performed to clean up unnecessary data or optimize table structure
ALTER TABLE dbo.Content
DROP COLUMN Records;

ALTER TABLE dbo.Reactions
DROP COLUMN Records;

ALTER TABLE dbo.ReactionTypes
DROP COLUMN Records;
--#endregion

--#region 2.0 Verify Tables
-- Check the first 3 rows of each table to verify their structure and contents after column removal
SELECT TOP 3 *
FROM dbo.Content;

SELECT TOP 3 *
FROM dbo.Reactions;

SELECT TOP 3 *
FROM dbo.ReactionTypes;
--#endregion

--#region 3.0 Join Tables and Insert Data into a New Table Accenture_Data for Data Manipulation
-- Create a new table 'Accenture_Data' by joining Content, Reactions, and ReactionTypes tables
-- This consolidates relevant data from all three tables into a single table for easier analysis
SELECT Content.Content_ID, 
       Content.Category, 
       Content.Type as Content_Type,
       ReactionTypes.Type as Reaction_Type,
       ReactionTypes.Score,
       ReactionTypes.Sentiment,
       Reactions.Datetime
INTO Accenture_Data       
FROM dbo.Content
JOIN dbo.Reactions 
   ON Content.Content_ID = Reactions.Content_ID
JOIN dbo.ReactionTypes 
   ON Reactions.Type = ReactionTypes.Type;
--#endregion

--#region 4.0 Perform Data cleaning, Validation, and Consistency and update into Accenture_Data table
--I performed data manipulation in Microsoft Excel
/*
--4.1 Remove Duplicate Rows:
-- Identify and delete duplicate rows based on Content_ID and Reaction_Type
WITH CTE_Duplicates AS (
   SELECT Content_ID, 
          Category, 
          Content_Type, 
          Reaction_Type, 
          Score, 
          Sentiment, 
          Datetime,
          ROW_NUMBER() OVER (PARTITION BY Content_ID, Reaction_Type ORDER BY Content_ID) AS row_num
   FROM Accenture_Data
)
DELETE FROM CTE_Duplicates
WHERE row_num > 1;

--4.2 Handle Missing Data (NULL values):
-- Remove rows with NULL values in any column
DELETE FROM Accenture_Data
WHERE Content_ID IS NULL
   OR Category IS NULL
   OR Content_Type IS NULL
   OR Reaction_Type IS NULL
   OR Score IS NULL
   OR Sentiment IS NULL
   OR Datetime IS NULL;

--4.3 Validate Data Types and Ensure Valid Ranges:
-- Set negative scores to 0
UPDATE Accenture_Data
SET Score = 0
WHERE Score < 0;

--4.4 Remove rows with invalid sentiment values
DELETE FROM Accenture_Data
WHERE Sentiment NOT IN ('Positive', 'Neutral', 'Negative');

--4.5 Remove rows with future dates
DELETE FROM Accenture_Data
WHERE Datetime > GETDATE();

--4.6 Check for Data Consistency:
-- Remove rows with Content_Type or Reaction_Type not present in original tables
DELETE FROM Accenture_Data
WHERE Content_Type NOT IN (SELECT DISTINCT Type FROM dbo.Content)
   OR Reaction_Type NOT IN (SELECT DISTINCT Type FROM dbo.ReactionTypes);

--4.7 Standardize Data Formats:
-- Convert Category to uppercase for consistency
UPDATE Accenture_Data
SET Category = UPPER(Category);

--4.8 Remove extra spaces, commas, and quotation marks from the Category column
UPDATE Accenture_Data
SET Category = REPLACE(REPLACE(LTRIM(RTRIM(Category)), ',', ''), '"', '');

--4.9 Verify cleaned Data
-- Check the first 20 rows of the cleaned Accenture_Data table
SELECT TOP 20 *
FROM Accenture_Data
*/
--#endregion

--#region 5.0 Aggregation of Data
-- Aggregate data by Category
SELECT Category, 
       COUNT(Category) Total_Contents, 
       SUM(Score) AS Total_Score
FROM Accenture_Data
GROUP BY Category
ORDER BY Total_Score DESC;

-- Aggregate data by Category and Content_Type
SELECT Category, 
       Content_Type, 
       COUNT(Content_Type) AS Total_Content_by_Type, 
       SUM(Score) AS Total_Score
FROM Accenture_Data
GROUP BY Category, Content_Type
ORDER BY Total_Score DESC;

-- Aggregate data by Category and Reaction_Type
SELECT Category, 
       Reaction_Type, 
       COUNT(Reaction_Type) AS Total_Reactions, 
       SUM(Score) AS Total_Score
FROM Accenture_Data
GROUP BY Category, Reaction_Type
ORDER BY Total_Score DESC;
--#endregion

--#region 6.0 View final table before export
-- Display all rows and columns of the cleaned and aggregated Accenture_Data table
SELECT *
FROM Accenture_Data
--#endregion
