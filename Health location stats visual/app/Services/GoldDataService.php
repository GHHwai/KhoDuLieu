<?php

namespace App\Services;

use Illuminate\Support\Facades\DB;

/**
 * Read-only aggregate queries against the gold star schema (SQL Server).
 * Only gold.* tables are ever touched.
 */
class GoldDataService
{
    /** @return array{status:string,message?:string,data?:array} */
    public function summary(): array
    {
        try {
            return ['status' => 'ok', 'data' => cache()->remember('gold.summary', 600, fn () => $this->build())];
        } catch (\Throwable $e) {
            return ['status' => 'error', 'message' => $this->shorten($e->getMessage())];
        }
    }

    /** First rows of a gold table for the table detail page. */
    public function sample(string $table, int $limit = 20): array
    {
        try {
            $rows = DB::table("gold.{$table}")->limit($limit)->get()->map(fn ($r) => (array) $r)->all();
            return ['status' => 'ok', 'rows' => $rows];
        } catch (\Throwable $e) {
            return ['status' => 'error', 'message' => $this->shorten($e->getMessage())];
        }
    }

    private function build(): array
    {
        $one = fn (string $sql) => (array) (DB::selectOne($sql) ?? []);
        $rows = fn (string $sql) => array_map(fn ($r) => (array) $r, DB::select($sql));

        $kpi = $one("
            SELECT
              (SELECT COUNT_BIG(*) FROM gold.FactHealthCenterSite)  AS sites,
              (SELECT COUNT_BIG(*) FROM gold.DimHealthCenter)       AS health_centers,
              (SELECT COUNT_BIG(*) FROM gold.DimLocation)           AS locations,
              (SELECT COUNT(DISTINCT StateAbbreviation) FROM gold.DimLocation) AS states,
              (SELECT AVG(OperatingHoursPerWeek) FROM gold.FactHealthCenterSchedule) AS avg_hours");

        return [
            'kpi' => $kpi,
            'by_state' => $rows("
                SELECT TOP 15 COALESCE(l.StateAbbreviation, 'n/a') AS label, COUNT_BIG(*) AS value
                FROM gold.FactHealthCenterSite f JOIN gold.DimLocation l ON l.LocationID = f.LocationID
                GROUP BY l.StateAbbreviation ORDER BY value DESC"),
            'by_region' => $rows("
                SELECT COALESCE(l.HHSRegionName, 'n/a') AS label, COUNT_BIG(*) AS value
                FROM gold.FactHealthCenterSite f JOIN gold.DimLocation l ON l.LocationID = f.LocationID
                GROUP BY l.HHSRegionName ORDER BY value DESC"),
            'by_status' => $rows("
                SELECT COALESCE(s.StatusDescription, 'n/a') AS label, COUNT_BIG(*) AS value
                FROM gold.FactHealthCenterSite f LEFT JOIN gold.DimStatus s ON s.StatusID = f.StatusID
                GROUP BY s.StatusDescription ORDER BY value DESC"),
            'by_type' => $rows("
                SELECT COALESCE(h.HealthCenterTypeDescription, 'n/a') AS label, COUNT_BIG(*) AS value
                FROM gold.FactHealthCenterSite f JOIN gold.DimHealthCenter h ON h.HealthCenterID = f.HealthCenterID
                GROUP BY h.HealthCenterTypeDescription ORDER BY value DESC"),
            'by_setting' => $rows("
                SELECT TOP 10 COALESCE(l.LocationSettingDescription, 'n/a') AS label, COUNT_BIG(*) AS value
                FROM gold.FactHealthCenterSite f JOIN gold.DimLocation l ON l.LocationID = f.LocationID
                GROUP BY l.LocationSettingDescription ORDER BY value DESC"),
            'hours' => $rows("
                SELECT CASE WHEN OperatingHoursPerWeek IS NULL THEN 'unknown'
                            WHEN OperatingHoursPerWeek < 20 THEN '< 20'
                            WHEN OperatingHoursPerWeek < 40 THEN '20-39'
                            WHEN OperatingHoursPerWeek < 60 THEN '40-59'
                            ELSE '60+' END AS label,
                       COUNT_BIG(*) AS value
                FROM gold.FactHealthCenterSchedule
                GROUP BY CASE WHEN OperatingHoursPerWeek IS NULL THEN 'unknown'
                            WHEN OperatingHoursPerWeek < 20 THEN '< 20'
                            WHEN OperatingHoursPerWeek < 40 THEN '20-39'
                            WHEN OperatingHoursPerWeek < 60 THEN '40-59'
                            ELSE '60+' END"),
            'by_year' => $rows("
                SELECT CAST(d.[Year] AS varchar(4)) AS label, COUNT_BIG(*) AS value
                FROM gold.FactHealthCenterSite f JOIN gold.DimDate d ON d.DateID = f.DateID
                GROUP BY d.[Year] ORDER BY d.[Year]"),
            // Longitude/latitude sample for the scatter map
            'points' => $rows("
                SELECT TOP 4000 CAST(Longitude AS float) AS x, CAST(Latitude AS float) AS y
                FROM gold.DimLocation
                WHERE Longitude IS NOT NULL AND Latitude IS NOT NULL
                  AND Longitude BETWEEN -180 AND -60 AND Latitude BETWEEN 15 AND 72
                ORDER BY NEWID()"),
        ];
    }

    private function shorten(string $m): string
    {
        $m = preg_replace('/\s+/', ' ', $m);
        return mb_strlen($m) > 300 ? mb_substr($m, 0, 300) . '…' : $m;
    }
}
