Select *
From workoutUpdated2
order by 5

-- Deletes column 

ALTER table workoutUpdated6
DROP COLUMN metadataEntryValue

-- Deletes Row
WITH cte AS (
    SELECT 
        Duration,
        startDate,
        workoutType,
        workoutNum,
        metadataEntryKey,
        metadataEntryValue,
        workoutStatisticsSum,
        workoutStatisticsType,
        workoutStatisticsUnit,
        ROW_NUMBER() OVER (
            PARTITION BY 
                workoutNum,
                metadataEntryKey,
                metadataEntryValue,
                workoutStatisticsSum
            ORDER BY
                workoutNum,
                metadataEntryKey,
                metadataEntryValue,
                workoutStatisticsSum 
        ) row_num
    FROM workoutUpdated6
)
DELETE FROM cte
WHERE row_num > 1

DELETE FROM workoutUpdated6
WHERE metadataEntryKey='HKWeatherHumidity'

-- select rows where metadataEntryKey is NULL
SELECT *
FROM workoutUpdated6
WHERE metadataEntryKey is NULL
and workoutStatisticsSum is NULL

-- delete rows where metadataEntryKey and workoutStatisticsSum are null
DELETE FROM workoutUpdated6
WHERE metadataEntryKey is NULL
and workoutStatisticsSum is NULL


-- fill null values in metadataEntryKey with workoutStatisticsType
WITH cte as (
    SELECT *
    FROM workoutUpdated6
    WHERE metadataEntryKey is NULL
)
UPDATE cte
SET metadataEntryKey = workoutStatisticsType

-- fill null values in metadataEntryValue with workoutStatisticsSum
WITH cte as (
    SELECT *
    FROM workoutUpdated6
    WHERE metadataEntryValue is NULL
)
UPDATE cte
SET metadataEntryValue = workoutStatisticsSum

-- renaming things
UPDATE workoutUpdated6
SET metadataEntryValue = CONCAT(metadataEntryValue, ' Cal')
WHERE workoutStatisticsUnit = 'CAL'

UPDATE workoutUpdated6
SET metadataEntryValue = CONCAT(metadataEntryValue, ' mi')
WHERE workoutStatisticsUnit = 'mi'

-- Split metadataEntryValue into value and Unit Type
SELECT 
    REVERSE(PARSENAME(REPLACE(REVERSE(metadataEntryValue), ' ', '.'), 1)) as Unit,
    REVERSE(PARSENAME(REPLACE(REVERSE(metadataEntryValue), ' ', '.'), 2)) as UnitDecimal,
    REVERSE(PARSENAME(REPLACE(REVERSE(metadataEntryValue), ' ', '.'), 3)) as UnitType
FROM workoutUpdated6

-- add columns Unit, UnitType
ALTER TABLE workoutUpdated6
ADD Unit NVARCHAR(50), UnitType NVARCHAR(50)

-- insert split contents into columns
UPDATE workoutUpdated6
SET Unit = CONCAT(REVERSE(PARSENAME(REPLACE(REVERSE(metadataEntryValue), ' ', '.'), 1)), '.', REVERSE(PARSENAME(REPLACE(REVERSE(metadataEntryValue), ' ', '.'), 2)))

UPDATE workoutUpdated6
SET UnitType = REVERSE(PARSENAME(REPLACE(REVERSE(metadataEntryValue), ' ', '.'), 3))

-- Removing HKWorkoutActivityType
SELECT REPLACE(workoutType, 'HKWorkoutActivityType', '') as newLine
FROM workoutUpdated2

UPDATE workoutUpdated6
set workoutType = REPLACE(workoutType, 'HKWorkoutActivityType', '')

SELECT REPLACE(metadataEntryKey, 'HK', '') as newLine
FROM workoutUpdated1

UPDATE workoutUpdated6
set metadataEntryKey = REPLACE(metadataEntryKey, 'HK', '')

UPDATE workoutUpdated6
set metadataEntryKey = REPLACE(metadataEntryKey, 'WalkingRunning', '')

-- drop endDate column
ALTER table workoutUpdated4
DROP COLUMN startDate, endDate

-- create new column Date, update it to include only the date
ALTER TABLE workoutUpdated4
ADD Date DATE

UPDATE workoutUpdated4
set Date = REVERSE(PARSENAME(REPLACE(REVERSE(startDate), ' ', '.'), 1))

SELECT 
    REVERSE(PARSENAME(REPLACE(REVERSE(startDate), ' ', '.'), 1)) as date,
    REVERSE(PARSENAME(REPLACE(REVERSE(startDate), ' ', '.'), 2)) as time,
    REVERSE(PARSENAME(REPLACE(REVERSE(startDate), ' ', '.'), 3)) as extra
FROM workoutUpdated3

-- fix nulls in unitType
WITH cte as (
    SELECT *
    FROM workoutUpdated6
    WHERE UnitType is NULL
)
UPDATE cte
SET UnitType = REVERSE(PARSENAME(REPLACE(REVERSE(Unit), ' ', '.'), 2))

WITH cte as (
    SELECT *
    FROM workoutUpdated6
    WHERE Unit like '%.degF%'
)
UPDATE cte 
SET Unit = REVERSE(PARSENAME(REPLACE(REVERSE(Unit), ' ', '.'), 1))

-- Convert unit from nvarchar(50) to float
UPDATE workoutUpdated6
SET Unit = TRY_CONVERT(FLOAT, Unit)

ALTER TABLE workoutUpdated6
ALTER COLUMN Unit FLOAT


--------------------------------------------

Select workoutNum, startDate, workoutType, Duration, metadataEntryKey, Unit, UnitType
From workoutUpdated6
WHERE workoutType='Running'
order by 1, 2

SELECT workoutNum, startDate, workoutType, MAX(duration) as test
FROM workoutUpdated6
where workoutType='TraditionalStrengthTraining'
GROUP by workoutNum, startDate, workoutType
ORDER by startDate

-- Average and total duration for each workout type

CREATE VIEW DurationStats as 
WITH cte as (
    SELECT workoutNum, startDate, workoutType, MAX(duration) as maxDur
    FROM workoutUpdated6
    GROUP by workoutNum, startDate, workoutType
)
SELECT workoutType, AVG(maxDur) as averageDurationMin, SUM(maxDur) as totalDurationMin
FROM cte
GROUP by workoutType
GO

CREATE OR ALTER VIEW ActiveEnergyBurnedStats as
WITH cte as (
    SELECT workoutNum, startDate, workoutType, metadataEntryKey, MAX(Unit) as maxUnit, UnitType
    FROM workoutUpdated6
    where metadataEntryKey='ActiveEnergyBurned'
    GROUP by workoutNum, startDate, workoutType, metadataEntryKey, UnitType
)
SELECT workoutType, AVG(maxUnit) as averageCal, SUM(maxUnit) as totalCal
FROM cte 
GROUP by workoutType
GO

CREATE OR ALTER VIEW BasalEnergyBurnedStats as
WITH cte as (
    SELECT workoutNum, startDate, workoutType, metadataEntryKey, MAX(Unit) as maxUnit, UnitType
    FROM workoutUpdated6
    where metadataEntryKey='BasalEnergyBurned'
    GROUP by workoutNum, startDate, workoutType, metadataEntryKey, UnitType
)
SELECT workoutType, AVG(maxUnit) as averageCal, SUM(maxUnit) as totalCal
FROM cte 
GROUP by workoutType
GO

CREATE OR ALTER VIEW RunningStats as
with cte as (
    SELECT workoutNum, startDate, workoutType, metadataEntryKey, Unit, UnitType
    FROM workoutUpdated6
    where metadataEntryKey='distance'
    and workoutType='Running'
    GROUP by workoutNum, startDate, workoutType, metadataEntryKey, Unit, UnitType
)
SELECT workoutType, AVG(Unit) as AvgMiles, SUM(Unit) as TotalMiles
FROM cte
GROUP by workoutType
GO

