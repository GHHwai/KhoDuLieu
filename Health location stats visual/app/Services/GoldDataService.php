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
            return ['status' => 'ok', 'data' => cache()->remember('gold.summary.v5', 600, fn () => $this->build())];
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
              (SELECT COUNT(DISTINCT LEFT(HealthCenterNumber, 50)) FROM gold.DimHealthCenter) AS health_centers,
              (SELECT COUNT_BIG(*) FROM gold.DimHealthCenter)       AS health_center_rows,
              (SELECT COUNT_BIG(*) FROM gold.DimLocation)           AS locations,
              (SELECT COUNT(DISTINCT StateAbbreviation) FROM gold.DimLocation) AS states,
              (SELECT AVG(OperatingHoursPerWeek) FROM gold.FactHealthCenterSchedule) AS avg_hours");

        $data = [
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
            'hospital_by_state' => $rows("
                SELECT TOP 15 UPPER(LTRIM(RTRIM(l.StateAbbreviation))) AS label, COUNT_BIG(*) AS value
                FROM gold.FactHealthCenterSite f JOIN gold.DimLocation l ON l.LocationID = f.LocationID
                WHERE l.LocationSettingDescription = 'Hospital'
                GROUP BY UPPER(LTRIM(RTRIM(l.StateAbbreviation))) ORDER BY value DESC"),
            'schedules' => $rows("
                SELECT TOP 10 x.description, x.calendar, COUNT_BIG(*) AS sites,
                       MIN(s.OperatingHoursPerWeek) AS min_hours, MAX(s.OperatingHoursPerWeek) AS max_hours
                FROM gold.FactHealthCenterSite f
                JOIN gold.DimSchedule s ON s.ScheduleID = f.ScheduleID
                CROSS APPLY (SELECT
                    LTRIM(RTRIM(REPLACE(REPLACE(CAST(s.OperationalScheduleDescription AS nvarchar(4000)), CHAR(13), ' '), CHAR(10), ' '))) AS description,
                    LTRIM(RTRIM(REPLACE(REPLACE(CAST(s.OperatingCalendar AS nvarchar(4000)), CHAR(13), ' '), CHAR(10), ' '))) AS calendar) x
                GROUP BY x.description, x.calendar
                ORDER BY sites DESC"),
            'recent' => $one("
                SELECT COUNT_BIG(*) AS recent_sites, CONVERT(varchar(10), MAX(d.FullDate), 23) AS newest
                FROM gold.FactHealthCenterSite f JOIN gold.DimDate d ON d.DateID = f.DateID
                WHERE d.FullDate >= DATEADD(YEAR, -1, (SELECT MAX(FullDate) FROM gold.DimDate))"),
            'by_state_all' => $rows("
                SELECT UPPER(LTRIM(RTRIM(l.StateAbbreviation))) AS label, COUNT_BIG(*) AS value
                FROM gold.FactHealthCenterSite f JOIN gold.DimLocation l ON l.LocationID = f.LocationID
                GROUP BY UPPER(LTRIM(RTRIM(l.StateAbbreviation)))"),
            'part_time_raw' => $rows("
                SELECT UPPER(LTRIM(RTRIM(l.StateAbbreviation))) AS label, COUNT_BIG(*) AS sites,
                       SUM(CASE WHEN s.OperatingHoursPerWeek IS NOT NULL THEN 1 ELSE 0 END) AS with_hours,
                       SUM(CASE WHEN s.OperatingHoursPerWeek < 40 THEN 1 ELSE 0 END) AS part_time
                FROM gold.FactHealthCenterSite f
                JOIN gold.DimLocation l      ON l.LocationID = f.LocationID
                LEFT JOIN gold.DimSchedule s ON s.ScheduleID = f.ScheduleID
                GROUP BY UPPER(LTRIM(RTRIM(l.StateAbbreviation)))"),
            'funnel_raw' => $one("
                SELECT
                  COUNT_BIG(*) AS all_sites,
                  SUM(CASE WHEN COALESCE(h.HealthCenterTypeDescription, '') <> 'Administrative' THEN 1 ELSE 0 END) AS patient_facing,
                  SUM(CASE WHEN COALESCE(h.HealthCenterTypeDescription, '') <> 'Administrative'
                            AND COALESCE(l.LocationSettingDescription, '') <> 'School' THEN 1 ELSE 0 END) AS non_school,
                  SUM(CASE WHEN COALESCE(h.HealthCenterTypeDescription, '') <> 'Administrative'
                            AND COALESCE(l.LocationSettingDescription, '') <> 'School'
                            AND s.OperatingHoursPerWeek >= 20 THEN 1 ELSE 0 END) AS open_20h_plus
                FROM gold.FactHealthCenterSite f
                JOIN gold.DimHealthCenter h ON h.HealthCenterID = f.HealthCenterID
                JOIN gold.DimLocation l     ON l.LocationID = f.LocationID
                LEFT JOIN gold.DimSchedule s ON s.ScheduleID = f.ScheduleID"),
        ];

        $data['per_1000'] = self::perThousand($data['by_state_all'], config('state_population', []));
        $data['part_time'] = self::partTimeShare($data['part_time_raw']);
        $data['funnel'] = self::funnel($data['funnel_raw']);
        unset($data['by_state_all'], $data['part_time_raw'], $data['funnel_raw']);

        return $data;
    }

    /** Lowest sites-per-1,000-residents first. Rows whose state has no population are skipped. */
    public static function perThousand(array $byState, array $population, int $limit = 15): array
    {
        $out = [];
        foreach ($byState as $r) {
            $pop = $population[$r['label']] ?? null;
            if ($pop) {
                $out[] = ['label' => $r['label'], 'value' => round($r['value'] / $pop * 1000, 2), 'sites' => (int) $r['value']];
            }
        }
        usort($out, fn ($a, $b) => $a['value'] <=> $b['value']);

        return array_slice($out, 0, $limit);
    }

    /** Highest share of part-time (< 40 h) sites among sites with known hours; ignores tiny states of data. */
    public static function partTimeShare(array $raw, int $minSites = 50, int $limit = 15): array
    {
        $out = [];
        foreach ($raw as $r) {
            if ((int) $r['with_hours'] >= $minSites) {
                $out[] = ['label' => $r['label'], 'value' => round($r['part_time'] / $r['with_hours'] * 100, 1), 'sites' => (int) $r['with_hours']];
            }
        }
        usort($out, fn ($a, $b) => $b['value'] <=> $a['value']);

        return array_slice($out, 0, $limit);
    }

    public static function funnel(array $f): array
    {
        return [
            ['label' => 'All active sites', 'value' => (int) ($f['all_sites'] ?? 0)],
            ['label' => 'Patient-facing sites', 'value' => (int) ($f['patient_facing'] ?? 0)],
            ['label' => 'and not school-based', 'value' => (int) ($f['non_school'] ?? 0)],
            ['label' => 'and open 20+ h/week', 'value' => (int) ($f['open_20h_plus'] ?? 0)],
        ];
    }

    private function shorten(string $m): string
    {
        $m = preg_replace('/\s+/', ' ', $m);
        return mb_strlen($m) > 300 ? mb_substr($m, 0, 300) . '…' : $m;
    }
}
