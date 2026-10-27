USE Heathcare_location;
GO

CREATE OR ALTER PROCEDURE bronze.load_bronze
AS
BEGIN

    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @StagingRows BIGINT;
    DECLARE @RowsInserted BIGINT;

    BEGIN TRY
        PRINT '========================================';
        PRINT 'START BRONZE DATA LOAD';
        PRINT '========================================';

        -- 1. Reload staging from CSV
        PRINT 'Step 1: Loading CSV into staging...';

        TRUNCATE TABLE bronze.health_center_service_staging;

        BULK INSERT bronze.health_center_service_staging
        FROM 'D:\data store\Health_Center_Service.csv'
        WITH (
            FORMAT = 'CSV',
            FIRSTROW = 2,
            FIELDQUOTE = '"',
            CODEPAGE = '65001',
            ROWTERMINATOR = '0x0a',
            TABLOCK,
            KEEPNULLS
        );

        -- 2. Validate staging
        SELECT @StagingRows = COUNT_BIG(*)
        FROM bronze.health_center_service_staging;

        PRINT CONCAT('Staging rows: ', @StagingRows);

        IF @StagingRows = 0
            THROW 50001, 'Staging is empty. Bronze load cancelled.', 1;

        -- 3. Reload Bronze target
        PRINT 'Step 2: Loading staging into Bronze...';

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

        SET @RowsInserted = @@ROWCOUNT;

        COMMIT TRANSACTION;

        -- 4. Validate final row counts
        PRINT 'Step 3: Validating load...';

        SELECT
            @StagingRows AS StagingRows,
            @RowsInserted AS RowsInserted,
            (SELECT COUNT_BIG(*)
             FROM bronze.health_center_service) AS BronzeRows;

        PRINT 'BRONZE DATA LOAD COMPLETED SUCCESSFULLY.';
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();

        PRINT 'BRONZE DATA LOAD FAILED.';
        PRINT @ErrorMessage;

        THROW;
    END CATCH;
END;
GO
