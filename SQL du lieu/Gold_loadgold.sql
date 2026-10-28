
USE Healthcare_location;
GO

CREATE OR ALTER PROCEDURE gold.load_gold
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- 1. Xoa du lieu cu theo thu tu Fact -> Dimension
        DELETE FROM gold.FactHealthCenterSchedule;
        DELETE FROM gold.FactHealthCenterSite;

        DELETE FROM gold.DimDate;
        DELETE FROM gold.DimSchedule;
        DELETE FROM gold.DimStatus;
        DELETE FROM gold.DimLocation;
        DELETE FROM gold.DimHealthCenter;

        -- 2. Nap DimHealthCenter
        SET IDENTITY_INSERT gold.DimHealthCenter ON;

        INSERT INTO gold.DimHealthCenter
        (
            HealthCenterID, HealthCenterNumber, HealthCenterName,
            HealthCenterType, HealthCenterTypeDescription,
            OperatorID, OperatorDescription, OrganizationStreetAddress,
            OrganizationCity, OrganizationState, OrganizationZIPCode,
            GranteeOrganizationType
        )
        SELECT
            HealthCenterID, HealthCenterNumber, HealthCenterName,
            HealthCenterType, HealthCenterTypeDescription,
            OperatorID, OperatorDescription, OrganizationStreetAddress,
            OrganizationCity, OrganizationState, OrganizationZIPCode,
            GranteeOrganizationType
        FROM silver.HealthCenter;

        SET IDENTITY_INSERT gold.DimHealthCenter OFF;

        -- 3. Nap DimLocation
        SET IDENTITY_INSERT gold.DimLocation ON;

        INSERT INTO gold.DimLocation
        (
            LocationID, SiteAddress, SiteCity, StateAbbreviation,
            PostalCode, TelephoneNumber, WebAddress, Longitude, Latitude,
            CountyName, CountyEquivalentName, CountyDescription, CountyFIPS,
            HHSRegionCode, HHSRegionName, StateFIPSCode, StateName,
            LocationTypeDescription, LocationSettingDescription
        )
        SELECT
            LocationID, SiteAddress, SiteCity, StateAbbreviation,
            PostalCode, TelephoneNumber, WebAddress, Longitude, Latitude,
            CountyName, CountyEquivalentName, CountyDescription, CountyFIPS,
            HHSRegionCode, HHSRegionName, StateFIPSCode, StateName,
            LocationTypeDescription, LocationSettingDescription
        FROM silver.Location;

        SET IDENTITY_INSERT gold.DimLocation OFF;

        -- 4. Nap DimStatus
        SET IDENTITY_INSERT gold.DimStatus ON;

        INSERT INTO gold.DimStatus
            (StatusID, StatusCode, StatusDescription)
        SELECT
            StatusID, StatusCode, StatusDescription
        FROM silver.Status;

        SET IDENTITY_INSERT gold.DimStatus OFF;

        -- 5. Nap DimSchedule
        SET IDENTITY_INSERT gold.DimSchedule ON;

        INSERT INTO gold.DimSchedule
        (
            ScheduleID, OperatingScheduleID,
            OperationalScheduleDescription, OperatingCalendarKey,
            OperatingCalendar, OperatingHoursPerWeek
        )
        SELECT
            ScheduleID, OperatingScheduleID,
            OperationalScheduleDescription, OperatingCalendarKey,
            OperatingCalendar, OperatingHoursPerWeek
        FROM silver.Schedule;

        SET IDENTITY_INSERT gold.DimSchedule OFF;

        -- 6. Nap DimDate
        INSERT INTO gold.DimDate
            (DateID, FullDate, Day, Month, QuarterNumber, Year)
        SELECT
            DateID, FullDate, Day, Month, QuarterNumber, Year
        FROM silver.[Date];

        -- 7. Nap FactHealthCenterSite
        INSERT INTO gold.FactHealthCenterSite
        (
            SourceRowID, HealthCenterID, LocationID, StatusID,
            ScheduleID, DateID, SiteCount, SiteName,
            MedicareBillingNumber, NPINumber
        )
        SELECT
            SourceRowID, HealthCenterID, LocationID, StatusID,
            ScheduleID, DateID, 1, SiteName,
            MedicareBillingNumber, NPINumber
        FROM silver.HealthCenterSite;

        -- 8. Nap FactHealthCenterSchedule
        INSERT INTO gold.FactHealthCenterSchedule
        (
            SourceRowID, HealthCenterID, LocationID, StatusID,
            ScheduleID, DateID, OperatingHoursPerWeek, ScheduleCount
        )
        SELECT
            hs.SourceRowID,
            hs.HealthCenterID,
            hs.LocationID,
            hs.StatusID,
            hs.ScheduleID,
            hs.DateID,
            sch.OperatingHoursPerWeek,
            1
        FROM silver.HealthCenterSite AS hs
        INNER JOIN silver.Schedule AS sch
            ON sch.ScheduleID = hs.ScheduleID;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;

        -- Dam bao tat ca IDENTITY_INSERT deu duoc tat
        BEGIN TRY
            SET IDENTITY_INSERT gold.DimHealthCenter OFF;
        END TRY
        BEGIN CATCH
        END CATCH;

        BEGIN TRY
            SET IDENTITY_INSERT gold.DimLocation OFF;
        END TRY
        BEGIN CATCH
        END CATCH;

        BEGIN TRY
            SET IDENTITY_INSERT gold.DimStatus OFF;
        END TRY
        BEGIN CATCH
        END CATCH;

        BEGIN TRY
            SET IDENTITY_INSERT gold.DimSchedule OFF;
        END TRY
        BEGIN CATCH
        END CATCH;

        THROW;
    END CATCH;
END;
GO