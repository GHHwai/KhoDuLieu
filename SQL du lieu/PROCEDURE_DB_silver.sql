USE Heathcare_location;
GO

-- Kiểm tra các bảng Bronze, Silver, Gold
SELECT
    s.name AS SchemaName,
    t.name AS TableName
FROM sys.tables AS t
JOIN sys.schemas AS s
    ON t.schema_id = s.schema_id
WHERE s.name IN ('bronze', 'silver', 'gold')
ORDER BY s.name, t.name;
GO