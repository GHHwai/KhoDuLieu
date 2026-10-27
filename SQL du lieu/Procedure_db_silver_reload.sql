USE Heathcare_location;
GO

CREATE OR ALTER PROCEDURE silver.load_silver
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF OBJECT_ID('tempdb..#Source') IS NOT NULL
            DROP TABLE #Source;

        SELECT
            bronze_row_id AS SourceRowID,
            NULLIF(LTRIM(RTRIM([Health Center Number])), '') AS HealthCenterNumber,
            NULLIF(LTRIM(RTRIM([Health Center Name])), '') AS HealthCenterName,
            NULLIF(LTRIM(RTRIM([Health Center Type])), '') AS HealthCenterType,
            NULLIF(LTRIM(RTRIM([Health Center Type Description])), '') AS HealthCenterTypeDescription,
            NULLIF(LTRIM(RTRIM([Health Center Operator Identification Number])), '') AS OperatorID,
            NULLIF(LTRIM(RTRIM([Health Center Operator Description])), '') AS OperatorDescription,
            NULLIF(LTRIM(RTRIM([Health Center Organization Street Address])), '') AS OrganizationStreetAddress,
            NULLIF(LTRIM(RTRIM([Health Center Organization City])), '') AS OrganizationCity,
            NULLIF(LTRIM(RTRIM([Health Center Organization State])), '') AS OrganizationState,
            NULLIF(LTRIM(RTRIM([Health Center Organization ZIP Code])), '') AS OrganizationZIPCode,
            NULLIF(LTRIM(RTRIM([Grantee Organization Type Description])), '') AS GranteeOrganizationType,

            NULLIF(LTRIM(RTRIM([Site Address])), '') AS SiteAddress,
            NULLIF(LTRIM(RTRIM([Site City])), '') AS SiteCity,
            NULLIF(LTRIM(RTRIM([Site State Abbreviation])), '') AS StateAbbreviation,
            NULLIF(LTRIM(RTRIM([Site Postal Code])), '') AS PostalCode,
            NULLIF(LTRIM(RTRIM([Site Telephone Number])), '') AS TelephoneNumber,
            NULLIF(LTRIM(RTRIM([Site Web Address])), '') AS WebAddress,
            TRY_CONVERT(DECIMAL(12,8), NULLIF(LTRIM(RTRIM([Geocoding Artifact Address Primary X Coordinate])), '')) AS Longitude,
            TRY_CONVERT(DECIMAL(12,8), NULLIF(LTRIM(RTRIM([Geocoding Artifact Address Primary Y Coordinate])), '')) AS Latitude,
            NULLIF(LTRIM(RTRIM([Complete County Name])), '') AS CountyName,
            NULLIF(LTRIM(RTRIM([County Equivalent Name])), '') AS CountyEquivalentName,
            NULLIF(LTRIM(RTRIM([County Description])), '') AS CountyDescription,
            NULLIF(LTRIM(RTRIM([State and County Federal Information Processing Standard Code])), '') AS CountyFIPS,
            NULLIF(LTRIM(RTRIM([HHS Region Code])), '') AS HHSRegionCode,
            NULLIF(LTRIM(RTRIM([HHS Region Name])), '') AS HHSRegionName,
            NULLIF(LTRIM(RTRIM([State FIPS Code])), '') AS StateFIPSCode,
            NULLIF(LTRIM(RTRIM([State Name])), '') AS StateName,
            NULLIF(LTRIM(RTRIM([Health Center Location Type Description])), '') AS LocationTypeDescription,
            NULLIF(LTRIM(RTRIM([Health Center Service Delivery Site Location Setting Description])), '') AS LocationSettingDescription,

            NULLIF(LTRIM(RTRIM([Health Center Status Identification Number])), '') AS StatusCode,
            NULLIF(LTRIM(RTRIM([Site Status Description])), '') AS StatusDescription,

            NULLIF(LTRIM(RTRIM([Health Center Operating Schedule Identification Number])), '') AS OperatingScheduleID,
            NULLIF(LTRIM(RTRIM([Health Center Operational Schedule Description])), '') AS OperationalScheduleDescription,
            NULLIF(LTRIM(RTRIM([Health Center Operating Calendar Surrogate Key])), '') AS OperatingCalendarKey,
            NULLIF(LTRIM(RTRIM([Health Center Operating Calendar])), '') AS OperatingCalendar,
            TRY_CONVERT(DECIMAL(10,2), NULLIF(LTRIM(RTRIM([Operating Hours per Week])), '')) AS OperatingHoursPerWeek,

            TRY_CONVERT(DATE, NULLIF(LTRIM(RTRIM([Site Added to Scope this Date])), ''), 101) AS FullDate,

            NULLIF(LTRIM(RTRIM([Site Name])), '') AS SiteName,
            NULLIF(LTRIM(RTRIM([FQHC Site Medicare Billing Number])), '') AS MedicareBillingNumber,
            NULLIF(LTRIM(RTRIM([FQHC Site NPI Number])), '') AS NPINumber,
            NULLIF(LTRIM(RTRIM([Health Center Location Setting Identification Number])), '') AS LocationSettingID,
            NULLIF(LTRIM(RTRIM([U.S. - Mexico Border 100 Kilometer Indicator])), '') AS Border100KmIndicator,
            NULLIF(LTRIM(RTRIM([U.S. - Mexico Border County Indicator])), '') AS BorderCountyIndicator,
            NULLIF(LTRIM(RTRIM([Congressional District Code])), '') AS CongressionalDistrictCode,
            NULLIF(LTRIM(RTRIM([Congressional District Name])), '') AS CongressionalDistrictName,
            NULLIF(LTRIM(RTRIM([U.S. Congressional Representative Name])), '') AS CongressionalRepresentative,
            NULLIF(LTRIM(RTRIM([Name of U.S. Senator Number One])), '') AS SenatorOne,
            NULLIF(LTRIM(RTRIM([Name of U.S. Senator Number Two])), '') AS SenatorTwo,
            NULLIF(LTRIM(RTRIM([Data Warehouse Record Create Date])), '') AS RecordCreateDate
        INTO #Source
        FROM bronze.health_center_service;

        CREATE UNIQUE CLUSTERED INDEX IX_Source_SourceRowID
            ON #Source(SourceRowID);

        DELETE FROM silver.HealthCenterSite;
        DELETE FROM silver.[Date];
        DELETE FROM silver.Schedule;
        DELETE FROM silver.Status;
        DELETE FROM silver.Location;
        DELETE FROM silver.HealthCenter;

        INSERT INTO silver.HealthCenter
        (
            HealthCenterNumber, HealthCenterName, HealthCenterType,
            HealthCenterTypeDescription, OperatorID, OperatorDescription,
            OrganizationStreetAddress, OrganizationCity, OrganizationState,
            OrganizationZIPCode, GranteeOrganizationType
        )
        SELECT DISTINCT
            HealthCenterNumber, HealthCenterName, HealthCenterType,
            HealthCenterTypeDescription, OperatorID, OperatorDescription,
            OrganizationStreetAddress, OrganizationCity, OrganizationState,
            OrganizationZIPCode, GranteeOrganizationType
        FROM #Source;

        INSERT INTO silver.Location
        (
            SiteAddress, SiteCity, StateAbbreviation, PostalCode,
            TelephoneNumber, WebAddress, Longitude, Latitude,
            CountyName, CountyEquivalentName, CountyDescription, CountyFIPS,
            HHSRegionCode, HHSRegionName, StateFIPSCode, StateName,
            LocationTypeDescription, LocationSettingDescription
        )
        SELECT DISTINCT
            SiteAddress, SiteCity, StateAbbreviation, PostalCode,
            TelephoneNumber, WebAddress, Longitude, Latitude,
            CountyName, CountyEquivalentName, CountyDescription, CountyFIPS,
            HHSRegionCode, HHSRegionName, StateFIPSCode, StateName,
            LocationTypeDescription, LocationSettingDescription
        FROM #Source;

        INSERT INTO silver.Status(StatusCode, StatusDescription)
        SELECT DISTINCT StatusCode, StatusDescription
        FROM #Source
        WHERE StatusCode IS NOT NULL
           OR StatusDescription IS NOT NULL;

        INSERT INTO silver.Schedule
        (
            OperatingScheduleID, OperationalScheduleDescription,
            OperatingCalendarKey, OperatingCalendar, OperatingHoursPerWeek
        )
        SELECT DISTINCT
            OperatingScheduleID, OperationalScheduleDescription,
            OperatingCalendarKey, OperatingCalendar, OperatingHoursPerWeek
        FROM #Source
        WHERE OperatingScheduleID IS NOT NULL
           OR OperationalScheduleDescription IS NOT NULL
           OR OperatingCalendarKey IS NOT NULL
           OR OperatingCalendar IS NOT NULL
           OR OperatingHoursPerWeek IS NOT NULL;

        INSERT INTO silver.[Date]
        (
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

        INSERT INTO silver.HealthCenterSite
        (
            SourceRowID, HealthCenterID, LocationID, StatusID,
            ScheduleID, DateID, SiteName, MedicareBillingNumber,
            NPINumber, LocationSettingID, Border100KmIndicator,
            BorderCountyIndicator, CongressionalDistrictCode,
            CongressionalDistrictName, CongressionalRepresentative,
            SenatorOne, SenatorTwo, RecordCreateDate
        )
        SELECT
            src.SourceRowID,
            hc.HealthCenterID,
            loc.LocationID,
            st.StatusID,
            sch.ScheduleID,
            dt.DateID,
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
        JOIN silver.HealthCenter hc
          ON hc.HealthCenterNumber IS NOT DISTINCT FROM src.HealthCenterNumber
         AND hc.HealthCenterName IS NOT DISTINCT FROM src.HealthCenterName
         AND hc.HealthCenterType IS NOT DISTINCT FROM src.HealthCenterType
         AND hc.HealthCenterTypeDescription IS NOT DISTINCT FROM src.HealthCenterTypeDescription
         AND hc.OperatorID IS NOT DISTINCT FROM src.OperatorID
         AND hc.OperatorDescription IS NOT DISTINCT FROM src.OperatorDescription
         AND hc.OrganizationStreetAddress IS NOT DISTINCT FROM src.OrganizationStreetAddress
         AND hc.OrganizationCity IS NOT DISTINCT FROM src.OrganizationCity
         AND hc.OrganizationState IS NOT DISTINCT FROM src.OrganizationState
         AND hc.OrganizationZIPCode IS NOT DISTINCT FROM src.OrganizationZIPCode
         AND hc.GranteeOrganizationType IS NOT DISTINCT FROM src.GranteeOrganizationType
        JOIN silver.Location loc
          ON loc.SiteAddress IS NOT DISTINCT FROM src.SiteAddress
         AND loc.SiteCity IS NOT DISTINCT FROM src.SiteCity
         AND loc.StateAbbreviation IS NOT DISTINCT FROM src.StateAbbreviation
         AND loc.PostalCode IS NOT DISTINCT FROM src.PostalCode
         AND loc.TelephoneNumber IS NOT DISTINCT FROM src.TelephoneNumber
         AND loc.WebAddress IS NOT DISTINCT FROM src.WebAddress
         AND loc.Longitude IS NOT DISTINCT FROM src.Longitude
         AND loc.Latitude IS NOT DISTINCT FROM src.Latitude
         AND loc.CountyName IS NOT DISTINCT FROM src.CountyName
         AND loc.CountyEquivalentName IS NOT DISTINCT FROM src.CountyEquivalentName
         AND loc.CountyDescription IS NOT DISTINCT FROM src.CountyDescription
         AND loc.CountyFIPS IS NOT DISTINCT FROM src.CountyFIPS
         AND loc.HHSRegionCode IS NOT DISTINCT FROM src.HHSRegionCode
         AND loc.HHSRegionName IS NOT DISTINCT FROM src.HHSRegionName
         AND loc.StateFIPSCode IS NOT DISTINCT FROM src.StateFIPSCode
         AND loc.StateName IS NOT DISTINCT FROM src.StateName
         AND loc.LocationTypeDescription IS NOT DISTINCT FROM src.LocationTypeDescription
         AND loc.LocationSettingDescription IS NOT DISTINCT FROM src.LocationSettingDescription
        LEFT JOIN silver.Status st
          ON st.StatusCode IS NOT DISTINCT FROM src.StatusCode
         AND st.StatusDescription IS NOT DISTINCT FROM src.StatusDescription
        LEFT JOIN silver.Schedule sch
          ON sch.OperatingScheduleID IS NOT DISTINCT FROM src.OperatingScheduleID
         AND sch.OperationalScheduleDescription IS NOT DISTINCT FROM src.OperationalScheduleDescription
         AND sch.OperatingCalendarKey IS NOT DISTINCT FROM src.OperatingCalendarKey
         AND sch.OperatingCalendar IS NOT DISTINCT FROM src.OperatingCalendar
         AND sch.OperatingHoursPerWeek IS NOT DISTINCT FROM src.OperatingHoursPerWeek
        LEFT JOIN silver.[Date] dt
          ON dt.FullDate = src.FullDate;

        IF EXISTS
        (
            SELECT SourceRowID
            FROM silver.HealthCenterSite
            GROUP BY SourceRowID
            HAVING COUNT_BIG(*) > 1
        )
            THROW 50001, 'Duplicate SourceRowID detected in HealthCenterSite.', 1;

        IF (SELECT COUNT_BIG(*) FROM silver.HealthCenterSite)
           <> (SELECT COUNT_BIG(*) FROM bronze.health_center_service)
            THROW 50002, 'Silver row count does not match Bronze row count. Transaction rolled back.', 1;

        COMMIT TRANSACTION;

        SELECT
            'HealthCenter' AS TableName, COUNT_BIG(*) AS TotalRows
        FROM silver.HealthCenter
        UNION ALL
        SELECT 'Location', COUNT_BIG(*) FROM silver.Location
        UNION ALL
        SELECT 'Status', COUNT_BIG(*) FROM silver.Status
        UNION ALL
        SELECT 'Schedule', COUNT_BIG(*) FROM silver.Schedule
        UNION ALL
        SELECT 'Date', COUNT_BIG(*) FROM silver.[Date]
        UNION ALL
        SELECT 'HealthCenterSite', COUNT_BIG(*) FROM silver.HealthCenterSite;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH
END;
GO