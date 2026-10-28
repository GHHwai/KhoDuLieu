
USE Healthcare_location;
GO

IF SCHEMA_ID('silver') IS NULL
    EXEC('CREATE SCHEMA silver');
GO

-- 1. Health center
IF OBJECT_ID('silver.HealthCenter', 'U') IS NULL
CREATE TABLE silver.HealthCenter (
    HealthCenterID BIGINT IDENTITY(1,1) PRIMARY KEY,
    HealthCenterNumber NVARCHAR(100),
    HealthCenterName NVARCHAR(500),
    HealthCenterType NVARCHAR(200),
    HealthCenterTypeDescription NVARCHAR(500),
    OperatorID NVARCHAR(100),
    OperatorDescription NVARCHAR(500),
    OrganizationStreetAddress NVARCHAR(500),
    OrganizationCity NVARCHAR(200),
    OrganizationState NVARCHAR(100),
    OrganizationZIPCode NVARCHAR(50),
    GranteeOrganizationType NVARCHAR(300)
);
GO

-- 2. Location
IF OBJECT_ID('silver.Location', 'U') IS NULL
CREATE TABLE silver.Location (
    LocationID BIGINT IDENTITY(1,1) PRIMARY KEY,
    SiteAddress NVARCHAR(500),
    SiteCity NVARCHAR(200),
    StateAbbreviation NVARCHAR(20),
    PostalCode NVARCHAR(50),
    TelephoneNumber NVARCHAR(100),
    WebAddress NVARCHAR(1000),
    Longitude DECIMAL(12,8),
    Latitude DECIMAL(12,8),
    CountyName NVARCHAR(300),
    CountyEquivalentName NVARCHAR(300),
    CountyDescription NVARCHAR(500),
    CountyFIPS NVARCHAR(50),
    HHSRegionCode NVARCHAR(50),
    HHSRegionName NVARCHAR(200),
    StateFIPSCode NVARCHAR(50),
    StateName NVARCHAR(200),
    LocationTypeDescription NVARCHAR(300),
    LocationSettingDescription NVARCHAR(300)
);
GO

-- 3. Status
IF OBJECT_ID('silver.Status', 'U') IS NULL
CREATE TABLE silver.Status (
    StatusID BIGINT IDENTITY(1,1) PRIMARY KEY,
    StatusCode NVARCHAR(100),
    StatusDescription NVARCHAR(300)
);
GO

-- 4. Schedule
IF OBJECT_ID('silver.Schedule', 'U') IS NULL
CREATE TABLE silver.Schedule (
    ScheduleID BIGINT IDENTITY(1,1) PRIMARY KEY,
    OperatingScheduleID NVARCHAR(100),
    OperationalScheduleDescription NVARCHAR(500),
    OperatingCalendarKey NVARCHAR(100),
    OperatingCalendar NVARCHAR(500),
    OperatingHoursPerWeek DECIMAL(10,2)
);
GO

-- 5. Date
IF OBJECT_ID('silver.Date', 'U') IS NULL
CREATE TABLE silver.[Date] (
    DateID INT PRIMARY KEY,
    FullDate DATE NOT NULL,
    [Day] TINYINT,
    [Month] TINYINT,
    QuarterNumber TINYINT,
    [Year] SMALLINT
);
GO

-- 6. Site: links the normalized entities
IF OBJECT_ID('silver.HealthCenterSite', 'U') IS NULL
CREATE TABLE silver.HealthCenterSite (
    SiteID BIGINT IDENTITY(1,1) PRIMARY KEY,
    SourceRowID BIGINT,
    HealthCenterID BIGINT NOT NULL,
    LocationID BIGINT NOT NULL,
    StatusID BIGINT NULL,
    ScheduleID BIGINT NULL,
    DateID INT NULL,
    SiteName NVARCHAR(500),
    MedicareBillingNumber NVARCHAR(100),
    NPINumber NVARCHAR(100),
    LocationSettingID NVARCHAR(100),
    Border100KmIndicator NVARCHAR(50),
    BorderCountyIndicator NVARCHAR(50),
    CongressionalDistrictCode NVARCHAR(100),
    CongressionalDistrictName NVARCHAR(300),
    CongressionalRepresentative NVARCHAR(300),
    SenatorOne NVARCHAR(300),
    SenatorTwo NVARCHAR(300),
    RecordCreateDate NVARCHAR(100),

    CONSTRAINT FK_Site_HealthCenter
        FOREIGN KEY (HealthCenterID)
        REFERENCES silver.HealthCenter(HealthCenterID),

    CONSTRAINT FK_Site_Location
        FOREIGN KEY (LocationID)
        REFERENCES silver.Location(LocationID),

    CONSTRAINT FK_Site_Status
        FOREIGN KEY (StatusID)
        REFERENCES silver.Status(StatusID),

    CONSTRAINT FK_Site_Schedule
        FOREIGN KEY (ScheduleID)
        REFERENCES silver.Schedule(ScheduleID),

    CONSTRAINT FK_Site_Date
        FOREIGN KEY (DateID)
        REFERENCES silver.[Date](DateID)
);
GO