-- HealthExport1
------------------------------------------------------------------------------------------------
ALTER table healthExport1
DROP COLUMN creationDate, appleExerciseTime, dateComponents, activeEnergyBurnedUnit, activeEnergyBurned

ALTER table healthExport1
DROP COLUMN sourceName

ALTER TABLE healthExport1
ADD Date DATE

UPDATE healthExport1
set Date = REVERSE(PARSENAME(REPLACE(REVERSE(startDate), ' ', '.'), 1))


DELETE FROM healthExport1
WHERE date is NULL

------------------------------------------------------------------------------------------------


-- SELECT Date, type, SUM(value) as TotalDistance, unit
SELECT Date, SUM(value) as TotalMiles INTO TotalMiles
FROM healthExport1
WHERE type='DistanceWalkingRunning'
GROUP by Date, type, unit
ORDER by Date
GO

Select Date, type, SUM(value) as TotalSteps, unit
FROM healthExport1
WHERE type='stepCount'
GROUP BY Date, type, unit
ORDER by Date
GO

-- Select Date, type, SUM(value) as TotalFlightsClimbed, unit
SELECT Date, SUM(value) as TotalFlightsClimbed INTO TotalFlightsClimbed
FROM healthExport1
WHERE type='FlightsClimbed'
GROUP BY Date, type, unit
ORDER by Date
GO

-- Select Date, type, AVG(value) as AverageHeartRate, unit
SELECT Date, AVG(value) as AverageBPM INTO AverageHeartRate
FROM healthExport1
WHERE type='HeartRate'
GROUP BY Date, type, unit
ORDER by Date
GO

Select Date, type, AVG(value) as AverageHeadphoneAudioExposure, unit
FROM healthExport1
WHERE type='HeadphoneAudioExposure'
GROUP BY Date, type, unit
ORDER by Date
GO

Select Date, type, AVG(value) as EnvironmentalAudioExposure, unit
FROM healthExport1
WHERE type='EnvironmentalAudioExposure'
GROUP BY Date, type, unit
ORDER by Date
GO

-- Select Date, type, AVG(value) as AverageStepLength, unit
SELECT Date, AVG(value) as AverageStepLength INTO AverageStepLength
FROM healthExport1
WHERE type='WalkingStepLength'
GROUP BY Date, type, unit
ORDER by Date
GO

-- Select Date, type, AVG(value) as AverageWalkingSpeed, unit
SELECT Date, AVG(value) as AverageWalkingSpeedMPH INTO AverageWalkSpeed
FROM healthExport1
WHERE type='WalkingSpeed'
GROUP BY Date, type, unit
ORDER by Date
GO

-- Select Date, type, SUM(value) as TotalStandTime, unit
SELECT Date, SUM(value) as TotalMinutesStanding INTO TotalStandingTime
FROM healthExport1
WHERE type='AppleStandTime'
GROUP BY Date, type, unit
ORDER by Date
GO

-- Select Date, type, AVG(value) as AverageOxygenSaturation, unit
SELECT Date, AVG(value) as AverageOxygenSaturation INTO AverageOxygenSaturation
FROM healthExport1
WHERE type='OxygenSaturation'
GROUP BY Date, type, unit
ORDER by Date
GO

-- Select Date, type, AVG(value) as WalkingAverage, unit
SELECT Date, AVG(value) as WalkingHeartBPM INTO WalkingHeartBPM
FROM healthExport1
WHERE type='WalkingHeartRateAverage'
GROUP BY Date, type, unit
ORDER by Date
GO

-- Select Date, type, value, unit
SELECT Date, AVG(value) as RestingHeartBPM INTO RestingHeartBPM
FROM healthExport1
WHERE type='RestingHeartRate'
GROUP BY Date, type, unit
ORDER by Date
GO
------------------------------------------------------------------------------------------------


