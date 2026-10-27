
USE Heathcare_location;
GO

CREATE OR ALTER PROCEDURE silver.load_silver
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        --------------------------------------------------
        -- 1. CLEAN AND TRANSFORM SOURCE DATA
        --------------------------------------------------
        IF OBJECT_ID('tempdb..#Source') IS NOT NULL
            DROP TABLE #Source;

        SELECT
            bronze_row_id AS SourceRowID,

            NULLIF(TRIM([Health Center Number]), '')
                AS HealthCenterNumber,
            NULLIF(TRIM([Health Center Name]), '')
                AS HealthCenterName,
            NULLIF(TRIM([Health Center Type]), '')
                AS HealthCenterType,
            NULLIF(TRIM([Health Center Type Description]), '')
                AS HealthCenterTypeDescription,
            NULLIF(TRIM([Health Center Operator Identification Number]), '')
                AS OperatorID,
            NULLIF(TRIM([Health Center Operator Description]), '')
                AS OperatorDescription,
            NULLIF(TRIM([Health Center Organization Street Address]), '')
                AS OrganizationStreetAddress,
            NULLIF(TRIM([Health Center Organization City]), '')
                AS OrganizationCity,
            NULLIF(TRIM([Health Center Organization State]), '')
                AS OrganizationState,
            NULLIF(TRIM([Health Center Organization ZIP Code]), '')
                AS OrganizationZIPCode,
            NULLIF(TRIM([Grantee Organization Type Description]), '')
                AS GranteeOrganizationType,

            NULLIF(TRIM([Site Name]), '') AS SiteName,
            NULLIF(TRIM([Site Address]), '') AS SiteAddress,
            NULLIF(TRIM([Site City]), '') AS SiteCity,
            NULLIF(TRIM([Site State Abbreviation]), '')
                AS StateAbbreviation,
            NULLIF(TRIM([Site Postal Code]), '') AS PostalCode,
            NULLIF(TRIM([Site Telephone Number]), '') AS TelephoneNumber,
            NULLIF(TRIM([Site Web Address]), '') AS WebAddress,

            TRY_CONVERT(DECIMAL(12,8),
                NULLIF(TRIM(
                    [Geocoding Artifact Address Primary X Coordinate]
                ), '')) AS Longitude,

            TRY_CONVERT(DECIMAL(12,8),
                NULLIF(TRIM(
                    [Geocoding Artifact Address Primary Y Coordinate]
                ), '')) AS Latitude,

            NULLIF(TRIM([Complete County Name]), '') AS CountyName,
            NULLIF(TRIM([County Equivalent Name]), '')
                AS CountyEquivalentName,
            NULLIF(TRIM([County Description]), '') AS CountyDescription,
            NULLIF(TRIM(
                [State and County Federal Information Processing Standard Code]
            ), '') AS CountyFIPS,
            NULLIF(TRIM([HHS Region Code]), '') AS HHSRegionCode,
            NULLIF(TRIM([HHS Region Name]), '') AS HHSRegionName,
            NULLIF(TRIM([State FIPS Code]), '') AS StateFIPSCode,
            NULLIF(TRIM([State Name]), '') AS StateName,
            NULLIF(TRIM([Health Center Location Type Description]), '')
                AS LocationTypeDescription,
            NULLIF(TRIM(
                [Health Center Service Delivery Site Location Setting Description]
            ), '') AS LocationSettingDescription,

            NULLIF(TRIM([Health Center Status Identification Number]), '')
                AS StatusCode,
            NULLIF(TRIM([Site Status Description]), '')
                AS StatusDescription,

            NULLIF(TRIM(
                [Health Center Operating Schedule Identification Number]
            ), '') AS OperatingScheduleID,
            NULLIF(TRIM(
                [Health Center Operational Schedule Description]
            ), '') AS OperationalScheduleDescription,
            NULLIF(TRIM(
                [Health Center Operating Calendar Surrogate Key]
            ), '') AS OperatingCalendarKey,
            NULLIF(TRIM([Health Center Operating Calendar]), '')
                AS OperatingCalendar,
            TRY_CONVERT(DECIMAL(10,2),
                NULLIF(TRIM([Operating Hours per Week]), ''))
                AS OperatingHoursPerWeek,

            TRY_CONVERT(DATE,
                NULLIF(TRIM([Site Added to Scope this Date]), ''), 101)
                AS FullDate,

            NULLIF(TRIM([FQHC Site Medicare Billing Number]), '')
                AS MedicareBillingNumber,
            NULLIF(TRIM([FQHC Site NPI Number]), '') AS NPINumber,
            NULLIF(TRIM(
                [Health Center Location Setting Identification Number]
            ), '') AS LocationSettingID,

            NULLIF(TRIM(
                [U.S. - Mexico Border 100 Kilometer Indicator]
            ), '') AS Border100KmIndicator,
            NULLIF(TRIM(
                [U.S. - Mexico Border County Indicator]
            ), '') AS BorderCountyIndicator,
            NULLIF(TRIM([Congressional District Code]), '')
                AS CongressionalDistrictCode,
            NULLIF(TRIM([Congressional District Name]), '')
                AS CongressionalDistrictName,
            NULLIF(TRIM(
                [U.S. Congressional Representative Name]
            ), '') AS CongressionalRepresentative,
            NULLIF(TRIM([Name of U.S. Senator Number One]), '')
                AS SenatorOne,
            NULLIF(TRIM([Name of U.S. Senator Number Two]), '')
                AS SenatorTwo,
            NULLIF(TRIM([Data Warehouse Record Create Date]), '')
                AS RecordCreateDate
        INTO #Source
        FROM bronze.health_center_service;

        --------------------------------------------------
        -- 2. CLEAR SILVER IN FOREIGN-KEY SAFE ORDER
        --------------------------------------------------
        DELETE FROM silver.HealthCenterSite;
        DELETE FROM silver.[Date];
        DELETE FROM silver.Schedule;
        DELETE FROM silver.Status;
        DELETE FROM silver.Location;
        DELETE FROM silver.HealthCenter;

        --------------------------------------------------
        -- 3. LOAD HEALTH CENTER
        --------------------------------------------------
        INSERT INTO silver.HealthCenter (
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
        SELECT DISTINCT
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
        FROM #Source;

        --------------------------------------------------
        -- 4. LOAD LOCATION
        --------------------------------------------------
        INSERT INTO silver.Location (
            SiteAddress, SiteCity, StateAbbreviation, PostalCode,
            TelephoneNumber, WebAddress, Longitude, Latitude,
            CountyName, CountyEquivalentName, CountyDescription,
            CountyFIPS, HHSRegionCode, HHSRegionName, StateFIPSCode,
            StateName, LocationTypeDescription, LocationSettingDescription
        )
        SELECT DISTINCT
            SiteAddress, SiteCity, StateAbbreviation, PostalCode,
            TelephoneNumber, WebAddress, Longitude, Latitude,
            CountyName, CountyEquivalentName, CountyDescription,
            CountyFIPS, HHSRegionCode, HHSRegionName, StateFIPSCode,
            StateName, LocationTypeDescription, LocationSettingDescription
        FROM #Source;

        --------------------------------------------------
        -- 5. LOAD STATUS
        --------------------------------------------------
        INSERT INTO silver.Status (StatusCode, StatusDescription)
        SELECT DISTINCT StatusCode, StatusDescription
        FROM #Source;

        --------------------------------------------------
        -- 6. LOAD SCHEDULE
        --------------------------------------------------
        INSERT INTO silver.Schedule (
            OperatingScheduleID,
            OperationalScheduleDescription,
            OperatingCalendarKey,
            OperatingCalendar,
            OperatingHoursPerWeek
        )
        SELECT DISTINCT
            OperatingScheduleID,
            OperationalScheduleDescription,
            OperatingCalendarKey,
            OperatingCalendar,
            OperatingHoursPerWeek
        FROM #Source;

        --------------------------------------------------
        -- 7. LOAD DATE
        --------------------------------------------------
        INSERT INTO silver.[Date] (
            DateID, FullDate, [Day], [Month], QuarterNumber, [Year]
        )
        SELECT DISTINCT
            CONVERT(INT, CONVERT(CHAR(8), FullDate, 112)),
            FullDate,
            DAY(FullDate),
            MONTH(FullDate),
            DATEPART(QUARTER, FullDate),
            YEAR(FullDate)
        FROM #Source
        WHERE FullDate IS NOT NULL;

        --------------------------------------------------
        -- 8. LOAD HEALTH CENTER SITE AND MAP DIMENSION IDS
        --------------------------------------------------
        INSERT INTO silver.HealthCenterSite (
            SourceRowID,
            HealthCenterID,
            LocationID,
            StatusID,
            ScheduleID,
            DateID,
            SiteName,
            MedicareBillingNumber,
            NPINumber,
            LocationSettingID,
            Border100KmIndicator,
            BorderCountyIndicator,
            CongressionalDistrictCode,
            CongressionalDistrictName,
            CongressionalRepresentative,
            SenatorOne,
            SenatorTwo,
            RecordCreateDate
        )
        SELECT
            src.SourceRowID,
            h.HealthCenterID,
            l.LocationID,
            st.StatusID,
            sc.ScheduleID,
            d.DateID,
            src.SiteName,
            src.MedicareBillingNumber,
            src.NPINumber,
            src.LocationSettingID,
            src.Border100KmIndicator,
            src.BorderCountyIndicator,
            src.CongressionalDistrictCode,
            src.CongressionalDistrictName,
            src.CongressionalRepresentative,
            src.SenatorOne,
            src.SenatorTwo,
            src.RecordCreateDate
        FROM #Source src

        JOIN silver.HealthCenter h
          ON EXISTS (
              SELECT h.HealthCenterNumber, h.HealthCenterName,
                     h.HealthCenterType, h.HealthCenterTypeDescription,
                     h.OperatorID, h.OperatorDescription,
                     h.OrganizationStreetAddress, h.OrganizationCity,
                     h.OrganizationState, h.OrganizationZIPCode,
                     h.GranteeOrganizationType
              INTERSECT
              SELECT src.HealthCenterNumber, src.HealthCenterName,
                     src.HealthCenterType, src.HealthCenterTypeDescription,
                     src.OperatorID, src.OperatorDescription,
                     src.OrganizationStreetAddress, src.OrganizationCity,
                     src.OrganizationState, src.OrganizationZIPCode,
                     src.GranteeOrganizationType
          )

        JOIN silver.Location l
          ON EXISTS (
              SELECT l.SiteAddress, l.SiteCity, l.StateAbbreviation,
                     l.PostalCode, l.TelephoneNumber, l.WebAddress,
                     l.Longitude, l.Latitude, l.CountyName,
                     l.CountyEquivalentName, l.CountyDescription,
                     l.CountyFIPS, l.HHSRegionCode, l.HHSRegionName,
                     l.StateFIPSCode, l.StateName,
                     l.LocationTypeDescription, l.LocationSettingDescription
              INTERSECT
              SELECT src.SiteAddress, src.SiteCity, src.StateAbbreviation,
                     src.PostalCode, src.TelephoneNumber, src.WebAddress,
                     src.Longitude, src.Latitude, src.CountyName,
                     src.CountyEquivalentName, src.CountyDescription,
                     src.CountyFIPS, src.HHSRegionCode, src.HHSRegionName,
                     src.StateFIPSCode, src.StateName,
                     src.LocationTypeDescription, src.LocationSettingDescription
          )

        LEFT JOIN silver.Status st
          ON EXISTS (
              SELECT st.StatusCode, st.StatusDescription
              INTERSECT
              SELECT src.StatusCode, src.StatusDescription
          )

        LEFT JOIN silver.Schedule sc
          ON EXISTS (
              SELECT sc.OperatingScheduleID,
                     sc.OperationalScheduleDescription,
                     sc.OperatingCalendarKey,
                     sc.OperatingCalendar,
                     sc.OperatingHoursPerWeek
              INTERSECT
              SELECT src.OperatingScheduleID,
                     src.OperationalScheduleDescription,
                     src.OperatingCalendarKey,
                     src.OperatingCalendar,
                     src.OperatingHoursPerWeek
          )

        LEFT JOIN silver.[Date] d
          ON d.FullDate = src.FullDate;

        --------------------------------------------------
        -- 9. RETURN LOAD SUMMARY
        --------------------------------------------------
        SELECT 'Bronze' AS LayerName,
               'health_center_service' AS TableName,
               COUNT_BIG(*) AS TotalRows
        FROM bronze.health_center_service

        UNION ALL
        SELECT 'Silver', 'HealthCenter', COUNT_BIG(*)
        FROM silver.HealthCenter

        UNION ALL
        SELECT 'Silver', 'Location', COUNT_BIG(*)
        FROM silver.Location

        UNION ALL
        SELECT 'Silver', 'Status', COUNT_BIG(*)
        FROM silver.Status

        UNION ALL
        SELECT 'Silver', 'Schedule', COUNT_BIG(*)
        FROM silver.Schedule

        UNION ALL
        SELECT 'Silver', 'Date', COUNT_BIG(*)
        FROM silver.[Date]

        UNION ALL
        SELECT 'Silver', 'HealthCenterSite', COUNT_BIG(*)
        FROM silver.HealthCenterSite;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH;
END;
GO

EXEC silver.load_silver;
GO
