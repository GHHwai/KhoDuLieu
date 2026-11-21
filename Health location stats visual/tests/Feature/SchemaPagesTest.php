<?php

namespace Tests\Feature;

use Tests\TestCase;

class SchemaPagesTest extends TestCase
{
    public function test_pages_render(): void
    {
        foreach (['/', '/diagram', '/pipeline', '/charts', '/data', '/finder', '/finder?q=20001', '/finder?q=nonsense', '/tables/gold/DimDate', '/procedures/gold/load_gold', '/api/schema'] as $url) {
            $this->get($url)->assertOk();
        }
    }

    public function test_unknown_table_is_404(): void
    {
        $this->get('/tables/gold/Nope')->assertNotFound();
    }
}
