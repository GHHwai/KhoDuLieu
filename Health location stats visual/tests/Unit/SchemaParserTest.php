<?php

namespace Tests\Unit;

use App\Services\SchemaParser;
use PHPUnit\Framework\TestCase;

class SchemaParserTest extends TestCase
{
    private function schema(): array
    {
        return (new SchemaParser())->parseFile(__DIR__ . '/../../resources/sql/schemascript.sql');
    }

    public function test_parses_tables_and_layers(): void
    {
        $s = $this->schema();
        $this->assertSame('Healthcare_location', $s['database']);
        $this->assertSame(['bronze', 'silver', 'gold'], $s['schemas']);
        $this->assertSame(15, $s['stats']['tables']);
        $this->assertSame(2, $s['stats']['facts']);
        $this->assertSame(5, $s['stats']['dimensions']);
    }

    public function test_parses_keys_and_relationships(): void
    {
        $s = $this->schema();
        $this->assertCount(15, $s['relationships']);
        $fact = array_values(array_filter($s["tables"], fn ($t) => $t["full"] === 'gold.FactHealthCenterSite'))[0];
        $this->assertSame(['FactSiteKey'], $fact['primary_key']);
        $this->assertCount(5, $fact['foreign_keys']);
    }

    public function test_procedure_lineage(): void
    {
        $s = $this->schema();
        $gold = array_values(array_filter($s["procedures"], fn ($p) => $p["full"] === 'gold.load_gold'))[0];
        $this->assertContains('silver.Schedule', $gold['reads']);
        $this->assertContains('gold.FactHealthCenterSite', $gold['writes']);
    }
}
