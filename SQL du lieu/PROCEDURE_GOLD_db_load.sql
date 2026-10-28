
USE Heathcare_location;
GO

IF SCHEMA_ID('gold') IS NULL
    EXEC('CREATE SCHEMA gold');
GO

IF OBJECT_ID('gold.FactHealthCenterSchedule', 'U') IS NOT NULL
    DROP TABLE gold.FactHealthCenterSchedule;

IF OBJECT_ID('gold.FactHealthCenterSite', 'U') IS NOT NULL
    DROP TABLE gold.FactHealthCenterSite;

IF OBJECT_ID('gold.DimDate', 'U') IS NOT NULL
    DROP TABLE gold.DimDate;

IF OBJECT_ID('gold.DimSchedule', 'U') IS NOT NULL
    DROP TABLE gold.DimSchedule;

IF OBJECT_ID('gold.DimStatus', 'U') IS NOT NULL
    DROP TABLE gold.DimStatus;

IF OBJECT_ID('gold.DimLocation', 'U') IS NOT NULL
    DROP TABLE gold.DimLocation;

IF OBJECT_ID('gold.DimHealthCenter', 'U') IS NOT NULL
    DROP TABLE gold.DimHealthCenter;
GO

SELECT *
INTO gold.DimHealthCenter
FROM silver.HealthCenter;

SELECT *
INTO gold.DimLocation
FROM silver.Location;

SELECT *
INTO gold.DimStatus
FROM silver.Status;

SELECT *
INTO gold.DimSchedule
FROM silver.Schedule;

SELECT *
INTO gold.DimDate
FROM silver.[Date];
GO

ALTER TABLE gold.DimHealthCenter
ADD CONSTRAINT PK_DimHealthCenter
PRIMARY KEY (HealthCenterID);

ALTER TABLE gold.DimLocation
ADD CONSTRAINT PK_DimLocation
PRIMARY KEY (LocationID);

ALTER TABLE gold.DimStatus
ADD CONSTRAINT PK_DimStatus
PRIMARY KEY (StatusID);

ALTER TABLE gold.DimSchedule
ADD CONSTRAINT PK_DimSchedule
PRIMARY KEY (ScheduleID);

ALTER TABLE gold.DimDate
ADD CONSTRAINT PK_DimDate
PRIMARY KEY (DateID);
GO

CREATE TABLE gold.FactHealthCenterSite
(
    FactSiteKey BIGINT IDENTITY(1,1) NOT NULL,
    SourceRowID BIGINT NOT NULL,
    HealthCenterID BIGINT NOT NULL,
    LocationID BIGINT NOT NULL,
    StatusID BIGINT NULL,
    ScheduleID BIGINT NULL,
    DateID INT NULL,
    SiteCount INT NOT NULL DEFAULT 1,
    SiteName NVARCHAR(500) NULL,
    MedicareBillingNumber NVARCHAR(100) NULL,
    NPINumber NVARCHAR(100) NULL,

    CONSTRAINT PK_FactHealthCenterSite
        PRIMARY KEY (FactSiteKey),

    CONSTRAINT UQ_FactHealthCenterSite_SourceRowID
        UNIQUE (SourceRowID),

    CONSTRAINT FK_FactSite_HealthCenter
        FOREIGN KEY (HealthCenterID)
        REFERENCES gold.DimHealthCenter(HealthCenterID),

    CONSTRAINT FK_FactSite_Location
        FOREIGN KEY (LocationID)
        REFERENCES gold.DimLocation(LocationID),

    CONSTRAINT FK_FactSite_Status
        FOREIGN KEY (StatusID)
        REFERENCES gold.DimStatus(StatusID),

    CONSTRAINT FK_FactSite_Schedule
        FOREIGN KEY (ScheduleID)
        REFERENCES gold.DimSchedule(ScheduleID),

    CONSTRAINT FK_FactSite_Date
        FOREIGN KEY (DateID)
        REFERENCES gold.DimDate(DateID)
);
GO

INSERT INTO gold.FactHealthCenterSite
(
    SourceRowID,
    HealthCenterID,
    LocationID,
    StatusID,
    ScheduleID,
    DateID,
    SiteCount,
    SiteName,
    MedicareBillingNumber,
    NPINumber
)
SELECT
    SourceRowID,
    HealthCenterID,
    LocationID,
    StatusID,
    ScheduleID,
    DateID,
    1,
    SiteName,
    MedicareBillingNumber,
    NPINumber
FROM silver.HealthCenterSite;
GO

CREATE TABLE gold.FactHealthCenterSchedule
(
    FactScheduleKey BIGINT IDENTITY(1,1) NOT NULL,
    SourceRowID BIGINT NOT NULL,
    HealthCenterID BIGINT NOT NULL,
    LocationID BIGINT NOT NULL,
    StatusID BIGINT NULL,
    ScheduleID BIGINT NOT NULL,
    DateID INT NULL,
    OperatingHoursPerWeek DECIMAL(10,2) NULL,
    ScheduleCount INT NOT NULL DEFAULT 1,

    CONSTRAINT PK_FactHealthCenterSchedule
        PRIMARY KEY (FactScheduleKey),

    CONSTRAINT UQ_FactHealthCenterSchedule_SourceRowID
        UNIQUE (SourceRowID),

    CONSTRAINT FK_FactSchedule_HealthCenter
        FOREIGN KEY (HealthCenterID)
        REFERENCES gold.DimHealthCenter(HealthCenterID),

    CONSTRAINT FK_FactSchedule_Location
        FOREIGN KEY (LocationID)
        REFERENCES gold.DimLocation(LocationID),

    CONSTRAINT FK_FactSchedule_Status
        FOREIGN KEY (StatusID)
        REFERENCES gold.DimStatus(StatusID),

    CONSTRAINT FK_FactSchedule_Schedule
        FOREIGN KEY (ScheduleID)
        REFERENCES gold.DimSchedule(ScheduleID),

    CONSTRAINT FK_FactSchedule_Date
        FOREIGN KEY (DateID)
        REFERENCES gold.DimDate(DateID)
);
GO

INSERT INTO gold.FactHealthCenterSchedule
(
    SourceRowID,
    HealthCenterID,
    LocationID,
    StatusID,
    ScheduleID,
    DateID,
    OperatingHoursPerWeek,
    ScheduleCount
)
SELECT
    fs.SourceRowID,
    fs.HealthCenterID,
    fs.LocationID,
    fs.StatusID,
    fs.ScheduleID,
    fs.DateID,
    sch.OperatingHoursPerWeek,
    1
FROM silver.HealthCenterSite fs
INNER JOIN silver.Schedule sch
    ON sch.ScheduleID = fs.ScheduleID;
GO

SELECT 'DimHealthCenter' AS TableName, COUNT_BIG(*) AS TotalRows
FROM gold.DimHealthCenter
UNION ALL
SELECT 'DimLocation', COUNT_BIG(*) FROM gold.DimLocation
UNION ALL
SELECT 'DimStatus', COUNT_BIG(*) FROM gold.DimStatus
UNION ALL
SELECT 'DimSchedule', COUNT_BIG(*) FROM gold.DimSchedule
UNION ALL
SELECT 'DimDate', COUNT_BIG(*) FROM gold.DimDate
UNION ALL
SELECT 'FactHealthCenterSite', COUNT_BIG(*) FROM gold.FactHealthCenterSite
UNION ALL
SELECT 'FactHealthCenterSchedule', COUNT_BIG(*) FROM gold.FactHealthCenterSchedule;
GO