SELECT Date, type, value, unit
FROM healthExport1
WHERE type not like '%DistanceWalkingRunning%'
and type not like '%StepCount%'
and type not like '%FlightsClimbed%'
and type not like '%HeartRate%'
and type not like '%HeadphoneAudioExposure%'
and type not like '%WalkingStepLength%'
and type not like '%WalkingSpeed%'
ORDER by Date

-- Remove lines with ActiveEnergyBurned and BasalEnergyBurned
DELETE FROM healthExport1
WHERE type='VO2Max'

SELECT Date, type, value, unit
FROM healthExport1
WHERE type='SixMinuteWalkTestDistance'
ORDER by Date
GO

--Create tables
CREATE TABLE StepsAndDistance
(
    Date DATE,
    TotalSteps FLOAT,
    TotalMiles FLOAT
)



SELECT Date, SUM(value) as TotalMiles
FROM healthExport1
WHERE type='DistanceWalkingRunning'
GROUP by Date
ORDER by Date
GO

Select Date, SUM(value) as TotalSteps
FROM healthExport1
WHERE type='stepCount'
GROUP BY Date
ORDER by Date
GO


-- INSERT INTO StepsAndDistance (Date, TotalSteps)
Select Date, SUM(value) as TotalSteps INTO TotalSteps
FROM healthExport1
WHERE type='stepCount'
GROUP BY Date
ORDER by Date

-- INSERT INTO StepsAndDistance (Date, TotalMiles)
SELECT Date, SUM(value) as TotalMiles
FROM healthExport1
WHERE type='DistanceWalkingRunning'
GROUP by Date
ORDER by Date
GO



SELECT Date, SUM(value) as TotalMiles
FROM healthExport1
WHERE type='DistanceWalkingRunning'
GROUP by Date
ORDER by Date
GO

Select Date, SUM(value) as TotalSteps
FROM healthExport1
WHERE type='stepCount'
GROUP BY Date
ORDER by Date
GO

SELECT Date, (
    SELECT SUM(value)
    FROM healthExport1
    WHERE type='DistanceWalkingRunning'
    -- GROUP by Date
) as TotalMiles, (
    SELECT SUM(value)
    FROM healthExport1
    WHERE type='stepCount'
    -- GROUP BY Date
) as TotalSteps
FROM healthExport1
GROUP BY Date
ORDER by Date

SELECT a.Date, a.type, SUM(a.value) as TotalMiles, b.Date, b.type, SUM(b.value) as TotalSteps
From healthExport1 as a
INNER JOIN healthExport1 as b
on a.Date = b.Date
WHERE a.type='DistanceWalkingRunning'
and b.type='stepCount'
GROUP BY a.Date, a.type, b.Date, b.type
ORDER by a.Date
GO

SELECT Date, SUM(value) as TotalMiles
FROM healthExport1
WHERE type='DistanceWalkingRunning'
GROUP by Date
ORDER by Date
GO

Select Date, SUM(value) as TotalSteps
FROM healthExport1
WHERE type='stepCount'
GROUP BY Date
ORDER by Date
GO

DROP TABLE Running1
DROP VIEW ActiveEnergyBurnedStats

-------------------------------------------------------------------------------------------------
-- Merge Tables

--Heart Tables
SELECT *
FROM AverageHeartRate
ORDER by Date

SELECT *
FROM AverageOxygenSaturation
ORDER by Date

SELECT *
FROM RestingHeartBPM
ORDER by Date

SELECT *
FROM WalkingHeartBPM
ORDER by Date

--------

SELECT *
FROM AverageStepLength
ORDER by Date

SELECT *
FROM AverageWalkSpeed
ORDER by Date

SELECT *
FROM TotalFlightsClimbed
ORDER by Date

SELECT *
FROM TotalMiles
ORDER by Date

SELECT *
FROM TotalStandingTime
ORDER by Date

SELECT *
FROM TotalSteps
ORDER by Date

-- Merge Heart Tables
SELECT a.Date, AverageBPM, AverageOxygenSaturation INTO HeartTable1
FROM AverageHeartRate a
FULL JOIN AverageOxygenSaturation b
    ON a.Date=b.Date 
Order by a.Date

SELECT a.Date, AverageBPM, AverageOxygenSaturation, RestingHeartBPM INTO HeartTable2
FROM HeartTable1 a 
FULL JOIN RestingHeartBPM b 
    ON a.Date=b.Date 
ORDER by a.Date

SELECT a.Date, AverageBPM, AverageOxygenSaturation, RestingHeartBPM, WalkingHeartBPM INTO HeartTable3
FROM HeartTable2 a 
FULL JOIN WalkingHeartBPM b 
    ON a.Date=b.Date 
ORDER by a.Date

SELECT Date, AverageBPM as AvgBPM, RestingHeartBPM, WalkingHeartBPM, AverageOxygenSaturation as AvgOxygenSaturation INTO HeartTable
FROM HeartTable3
ORDER by Date

-- Merge Step Table
SELECT a.Date, AverageStepLength, AverageWalkingSpeedMPH INTO StepTable1
FROM AverageStepLength a
FULL JOIN AverageWalkSpeed b
    on a.Date=b.Date

SELECT b.Date, AverageStepLength, AverageWalkingSpeedMPH, TotalMiles INTO StepTable2
FROM StepTable1 a
FULL JOIN TotalMiles b
    on a.Date=b.Date
ORDER by b.Date

SELECT a.Date, AverageStepLength, AverageWalkingSpeedMPH, TotalMiles, TotalFlightsClimbed INTO StepTable3
FROM StepTable2 a
FULL JOIN TotalFlightsClimbed b
    on a.Date=b.Date
ORDER by a.Date

SELECT a.Date, AverageStepLength, AverageWalkingSpeedMPH, TotalMiles, TotalFlightsClimbed, TotalMinutesStanding INTO StepTable4
FROM StepTable3 a
FULL JOIN TotalStandingTime b
    on a.Date=b.Date
ORDER by a.Date

SELECT a.Date, AverageStepLength, AverageWalkingSpeedMPH, TotalMiles, TotalFlightsClimbed, TotalMinutesStanding, TotalSteps INTO StepTable5
FROM StepTable4 a
FULL JOIN TotalSteps b
    on a.Date=b.Date
ORDER by a.Date

SELECT Date, TotalSteps, TotalMiles, AverageStepLength as AvgStepLength, AverageWalkingSpeedMPH as AvgWalkSpeed, TotalFLightsClimbed, TotalMinutesStanding INTO StepTable
FROM StepTable5
ORDER by Date 
-------------------------------------------------------------------------------------------------
-------- Make workoutUpdated tables --------

SELECT *
FROM StrengthTrainingBasal
ORDER by Date

SELECT startDate as Date, Duration, Unit as ActiveCalories INTO RunningActive
-- SELECT *
FROM workoutUpdated6
WHERE workoutType='Running'
AND metadataEntryKey='ActiveEnergyBurned'
ORDER BY startDate

SELECT Date, Duration, Miles, ActiveCalories, BasalCalories INTO Running
FROM Running1
-- FULL JOIN workoutUpdated6 b
--     ON a.Date=b.startDate
-- WHERE UnitType='mi'
ORDER BY Date
----------------------------------------------------------

SELECT *
FROM ActiveEnergyBurnedStats

SELECT *
FROM BasalEnergyBurnedStats

SELECT *
FROM DurationStats

SELECT *
FROM RunningStats

SELECT *
FROM HeartTable

SELECT *
FROM StepTable

SELECT *
FROM StrengthTraining

SELECT *
FROM CoreTraining

SELECT *
FROM Running