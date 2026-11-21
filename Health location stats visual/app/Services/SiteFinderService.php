<?php

namespace App\Services;

use Illuminate\Support\Facades\DB;

/**
 * "Closest site" search over the gold star schema (read-only).
 * Distance is great-circle miles from a latitude/longitude, with a bounding box
 * that widens until enough rows are found.
 */
class SiteFinderService
{
    /** Approximate centre of a ZIP, averaged from the sites already located in it. */
    public function geocodeZip(string $zip): ?array
    {
        $row = DB::selectOne(
            'SELECT AVG(CAST(Latitude AS float)) AS lat, AVG(CAST(Longitude AS float)) AS lon, COUNT_BIG(*) AS n
             FROM gold.DimLocation
             WHERE LEFT(PostalCode, 5) = ?
               AND Latitude BETWEEN -90 AND 90 AND Longitude BETWEEN -180 AND 180',
            [substr($zip, 0, 5)]
        );

        if (! $row || (int) $row->n === 0 || $row->lat === null) {
            return null;
        }

        return ['lat' => (float) $row->lat, 'lon' => (float) $row->lon, 'sites_in_zip' => (int) $row->n];
    }

    /**
     * @param array{limit?:int, exclude_admin?:bool, exclude_school?:bool, hospital_only?:bool} $opt
     */
    public function nearest(float $lat, float $lon, array $opt = []): array
    {
        $limit = max(1, min(50, (int) ($opt['limit'] ?? 10)));
        $where = '';
        if (! empty($opt['exclude_admin'])) {
            $where .= " AND COALESCE(h.HealthCenterTypeDescription, '') <> 'Administrative'";
        }
        if (! empty($opt['exclude_school'])) {
            $where .= " AND COALESCE(l.LocationSettingDescription, '') <> 'School'";
        }
        if (! empty($opt['hospital_only'])) {
            $where .= " AND l.LocationSettingDescription = 'Hospital'";
        }

        // Safe to inline: both are PHP floats formatted as plain decimals.
        $la = number_format($lat, 8, '.', '');
        $lo = number_format($lon, 8, '.', '');

        $rows = [];
        foreach ([1.0, 3.0, 8.0, 25.0, 90.0] as $dLat) {
            $dLon = min(180.0, $dLat / max(0.2, cos(deg2rad($lat))));
            $sql = "
                SELECT TOP {$limit}
                       f.SiteName AS name, l.SiteAddress AS address, l.SiteCity AS city,
                       l.StateAbbreviation AS state, l.PostalCode AS zip, l.TelephoneNumber AS phone,
                       l.WebAddress AS web, l.LocationSettingDescription AS setting,
                       h.HealthCenterTypeDescription AS type, s.OperatingHoursPerWeek AS hours,
                       CAST(l.Latitude AS float) AS lat, CAST(l.Longitude AS float) AS lon, d.FullDate AS added,
                       3959.0 * ACOS(LEAST(1.0,
                           COS(RADIANS({$la})) * COS(RADIANS(l.Latitude)) * COS(RADIANS(l.Longitude) - RADIANS({$lo}))
                         + SIN(RADIANS({$la})) * SIN(RADIANS(l.Latitude)))) AS miles
                FROM gold.FactHealthCenterSite f
                JOIN gold.DimLocation l      ON l.LocationID = f.LocationID
                JOIN gold.DimHealthCenter h  ON h.HealthCenterID = f.HealthCenterID
                LEFT JOIN gold.DimSchedule s ON s.ScheduleID = f.ScheduleID
                LEFT JOIN gold.DimDate d     ON d.DateID = f.DateID
                WHERE l.Latitude  BETWEEN {$la} - {$dLat} AND {$la} + {$dLat}
                  AND l.Longitude BETWEEN {$lo} - {$dLon} AND {$lo} + {$dLon}
                  {$where}
                ORDER BY miles";

            $rows = array_map(fn ($r) => (array) $r, DB::select($sql));
            if (count($rows) >= $limit) {
                break;
            }
        }

        // "New" = added within a year of the newest site in the data (not of today's date).
        $newest = DB::selectOne('SELECT MAX(FullDate) AS d FROM gold.DimDate');
        $cutoff = ($newest && $newest->d) ? strtotime($newest->d . ' -1 year') : null;

        foreach ($rows as &$r) {
            $r['is_new'] = $cutoff !== null && ! empty($r['added']) && strtotime((string) $r['added']) >= $cutoff;
            $r['miles'] = round((float) $r['miles'], 1);
            $r['hours'] = $r['hours'] === null ? null : (float) $r['hours'];
        }

        return $rows;
    }
}
