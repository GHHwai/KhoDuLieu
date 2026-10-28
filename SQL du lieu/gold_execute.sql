
USE Heathcare_location;
GO

CREATE OR ALTER PROCEDURE gold.load_gold
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @ExpectedSiteRows BIGINT;
    DECLARE @ExpectedScheduleRows BIGINT;
    DECLARE @ActualSiteRows BIGINT;
    DECLARE @ActualScheduleRows BIGINT;

    BEGIN TRY
        BEGIN TRANSACTION;

        SELECT @ExpectedSiteRows = COUNT_BIG(*)
        FROM silver.HealthCenterSite;

        SELECT @ExpectedScheduleRows = COUNT_BIG(*)
        FROM silver.HealthCenterSite s
        INNER JOIN silver.Schedule sch
            ON sch.ScheduleID = s.ScheduleID;

        DELETE FROM gold.FactHealthCenterSchedule;
        DELETE FROM gold.FactHealthCenterSite;

        DELETE FROM gold.DimDate;
        DELETE FROM gold.DimSchedule;
        DELETE FROM gold.DimStatus;
        DELETE FROM gold.DimLocation;
        DELETE FROM gold.DimHealthCenter;

        SET IDENTITY_INSERT gold.DimHealthCenter ON;

        INSERT INTO gold.DimHealthCenter (
            HealthCenterID,
            HealthCenterNumber,
            HealthCenterName,
            HealthCenterType,
            HealthCenterTypeDescription,
            OperatorID,
            OperatorDescription,
            OrganizationStreetAddress,
            OrganizationCity,
            OrganizationState,
            OrganizationZIPCode,
            GranteeOrganizationType
        )
        SELECT
            HealthCenterID,
            HealthCenterNumber,
            HealthCenterName,
            HealthCenterType,
            HealthCenterTypeDescription,
            OperatorID,
            OperatorDescription,
            OrganizationStreetAddress,
            OrganizationCity,
            OrganizationState,
            OrganizationZIPCode,
            GranteeOrganizationType
        FROM silver.HealthCenter;

        SET IDENTITY_INSERT gold.DimHealthCenter OFF;

        SET IDENTITY_INSERT gold.DimLocation ON;

        INSERT INTO gold.DimLocation (
            LocationID,
            SiteAddress,
            SiteCity,
            StateAbbreviation,
            PostalCode,
            TelephoneNumber,
            WebAddress,
            Longitude,
            Latitude,
            CountyName,
            CountyEquivalentName,
            CountyDescription,
            CountyFIPS,
            HHSRegionCode,
            HHSRegionName,
            StateFIPSCode,
            StateName,
            LocationTypeDescription,
            LocationSettingDescription
        )
        SELECT
            LocationID,
            SiteAddress,
            SiteCity,
            StateAbbreviation,
            PostalCode,
            TelephoneNumber,
            WebAddress,
            Longitude,
            Latitude,
            CountyName,
            CountyEquivalentName,
            CountyDescription,
            CountyFIPS,
            HHSRegionCode,
            HHSRegionName,
            StateFIPSCode,
            StateName,
            LocationTypeDescription,
            LocationSettingDescription
        FROM silver.Location;

        SET IDENTITY_INSERT gold.DimLocation OFF;

        SET IDENTITY_INSERT gold.DimStatus ON;

        INSERT INTO gold.DimStatus (
            StatusID,
            StatusCode,
            StatusDescription
        )
        SELECT
            StatusID,
            StatusCode,
            StatusDescription
        FROM silver.Status;

        SET IDENTITY_INSERT gold.DimStatus OFF;

        SET IDENTITY_INSERT gold.DimSchedule ON;

        INSERT INTO gold.DimSchedule (
            ScheduleID,
            OperatingScheduleID,
            OperationalScheduleDescription,
            OperatingCalendarKey,
            OperatingCalendar,
            OperatingHoursPerWeek
        )
        SELECT
            ScheduleID,
            OperatingScheduleID,
            OperationalScheduleDescription,
            OperatingCalendarKey,
            OperatingCalendar,
            OperatingHoursPerWeek
        FROM silver.Schedule;

        SET IDENTITY_INSERT gold.DimSchedule OFF;

        INSERT INTO gold.DimDate (
            DateID,
            FullDate,
            Day,
            Month,
            QuarterNumber,
            Year
        )
        SELECT
            DateID,
            FullDate,
            Day,
            Month,
            QuarterNumber,
            Year
        FROM silver.[Date];

        INSERT INTO gold.FactHealthCenterSite (
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

        INSERT INTO gold.FactHealthCenterSchedule (
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
            s.SourceRowID,
            s.HealthCenterID,
            s.LocationID,
            s.StatusID,
            s.ScheduleID,
            s.DateID,
            sch.OperatingHoursPerWeek,
            1
        FROM silver.HealthCenterSite s
        INNER JOIN silver.Schedule sch
            ON sch.ScheduleID = s.ScheduleID;

        SELECT @ActualSiteRows = COUNT_BIG(*)
        FROM gold.FactHealthCenterSite;

        SELECT @ActualScheduleRows = COUNT_BIG(*)
        FROM gold.FactHealthCenterSchedule;

        IF @ActualSiteRows <> @ExpectedSiteRows
            THROW 50001, 'FactHealthCenterSite row count mismatch.', 1;

        IF @ActualScheduleRows <> @ExpectedScheduleRows
            THROW 50002, 'FactHealthCenterSchedule row count mismatch.', 1;

        COMMIT TRANSACTION;

        SELECT
            'SUCCESS' AS ReloadStatus,
            @ActualSiteRows AS FactHealthCenterSiteRows,
            @ActualScheduleRows AS FactHealthCenterScheduleRows;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH;
END;
GO
