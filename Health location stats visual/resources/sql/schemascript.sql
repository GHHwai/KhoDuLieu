-- Healthcare_location schema script (condensed copy of the original SSMS script:
-- server/database settings removed, table + constraint + procedure structure kept).
-- Upload your full schemascript.sql in the app to replace this file.
USE [Healthcare_location]
GO
CREATE SCHEMA [bronze]
GO
CREATE SCHEMA [gold]
GO
CREATE SCHEMA [silver]
GO
CREATE TABLE [bronze].[health_center_service](
	[Health Center Type] [nvarchar](max) NULL,
	[Health Center Number] [nvarchar](max) NULL,
	[BHCMIS Organization Identification Number] [nvarchar](max) NULL,
	[BPHC Assigned Number] [nvarchar](max) NULL,
	[Site Name] [nvarchar](max) NULL,
	[Site Address] [nvarchar](max) NULL,
	[Site City] [nvarchar](max) NULL,
	[Site State Abbreviation] [nvarchar](max) NULL,
	[Site Postal Code] [nvarchar](max) NULL,
	[Site Telephone Number] [nvarchar](max) NULL,
	[Site Web Address] [nvarchar](max) NULL,
	[Operating Hours per Week] [nvarchar](max) NULL,
	[Health Center Location Setting Identification Number] [nvarchar](max) NULL,
	[Health Center Service Delivery Site Location Setting Description] [nvarchar](max) NULL,
	[Health Center Status Identification Number] [nvarchar](max) NULL,
	[Site Status Description] [nvarchar](max) NULL,
	[FQHC Site Medicare Billing Number] [nvarchar](max) NULL,
	[FQHC Site NPI Number] [nvarchar](max) NULL,
	[Health Center Location Identification Number] [nvarchar](max) NULL,
	[Health Center Location Type Description] [nvarchar](max) NULL,
	[Health Center Type Identification Number] [nvarchar](max) NULL,
	[Health Center Type Description] [nvarchar](max) NULL,
	[Health Center Operator Identification Number] [nvarchar](max) NULL,
	[Health Center Operator Description] [nvarchar](max) NULL,
	[Health Center Operating Schedule Identification Number] [nvarchar](max) NULL,
	[Health Center Operational Schedule Description] [nvarchar](max) NULL,
	[Health Center Operating Calendar Surrogate Key] [nvarchar](max) NULL,
	[Health Center Operating Calendar] [nvarchar](max) NULL,
	[Site Added to Scope this Date] [nvarchar](max) NULL,
	[Health Center Name] [nvarchar](max) NULL,
	[Health Center Organization Street Address] [nvarchar](max) NULL,
	[Health Center Organization City] [nvarchar](max) NULL,
	[Health Center Organization State] [nvarchar](max) NULL,
	[Health Center Organization ZIP Code] [nvarchar](max) NULL,
	[Grantee Organization Type Description] [nvarchar](max) NULL,
	[Geocoding Artifact Address Primary X Coordinate] [nvarchar](max) NULL,
	[Geocoding Artifact Address Primary Y Coordinate] [nvarchar](max) NULL,
	[U.S. - Mexico Border 100 Kilometer Indicator] [nvarchar](max) NULL,
	[U.S. - Mexico Border County Indicator] [nvarchar](max) NULL,
	[State and County Federal Information Processing Standard Code] [nvarchar](max) NULL,
	[Complete County Name] [nvarchar](max) NULL,
	[County Equivalent Name] [nvarchar](max) NULL,
	[County Description] [nvarchar](max) NULL,
	[HHS Region Code] [nvarchar](max) NULL,
	[HHS Region Name] [nvarchar](max) NULL,
	[State FIPS Code] [nvarchar](max) NULL,
	[State Name] [nvarchar](max) NULL,
	[State FIPS and Congressional District Number Code] [nvarchar](max) NULL,
	[Congressional District Number] [nvarchar](max) NULL,
	[Congressional District Name] [nvarchar](max) NULL,
	[Congressional District Code] [nvarchar](max) NULL,
	[U.S. Congressional Representative Name] [nvarchar](max) NULL,
	[Name of U.S. Senator Number One] [nvarchar](max) NULL,
	[Name of U.S. Senator Number Two] [nvarchar](max) NULL,
	[Data Warehouse Record Create Date] [nvarchar](max) NULL,
	[bronze_row_id] [bigint] IDENTITY(1,1) NOT NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
CREATE TABLE [bronze].[health_center_service_staging](
	[Health Center Type] [nvarchar](max) NULL,
	[Health Center Number] [nvarchar](max) NULL,
	[BHCMIS Organization Identification Number] [nvarchar](max) NULL,
	[BPHC Assigned Number] [nvarchar](max) NULL,
	[Site Name] [nvarchar](max) NULL,
	[Site Address] [nvarchar](max) NULL,
	[Site City] [nvarchar](max) NULL,
	[Site State Abbreviation] [nvarchar](max) NULL,
	[Site Postal Code] [nvarchar](max) NULL,
	[Site Telephone Number] [nvarchar](max) NULL,
	[Site Web Address] [nvarchar](max) NULL,
	[Operating Hours per Week] [nvarchar](max) NULL,
	[Health Center Location Setting Identification Number] [nvarchar](max) NULL,
	[Health Center Service Delivery Site Location Setting Description] [nvarchar](max) NULL,
	[Health Center Status Identification Number] [nvarchar](max) NULL,
	[Site Status Description] [nvarchar](max) NULL,
	[FQHC Site Medicare Billing Number] [nvarchar](max) NULL,
	[FQHC Site NPI Number] [nvarchar](max) NULL,
	[Health Center Location Identification Number] [nvarchar](max) NULL,
	[Health Center Location Type Description] [nvarchar](max) NULL,
	[Health Center Type Identification Number] [nvarchar](max) NULL,
	[Health Center Type Description] [nvarchar](max) NULL,
	[Health Center Operator Identification Number] [nvarchar](max) NULL,
	[Health Center Operator Description] [nvarchar](max) NULL,
	[Health Center Operating Schedule Identification Number] [nvarchar](max) NULL,
	[Health Center Operational Schedule Description] [nvarchar](max) NULL,
	[Health Center Operating Calendar Surrogate Key] [nvarchar](max) NULL,
	[Health Center Operating Calendar] [nvarchar](max) NULL,
	[Site Added to Scope this Date] [nvarchar](max) NULL,
	[Health Center Name] [nvarchar](max) NULL,
	[Health Center Organization Street Address] [nvarchar](max) NULL,
	[Health Center Organization City] [nvarchar](max) NULL,
	[Health Center Organization State] [nvarchar](max) NULL,
	[Health Center Organization ZIP Code] [nvarchar](max) NULL,
	[Grantee Organization Type Description] [nvarchar](max) NULL,
	[Geocoding Artifact Address Primary X Coordinate] [nvarchar](max) NULL,
	[Geocoding Artifact Address Primary Y Coordinate] [nvarchar](max) NULL,
	[U.S. - Mexico Border 100 Kilometer Indicator] [nvarchar](max) NULL,
	[U.S. - Mexico Border County Indicator] [nvarchar](max) NULL,
	[State and County Federal Information Processing Standard Code] [nvarchar](max) NULL,
	[Complete County Name] [nvarchar](max) NULL,
	[County Equivalent Name] [nvarchar](max) NULL,
	[County Description] [nvarchar](max) NULL,
	[HHS Region Code] [nvarchar](max) NULL,
	[HHS Region Name] [nvarchar](max) NULL,
	[State FIPS Code] [nvarchar](max) NULL,
	[State Name] [nvarchar](max) NULL,
	[State FIPS and Congressional District Number Code] [nvarchar](max) NULL,
	[Congressional District Number] [nvarchar](max) NULL,
	[Congressional District Name] [nvarchar](max) NULL,
	[Congressional District Code] [nvarchar](max) NULL,
	[U.S. Congressional Representative Name] [nvarchar](max) NULL,
	[Name of U.S. Senator Number One] [nvarchar](max) NULL,
	[Name of U.S. Senator Number Two] [nvarchar](max) NULL,
	[Data Warehouse Record Create Date] [nvarchar](max) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
CREATE TABLE [gold].[DimDate](
	[DateID] [int] NOT NULL,
	[FullDate] [date] NOT NULL,
	[Day] [int] NULL,
	[Month] [int] NULL,
	[QuarterNumber] [int] NULL,
	[Year] [int] NULL,
 CONSTRAINT [PK_DimDate] PRIMARY KEY CLUSTERED 
(
	[DateID] ASC
)WITH (PAD_INDEX = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
CREATE TABLE [gold].[DimHealthCenter](
	[HealthCenterID] [bigint] IDENTITY(1,1) NOT NULL,
	[HealthCenterNumber] [nvarchar](max) NULL,
	[HealthCenterName] [nvarchar](max) NULL,
	[HealthCenterType] [nvarchar](max) NULL,
	[HealthCenterTypeDescription] [nvarchar](max) NULL,
	[OperatorID] [nvarchar](max) NULL,
	[OperatorDescription] [nvarchar](max) NULL,
	[OrganizationStreetAddress] [nvarchar](max) NULL,
	[OrganizationCity] [nvarchar](max) NULL,
	[OrganizationState] [nvarchar](max) NULL,
	[OrganizationZIPCode] [nvarchar](max) NULL,
	[GranteeOrganizationType] [nvarchar](max) NULL,
 CONSTRAINT [PK_DimHealthCenter] PRIMARY KEY CLUSTERED 
(
	[HealthCenterID] ASC
)WITH (PAD_INDEX = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
CREATE TABLE [gold].[DimLocation](
	[LocationID] [bigint] IDENTITY(1,1) NOT NULL,
	[SiteAddress] [nvarchar](max) NULL,
	[SiteCity] [nvarchar](max) NULL,
	[StateAbbreviation] [nvarchar](max) NULL,
	[PostalCode] [nvarchar](max) NULL,
	[TelephoneNumber] [nvarchar](max) NULL,
	[WebAddress] [nvarchar](max) NULL,
	[Longitude] [decimal](12, 8) NULL,
	[Latitude] [decimal](12, 8) NULL,
	[CountyName] [nvarchar](max) NULL,
	[CountyEquivalentName] [nvarchar](max) NULL,
	[CountyDescription] [nvarchar](max) NULL,
	[CountyFIPS] [nvarchar](max) NULL,
	[HHSRegionCode] [nvarchar](max) NULL,
	[HHSRegionName] [nvarchar](max) NULL,
	[StateFIPSCode] [nvarchar](max) NULL,
	[StateName] [nvarchar](max) NULL,
	[LocationTypeDescription] [nvarchar](max) NULL,
	[LocationSettingDescription] [nvarchar](max) NULL,
 CONSTRAINT [PK_DimLocation] PRIMARY KEY CLUSTERED 
(
	[LocationID] ASC
)WITH (PAD_INDEX = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
CREATE TABLE [gold].[DimSchedule](
	[ScheduleID] [bigint] IDENTITY(1,1) NOT NULL,
	[OperatingScheduleID] [nvarchar](max) NULL,
	[OperationalScheduleDescription] [nvarchar](max) NULL,
	[OperatingCalendarKey] [nvarchar](max) NULL,
	[OperatingCalendar] [nvarchar](max) NULL,
	[OperatingHoursPerWeek] [decimal](10, 2) NULL,
 CONSTRAINT [PK_DimSchedule] PRIMARY KEY CLUSTERED 
(
	[ScheduleID] ASC
)WITH (PAD_INDEX = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
CREATE TABLE [gold].[DimStatus](
	[StatusID] [bigint] IDENTITY(1,1) NOT NULL,
	[StatusCode] [nvarchar](max) NULL,
	[StatusDescription] [nvarchar](max) NULL,
 CONSTRAINT [PK_DimStatus] PRIMARY KEY CLUSTERED 
(
	[StatusID] ASC
)WITH (PAD_INDEX = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
CREATE TABLE [gold].[FactHealthCenterSchedule](
	[FactScheduleKey] [bigint] IDENTITY(1,1) NOT NULL,
	[SourceRowID] [bigint] NOT NULL,
	[HealthCenterID] [bigint] NOT NULL,
	[LocationID] [bigint] NOT NULL,
	[StatusID] [bigint] NULL,
	[ScheduleID] [bigint] NOT NULL,
	[DateID] [int] NULL,
	[OperatingHoursPerWeek] [decimal](10, 2) NULL,
	[ScheduleCount] [int] NOT NULL,
 CONSTRAINT [PK_FactHealthCenterSchedule] PRIMARY KEY CLUSTERED 
(
	[FactScheduleKey] ASC
)WITH (PAD_INDEX = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_FactHealthCenterSchedule_SourceRowID] UNIQUE NONCLUSTERED 
(
	[SourceRowID] ASC
)WITH (PAD_INDEX = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
CREATE TABLE [gold].[FactHealthCenterSite](
	[FactSiteKey] [bigint] IDENTITY(1,1) NOT NULL,
	[SourceRowID] [bigint] NOT NULL,
	[HealthCenterID] [bigint] NOT NULL,
	[LocationID] [bigint] NOT NULL,
	[StatusID] [bigint] NULL,
	[ScheduleID] [bigint] NULL,
	[DateID] [int] NULL,
	[SiteCount] [int] NOT NULL,
	[SiteName] [nvarchar](500) NULL,
	[MedicareBillingNumber] [nvarchar](100) NULL,
	[NPINumber] [nvarchar](100) NULL,
 CONSTRAINT [PK_FactHealthCenterSite] PRIMARY KEY CLUSTERED 
(
	[FactSiteKey] ASC
)WITH (PAD_INDEX = OFF) ON [PRIMARY],
 CONSTRAINT [UQ_FactHealthCenterSite_SourceRowID] UNIQUE NONCLUSTERED 
(
	[SourceRowID] ASC
)WITH (PAD_INDEX = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
CREATE TABLE [silver].[Date](
	[DateID] [int] NOT NULL,
	[FullDate] [date] NOT NULL,
	[Day] [int] NULL,
	[Month] [int] NULL,
	[QuarterNumber] [int] NULL,
	[Year] [int] NULL,
PRIMARY KEY CLUSTERED 
(
	[DateID] ASC
)WITH (PAD_INDEX = OFF) ON [PRIMARY],
UNIQUE NONCLUSTERED 
(
	[FullDate] ASC
)WITH (PAD_INDEX = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
CREATE TABLE [silver].[HealthCenter](
	[HealthCenterID] [bigint] IDENTITY(1,1) NOT NULL,
	[HealthCenterNumber] [nvarchar](max) NULL,
	[HealthCenterName] [nvarchar](max) NULL,
	[HealthCenterType] [nvarchar](max) NULL,
	[HealthCenterTypeDescription] [nvarchar](max) NULL,
	[OperatorID] [nvarchar](max) NULL,
	[OperatorDescription] [nvarchar](max) NULL,
	[OrganizationStreetAddress] [nvarchar](max) NULL,
	[OrganizationCity] [nvarchar](max) NULL,
	[OrganizationState] [nvarchar](max) NULL,
	[OrganizationZIPCode] [nvarchar](max) NULL,
	[GranteeOrganizationType] [nvarchar](max) NULL,
PRIMARY KEY CLUSTERED 
(
	[HealthCenterID] ASC
)WITH (PAD_INDEX = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
CREATE TABLE [silver].[HealthCenterSite](
	[SourceRowID] [bigint] NOT NULL,
	[HealthCenterID] [bigint] NOT NULL,
	[LocationID] [bigint] NOT NULL,
	[StatusID] [bigint] NULL,
	[ScheduleID] [bigint] NULL,
	[DateID] [int] NULL,
	[SiteName] [nvarchar](max) NULL,
	[MedicareBillingNumber] [nvarchar](max) NULL,
	[NPINumber] [nvarchar](max) NULL,
	[LocationSettingID] [nvarchar](max) NULL,
	[Border100KmIndicator] [nvarchar](max) NULL,
	[BorderCountyIndicator] [nvarchar](max) NULL,
	[CongressionalDistrictCode] [nvarchar](max) NULL,
	[CongressionalDistrictName] [nvarchar](max) NULL,
	[CongressionalRepresentative] [nvarchar](max) NULL,
	[SenatorOne] [nvarchar](max) NULL,
	[SenatorTwo] [nvarchar](max) NULL,
	[RecordCreateDate] [nvarchar](max) NULL,
PRIMARY KEY CLUSTERED 
(
	[SourceRowID] ASC
)WITH (PAD_INDEX = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
CREATE TABLE [silver].[Location](
	[LocationID] [bigint] IDENTITY(1,1) NOT NULL,
	[SiteAddress] [nvarchar](max) NULL,
	[SiteCity] [nvarchar](max) NULL,
	[StateAbbreviation] [nvarchar](max) NULL,
	[PostalCode] [nvarchar](max) NULL,
	[TelephoneNumber] [nvarchar](max) NULL,
	[WebAddress] [nvarchar](max) NULL,
	[Longitude] [decimal](12, 8) NULL,
	[Latitude] [decimal](12, 8) NULL,
	[CountyName] [nvarchar](max) NULL,
	[CountyEquivalentName] [nvarchar](max) NULL,
	[CountyDescription] [nvarchar](max) NULL,
	[CountyFIPS] [nvarchar](max) NULL,
	[HHSRegionCode] [nvarchar](max) NULL,
	[HHSRegionName] [nvarchar](max) NULL,
	[StateFIPSCode] [nvarchar](max) NULL,
	[StateName] [nvarchar](max) NULL,
	[LocationTypeDescription] [nvarchar](max) NULL,
	[LocationSettingDescription] [nvarchar](max) NULL,
PRIMARY KEY CLUSTERED 
(
	[LocationID] ASC
)WITH (PAD_INDEX = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
CREATE TABLE [silver].[Schedule](
	[ScheduleID] [bigint] IDENTITY(1,1) NOT NULL,
	[OperatingScheduleID] [nvarchar](max) NULL,
	[OperationalScheduleDescription] [nvarchar](max) NULL,
	[OperatingCalendarKey] [nvarchar](max) NULL,
	[OperatingCalendar] [nvarchar](max) NULL,
	[OperatingHoursPerWeek] [decimal](10, 2) NULL,
PRIMARY KEY CLUSTERED 
(
	[ScheduleID] ASC
)WITH (PAD_INDEX = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
CREATE TABLE [silver].[Status](
	[StatusID] [bigint] IDENTITY(1,1) NOT NULL,
	[StatusCode] [nvarchar](max) NULL,
	[StatusDescription] [nvarchar](max) NULL,
PRIMARY KEY CLUSTERED 
(
	[StatusID] ASC
)WITH (PAD_INDEX = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [gold].[FactHealthCenterSchedule] ADD  DEFAULT ((1)) FOR [ScheduleCount]
GO
ALTER TABLE [gold].[FactHealthCenterSite] ADD  DEFAULT ((1)) FOR [SiteCount]
GO
ALTER TABLE [gold].[FactHealthCenterSchedule]  WITH CHECK ADD  CONSTRAINT [FK_FactSchedule_Date] FOREIGN KEY([DateID])
REFERENCES [gold].[DimDate] ([DateID])
GO
ALTER TABLE [gold].[FactHealthCenterSchedule] CHECK CONSTRAINT [FK_FactSchedule_Date]
GO
ALTER TABLE [gold].[FactHealthCenterSchedule]  WITH CHECK ADD  CONSTRAINT [FK_FactSchedule_HealthCenter] FOREIGN KEY([HealthCenterID])
REFERENCES [gold].[DimHealthCenter] ([HealthCenterID])
GO
ALTER TABLE [gold].[FactHealthCenterSchedule] CHECK CONSTRAINT [FK_FactSchedule_HealthCenter]
GO
ALTER TABLE [gold].[FactHealthCenterSchedule]  WITH CHECK ADD  CONSTRAINT [FK_FactSchedule_Location] FOREIGN KEY([LocationID])
REFERENCES [gold].[DimLocation] ([LocationID])
GO
ALTER TABLE [gold].[FactHealthCenterSchedule] CHECK CONSTRAINT [FK_FactSchedule_Location]
GO
ALTER TABLE [gold].[FactHealthCenterSchedule]  WITH CHECK ADD  CONSTRAINT [FK_FactSchedule_Schedule] FOREIGN KEY([ScheduleID])
REFERENCES [gold].[DimSchedule] ([ScheduleID])
GO
ALTER TABLE [gold].[FactHealthCenterSchedule] CHECK CONSTRAINT [FK_FactSchedule_Schedule]
GO
ALTER TABLE [gold].[FactHealthCenterSchedule]  WITH CHECK ADD  CONSTRAINT [FK_FactSchedule_Status] FOREIGN KEY([StatusID])
REFERENCES [gold].[DimStatus] ([StatusID])
GO
ALTER TABLE [gold].[FactHealthCenterSchedule] CHECK CONSTRAINT [FK_FactSchedule_Status]
GO
ALTER TABLE [gold].[FactHealthCenterSite]  WITH CHECK ADD  CONSTRAINT [FK_FactSite_Date] FOREIGN KEY([DateID])
REFERENCES [gold].[DimDate] ([DateID])
GO
ALTER TABLE [gold].[FactHealthCenterSite] CHECK CONSTRAINT [FK_FactSite_Date]
GO
ALTER TABLE [gold].[FactHealthCenterSite]  WITH CHECK ADD  CONSTRAINT [FK_FactSite_HealthCenter] FOREIGN KEY([HealthCenterID])
REFERENCES [gold].[DimHealthCenter] ([HealthCenterID])
GO
ALTER TABLE [gold].[FactHealthCenterSite] CHECK CONSTRAINT [FK_FactSite_HealthCenter]
GO
ALTER TABLE [gold].[FactHealthCenterSite]  WITH CHECK ADD  CONSTRAINT [FK_FactSite_Location] FOREIGN KEY([LocationID])
REFERENCES [gold].[DimLocation] ([LocationID])
GO
ALTER TABLE [gold].[FactHealthCenterSite] CHECK CONSTRAINT [FK_FactSite_Location]
GO
ALTER TABLE [gold].[FactHealthCenterSite]  WITH CHECK ADD  CONSTRAINT [FK_FactSite_Schedule] FOREIGN KEY([ScheduleID])
REFERENCES [gold].[DimSchedule] ([ScheduleID])
GO
ALTER TABLE [gold].[FactHealthCenterSite] CHECK CONSTRAINT [FK_FactSite_Schedule]
GO
ALTER TABLE [gold].[FactHealthCenterSite]  WITH CHECK ADD  CONSTRAINT [FK_FactSite_Status] FOREIGN KEY([StatusID])
REFERENCES [gold].[DimStatus] ([StatusID])
GO
ALTER TABLE [gold].[FactHealthCenterSite] CHECK CONSTRAINT [FK_FactSite_Status]
GO
ALTER TABLE [silver].[HealthCenterSite]  WITH CHECK ADD  CONSTRAINT [FK_Site_Date] FOREIGN KEY([DateID])
REFERENCES [silver].[Date] ([DateID])
GO
ALTER TABLE [silver].[HealthCenterSite] CHECK CONSTRAINT [FK_Site_Date]
GO
ALTER TABLE [silver].[HealthCenterSite]  WITH CHECK ADD  CONSTRAINT [FK_Site_HealthCenter] FOREIGN KEY([HealthCenterID])
REFERENCES [silver].[HealthCenter] ([HealthCenterID])
GO
ALTER TABLE [silver].[HealthCenterSite] CHECK CONSTRAINT [FK_Site_HealthCenter]
GO
ALTER TABLE [silver].[HealthCenterSite]  WITH CHECK ADD  CONSTRAINT [FK_Site_Location] FOREIGN KEY([LocationID])
REFERENCES [silver].[Location] ([LocationID])
GO
ALTER TABLE [silver].[HealthCenterSite] CHECK CONSTRAINT [FK_Site_Location]
GO
ALTER TABLE [silver].[HealthCenterSite]  WITH CHECK ADD  CONSTRAINT [FK_Site_Schedule] FOREIGN KEY([ScheduleID])
REFERENCES [silver].[Schedule] ([ScheduleID])
GO
ALTER TABLE [silver].[HealthCenterSite] CHECK CONSTRAINT [FK_Site_Schedule]
GO
ALTER TABLE [silver].[HealthCenterSite]  WITH CHECK ADD  CONSTRAINT [FK_Site_Status] FOREIGN KEY([StatusID])
REFERENCES [silver].[Status] ([StatusID])
GO
ALTER TABLE [silver].[HealthCenterSite] CHECK CONSTRAINT [FK_Site_Status]
GO
CREATE   PROCEDURE [bronze].[load_bronze]
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        -- 1. Reload staging from CSV
        TRUNCATE TABLE bronze.health_center_service_staging;
        BULK INSERT bronze.health_center_service_staging
        FROM 'C:\path\Health_Center_Service.csv'
        WITH (FORMAT = 'CSV', FIRSTROW = 2, FIELDQUOTE = '"', CODEPAGE = '65001', ROWTERMINATOR = '0x0a', TABLOCK, KEEPNULLS);
        -- 2. Validate staging
        -- 3. Reload Bronze target
        BEGIN TRANSACTION;
        TRUNCATE TABLE bronze.health_center_service;
        INSERT INTO bronze.health_center_service (
            [Health Center Type],
            [Health Center Number],
            [BHCMIS Organization Identification Number],
            [BPHC Assigned Number],
            [Site Name],
            [Site Address],
            [Site City],
            [Site State Abbreviation],
            [Site Postal Code],
            [Site Telephone Number],
            [Site Web Address],
            [Operating Hours per Week],
            [Health Center Location Setting Identification Number],
            [Health Center Service Delivery Site Location Setting Description],
            [Health Center Status Identification Number],
            [Site Status Description],
            [FQHC Site Medicare Billing Number],
            [FQHC Site NPI Number],
            [Health Center Location Identification Number],
            [Health Center Location Type Description],
            [Health Center Type Identification Number],
            [Health Center Type Description],
            [Health Center Operator Identification Number],
            [Health Center Operator Description],
            [Health Center Operating Schedule Identification Number],
            [Health Center Operational Schedule Description],
            [Health Center Operating Calendar Surrogate Key],
            [Health Center Operating Calendar],
            [Site Added to Scope this Date],
            [Health Center Name],
            [Health Center Organization Street Address],
            [Health Center Organization City],
            [Health Center Organization State],
            [Health Center Organization ZIP Code],
            [Grantee Organization Type Description],
            [Geocoding Artifact Address Primary X Coordinate],
            [Geocoding Artifact Address Primary Y Coordinate],
            [U.S. - Mexico Border 100 Kilometer Indicator],
            [U.S. - Mexico Border County Indicator],
            [State and County Federal Information Processing Standard Code],
            [Complete County Name],
            [County Equivalent Name],
            [County Description],
            [HHS Region Code],
            [HHS Region Name],
            [State FIPS Code],
            [State Name],
            [State FIPS and Congressional District Number Code],
            [Congressional District Number],
            [Congressional District Name],
            [Congressional District Code],
            [U.S. Congressional Representative Name],
            [Name of U.S. Senator Number One],
            [Name of U.S. Senator Number Two],
            [Data Warehouse Record Create Date]
        )
        SELECT
            [Health Center Type],
            [Health Center Number],
            [BHCMIS Organization Identification Number],
            [BPHC Assigned Number],
            [Site Name],
            [Site Address],
            [Site City],
            [Site State Abbreviation],
            [Site Postal Code],
            [Site Telephone Number],
            [Site Web Address],
            [Operating Hours per Week],
            [Health Center Location Setting Identification Number],
            [Health Center Service Delivery Site Location Setting Description],
            [Health Center Status Identification Number],
            [Site Status Description],
            [FQHC Site Medicare Billing Number],
            [FQHC Site NPI Number],
            [Health Center Location Identification Number],
            [Health Center Location Type Description],
            [Health Center Type Identification Number],
            [Health Center Type Description],
            [Health Center Operator Identification Number],
            [Health Center Operator Description],
            [Health Center Operating Schedule Identification Number],
            [Health Center Operational Schedule Description],
            [Health Center Operating Calendar Surrogate Key],
            [Health Center Operating Calendar],
            [Site Added to Scope this Date],
            [Health Center Name],
            [Health Center Organization Street Address],
            [Health Center Organization City],
            [Health Center Organization State],
            [Health Center Organization ZIP Code],
            [Grantee Organization Type Description],
            [Geocoding Artifact Address Primary X Coordinate],
            [Geocoding Artifact Address Primary Y Coordinate],
            [U.S. - Mexico Border 100 Kilometer Indicator],
            [U.S. - Mexico Border County Indicator],
            [State and County Federal Information Processing Standard Code],
            [Complete County Name],
            [County Equivalent Name],
            [County Description],
            [HHS Region Code],
            [HHS Region Name],
            [State FIPS Code],
            [State Name],
            [State FIPS and Congressional District Number Code],
            [Congressional District Number],
            [Congressional District Name],
            [Congressional District Code],
            [U.S. Congressional Representative Name],
            [Name of U.S. Senator Number One],
            [Name of U.S. Senator Number Two],
            [Data Warehouse Record Create Date]
        FROM bronze.health_center_service_staging;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO
CREATE   PROCEDURE [silver].[load_silver]
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        SELECT bronze_row_id AS SourceRowID,
            NULLIF(LTRIM(RTRIM([Health Center Number])), '') AS HealthCenterNumber
        INTO #Source
        FROM bronze.health_center_service;
        DELETE FROM silver.HealthCenterSite;
        DELETE FROM silver.[Date];
        DELETE FROM silver.Schedule;
        DELETE FROM silver.Status;
        DELETE FROM silver.Location;
        DELETE FROM silver.HealthCenter;
        INSERT INTO silver.HealthCenter (HealthCenterNumber) SELECT DISTINCT HealthCenterNumber FROM #Source;
        INSERT INTO silver.Location (SiteAddress) SELECT DISTINCT SiteAddress FROM #Source;
        INSERT INTO silver.Status(StatusCode, StatusDescription) SELECT DISTINCT StatusCode, StatusDescription FROM #Source;
        INSERT INTO silver.Schedule (OperatingScheduleID) SELECT DISTINCT OperatingScheduleID FROM #Source;
        INSERT INTO silver.[Date] (DateID, FullDate) SELECT DISTINCT 1, FullDate FROM #Source;
        INSERT INTO silver.HealthCenterSite (SourceRowID, HealthCenterID, LocationID, StatusID, ScheduleID, DateID)
        SELECT src.SourceRowID, hc.HealthCenterID, loc.LocationID, st.StatusID, sch.ScheduleID, dt.DateID
        FROM #Source src
        JOIN silver.HealthCenter hc ON hc.HealthCenterNumber = src.HealthCenterNumber
        JOIN silver.Location loc ON loc.SiteAddress = src.SiteAddress
        LEFT JOIN silver.Status st ON st.StatusCode = src.StatusCode
        LEFT JOIN silver.Schedule sch ON sch.OperatingScheduleID = src.OperatingScheduleID
        LEFT JOIN silver.[Date] dt ON dt.FullDate = src.FullDate;
        IF (SELECT COUNT_BIG(*) FROM silver.HealthCenterSite) <> (SELECT COUNT_BIG(*) FROM bronze.health_center_service)
            THROW 50002, 'Silver row count does not match Bronze row count.', 1;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO
CREATE   PROCEDURE [gold].[load_gold]
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        DELETE FROM gold.FactHealthCenterSchedule;
        DELETE FROM gold.FactHealthCenterSite;
        DELETE FROM gold.DimDate;
        DELETE FROM gold.DimSchedule;
        DELETE FROM gold.DimStatus;
        DELETE FROM gold.DimLocation;
        DELETE FROM gold.DimHealthCenter;
        SET IDENTITY_INSERT gold.DimHealthCenter ON;
        INSERT INTO gold.DimHealthCenter (HealthCenterID, HealthCenterNumber) SELECT HealthCenterID, HealthCenterNumber FROM silver.HealthCenter;
        SET IDENTITY_INSERT gold.DimHealthCenter OFF;
        SET IDENTITY_INSERT gold.DimLocation ON;
        INSERT INTO gold.DimLocation (LocationID, SiteAddress) SELECT LocationID, SiteAddress FROM silver.Location;
        SET IDENTITY_INSERT gold.DimLocation OFF;
        SET IDENTITY_INSERT gold.DimStatus ON;
        INSERT INTO gold.DimStatus (StatusID, StatusCode, StatusDescription) SELECT StatusID, StatusCode, StatusDescription FROM silver.Status;
        SET IDENTITY_INSERT gold.DimStatus OFF;
        SET IDENTITY_INSERT gold.DimSchedule ON;
        INSERT INTO gold.DimSchedule (ScheduleID, OperatingScheduleID) SELECT ScheduleID, OperatingScheduleID FROM silver.Schedule;
        SET IDENTITY_INSERT gold.DimSchedule OFF;
        INSERT INTO gold.DimDate (DateID, FullDate) SELECT DateID, FullDate FROM silver.[Date];
        INSERT INTO gold.FactHealthCenterSite (SourceRowID, HealthCenterID, LocationID, StatusID, ScheduleID, DateID, SiteCount)
        SELECT SourceRowID, HealthCenterID, LocationID, StatusID, ScheduleID, DateID, 1 FROM silver.HealthCenterSite;
        INSERT INTO gold.FactHealthCenterSchedule (SourceRowID, HealthCenterID, LocationID, StatusID, ScheduleID, DateID, OperatingHoursPerWeek, ScheduleCount)
        SELECT hs.SourceRowID, hs.HealthCenterID, hs.LocationID, hs.StatusID, hs.ScheduleID, hs.DateID, sch.OperatingHoursPerWeek, 1
        FROM silver.HealthCenterSite AS hs
        INNER JOIN silver.Schedule AS sch ON sch.ScheduleID = hs.ScheduleID;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO
