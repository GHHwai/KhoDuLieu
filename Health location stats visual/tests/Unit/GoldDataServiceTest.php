<?php

namespace Tests\Unit;

use App\Services\GoldDataService;
use PHPUnit\Framework\TestCase;

class GoldDataServiceTest extends TestCase
{
    public function test_per_thousand_sorts_lowest_first_and_skips_unknown_states(): void
    {
        $rows = [
            ['label' => 'AA', 'value' => 500],   // 5 per 1,000
            ['label' => 'BB', 'value' => 100],   // 0.5 per 1,000
            ['label' => 'ZZ', 'value' => 999],   // no population given
        ];
        $out = GoldDataService::perThousand($rows, ['AA' => 100000, 'BB' => 200000]);

        $this->assertSame(['BB', 'AA'], array_column($out, 'label'));
        $this->assertSame(0.5, $out[0]['value']);
    }

    public function test_part_time_share_ignores_small_samples(): void
    {
        $raw = [
            ['label' => 'AA', 'sites' => 200, 'with_hours' => 100, 'part_time' => 40],
            ['label' => 'BB', 'sites' => 10, 'with_hours' => 10, 'part_time' => 10],
        ];
        $out = GoldDataService::partTimeShare($raw, 50);

        $this->assertCount(1, $out);
        $this->assertSame(40.0, $out[0]['value']);
    }

    public function test_funnel_has_four_stages(): void
    {
        $out = GoldDataService::funnel(['all_sites' => 10, 'patient_facing' => 8, 'non_school' => 6, 'open_20h_plus' => 5]);
        $this->assertSame([10, 8, 6, 5], array_column($out, 'value'));
    }
}
