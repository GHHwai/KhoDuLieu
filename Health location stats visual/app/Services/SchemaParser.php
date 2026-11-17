<?php

namespace App\Services;

/**
 * Parses a SQL Server (SSMS "Generate Scripts") schema script into a plain
 * array describing schemas, tables, columns, keys, relationships and
 * stored-procedure data flow. No database connection is needed.
 *
 * Intentionally dependency-free so it can run under plain PHP.
 */
class SchemaParser
{
    public function parseFile(string $path): array
    {
        $sql = file_get_contents($path);
        if ($sql === false) {
            throw new \RuntimeException("Cannot read schema script: {$path}");
        }

        return $this->parse($sql);
    }

    public function parse(string $sql): array
    {
        // Normalise encoding (SSMS often saves UTF-16 / BOM) and line endings.
        $sql = $this->normaliseEncoding($sql);
        $sql = str_replace(["\r\n", "\r"], "\n", $sql);

        $batches = preg_split('/^[ \t]*GO[ \t]*(?:\d+)?[ \t]*$/mi', $sql) ?: [];

        $database = null;
        $schemas = [];
        $tables = [];
        $fks = [];
        $defaults = [];
        $procedures = [];

        foreach ($batches as $batch) {
            $trim = trim($batch);
            if ($trim === '') {
                continue;
            }
            $clean = $this->stripComments($trim);

            if ($database === null && preg_match('/^\s*USE\s+\[([^\]]+)\]/mi', $clean, $m) && strcasecmp($m[1], 'master') !== 0) {
                $database = $m[1];
            }

            if (preg_match('/CREATE\s+SCHEMA\s+\[([^\]]+)\]/i', $clean, $m)) {
                $schemas[] = $m[1];
                continue;
            }

            if (preg_match('/CREATE\s+TABLE\s+\[([^\]]+)\]\.\[([^\]]+)\]\s*\(/i', $clean, $m, PREG_OFFSET_CAPTURE)) {
                $open = $m[0][1] + strlen($m[0][0]) - 1;
                $body = $this->matchParens($clean, $open);
                $tables[] = $this->parseTable($m[1][0], $m[2][0], $body);
                continue;
            }

            if (preg_match('/CREATE\s+(?:OR\s+ALTER\s+)?PROC(?:EDURE)?\s+\[([^\]]+)\]\.\[([^\]]+)\]/i', $clean, $m)) {
                $procedures[] = ['schema' => $m[1], 'name' => $m[2], 'raw' => $trim, 'clean' => $clean];
                continue;
            }

            if (preg_match(
                '/ALTER\s+TABLE\s+\[([^\]]+)\]\.\[([^\]]+)\]\s+(?:WITH\s+(?:NO)?CHECK\s+)?ADD\s+CONSTRAINT\s+\[([^\]]+)\]\s+FOREIGN\s+KEY\s*\(([^)]*)\)\s*REFERENCES\s+\[([^\]]+)\]\.\[([^\]]+)\]\s*\(([^)]*)\)/is',
                $clean,
                $m
            )) {
                $fks[] = [
                    'name' => $m[3],
                    'table' => "{$m[1]}.{$m[2]}",
                    'columns' => $this->identList($m[4]),
                    'ref_table' => "{$m[5]}.{$m[6]}",
                    'ref_columns' => $this->identList($m[7]),
                ];
                continue;
            }

            if (preg_match(
                '/ALTER\s+TABLE\s+\[([^\]]+)\]\.\[([^\]]+)\]\s+ADD\s+(?:CONSTRAINT\s+\[[^\]]+\]\s+)?DEFAULT\s+(.+?)\s+FOR\s+\[([^\]]+)\]/is',
                $clean,
                $m
            )) {
                $defaults[] = ['table' => "{$m[1]}.{$m[2]}", 'column' => $m[4], 'value' => trim($m[3])];
            }
        }

        $byFull = [];
        foreach ($tables as $i => $t) {
            $byFull[strtolower($t['full'])] = $i;
        }

        foreach ($defaults as $d) {
            $i = $byFull[strtolower($d['table'])] ?? null;
            if ($i === null) {
                continue;
            }
            foreach ($tables[$i]['columns'] as &$col) {
                if (strcasecmp($col['name'], $d['column']) === 0) {
                    $col['default'] = $this->unwrapParens($d['value']);
                }
            }
            unset($col);
        }

        $relationships = [];
        foreach ($fks as $fk) {
            $i = $byFull[strtolower($fk['table'])] ?? null;
            if ($i !== null) {
                $tables[$i]['foreign_keys'][] = $fk;
                foreach ($tables[$i]['columns'] as &$col) {
                    if (in_array($col['name'], $fk['columns'], true)) {
                        $col['fk'] = true;
                    }
                }
                unset($col);
            }
            $relationships[] = $fk;
        }

        // Which tables are referenced by others.
        foreach ($relationships as $fk) {
            $j = $byFull[strtolower($fk['ref_table'])] ?? null;
            if ($j !== null) {
                $tables[$j]['referenced_by'][] = ['table' => $fk['table'], 'name' => $fk['name']];
            }
        }

        $knownTables = array_column($tables, 'full');
        $procs = array_map(fn ($p) => $this->analyseProcedure($p, $knownTables), $procedures);

        $lineage = $this->buildLineage($procs);

        foreach ($tables as &$t) {
            $t['loaded_by'] = [];
            $t['read_by'] = [];
            foreach ($procs as $p) {
                if (in_array($t['full'], $p['writes'], true)) {
                    $t['loaded_by'][] = $p['full'];
                }
                if (in_array($t['full'], $p['reads'], true)) {
                    $t['read_by'][] = $p['full'];
                }
            }
        }
        unset($t);

        $schemas = array_values(array_unique(array_merge($schemas, array_column($tables, 'schema'))));
        $layerOrder = ['bronze' => 1, 'silver' => 2, 'gold' => 3];
        usort($schemas, fn ($a, $b) => ($layerOrder[strtolower($a)] ?? 9) <=> ($layerOrder[strtolower($b)] ?? 9) ?: strcmp($a, $b));

        return [
            'database' => $database ?? 'Unknown',
            'schemas' => $schemas,
            'tables' => $tables,
            'relationships' => $relationships,
            'procedures' => $procs,
            'lineage' => $lineage,
            'stats' => $this->stats($schemas, $tables, $relationships, $procs),
        ];
    }

    // ---------------------------------------------------------------- tables

    private function parseTable(string $schema, string $name, string $body): array
    {
        $columns = [];
        $pk = [];
        $uniques = [];
        $pkName = null;

        foreach ($this->splitTopLevel($body) as $item) {
            $item = trim($item);
            if ($item === '') {
                continue;
            }

            if (preg_match('/^(?:CONSTRAINT\s+\[([^\]]+)\]\s+)?(PRIMARY\s+KEY|UNIQUE)\b/i', $item, $m)) {
                if (preg_match('/(?:PRIMARY\s+KEY|UNIQUE)\s*(?:CLUSTERED|NONCLUSTERED)?\s*\(([^)]*)\)/is', $item, $c)) {
                    $cols = $this->identList($c[1]);
                    if (stripos($m[2], 'PRIMARY') === 0) {
                        $pk = $cols;
                        $pkName = $m[1] !== '' ? $m[1] : null;
                    } else {
                        $uniques[] = ['name' => $m[1] !== '' ? $m[1] : null, 'columns' => $cols];
                    }
                }
                continue;
            }

            if (preg_match('/^\[([^\]]+)\]\s+\[([^\]]+)\]\s*(?:\(([^)]*)\))?(.*)$/is', $item, $m)) {
                $rest = $m[4];
                $columns[] = [
                    'name' => $m[1],
                    'type' => $m[2],
                    'size' => $m[3] !== '' ? trim($m[3]) : null,
                    'type_full' => $m[2] . ($m[3] !== '' ? '(' . trim($m[3]) . ')' : ''),
                    'nullable' => !preg_match('/\bNOT\s+NULL\b/i', $rest),
                    'identity' => (bool) preg_match('/\bIDENTITY\b/i', $rest),
                    'pk' => false,
                    'fk' => false,
                    'unique' => false,
                    'default' => null,
                ];
            }
        }

        foreach ($columns as &$col) {
            $col['pk'] = in_array($col['name'], $pk, true);
            foreach ($uniques as $u) {
                if (in_array($col['name'], $u['columns'], true)) {
                    $col['unique'] = true;
                }
            }
        }
        unset($col);

        return [
            'schema' => $schema,
            'name' => $name,
            'full' => "{$schema}.{$name}",
            'layer' => strtolower($schema),
            'kind' => $this->kind($schema, $name),
            'columns' => $columns,
            'primary_key' => $pk,
            'primary_key_name' => $pkName,
            'uniques' => $uniques,
            'foreign_keys' => [],
            'referenced_by' => [],
        ];
    }

    private function kind(string $schema, string $name): string
    {
        $s = strtolower($schema);
        if ($s === 'gold') {
            if (preg_match('/^fact/i', $name)) {
                return 'fact';
            }
            if (preg_match('/^dim/i', $name)) {
                return 'dimension';
            }
            return 'gold';
        }
        if ($s === 'bronze') {
            return preg_match('/staging$/i', $name) ? 'staging' : 'raw';
        }
        return $s === 'silver' ? 'cleaned' : 'table';
    }

    // ------------------------------------------------------------ procedures

    private function analyseProcedure(array $p, array $knownTables): array
    {
        $text = $this->blankStrings($p['clean']);
        $full = "{$p['schema']}.{$p['name']}";

        $known = [];
        foreach ($knownTables as $k) {
            $known[strtolower($k)] = $k;
        }
        $ident = '\[?([A-Za-z_][\w]*)\]?\s*\.\s*(?:\[([^\]]+)\]|([A-Za-z_]\w*))';
        $resolve = function (array $m) use ($known) {
            $schema = $m[1][0];
            $tbl = ($m[2][0] ?? '') !== '' ? $m[2][0] : ($m[3][0] ?? '');
            return $known[strtolower("{$schema}.{$tbl}")] ?? null;
        };

        $writes = [];
        $ops = [];
        $add = function (string $op, string $pattern) use ($text, $ident, $resolve, &$writes, &$ops) {
            if (preg_match_all('/' . str_replace('{I}', $ident, $pattern) . '/i', $text, $mm, PREG_SET_ORDER | PREG_OFFSET_CAPTURE)) {
                foreach ($mm as $m) {
                    $t = $resolve($m);
                    if ($t) {
                        $writes[$t] = true;
                        $ops[$t][$op] = true;
                    }
                }
            }
        };
        $add('INSERT', '(?<!BULK )\bINSERT\s+(?:INTO\s+)?{I}');
        $add('DELETE', '\bDELETE\s+(?:FROM\s+)?{I}');
        $add('TRUNCATE', '\bTRUNCATE\s+TABLE\s+{I}');
        $add('BULK INSERT', '\bBULK\s+INSERT\s+{I}');
        $reads = [];
        if (preg_match_all('/\b(?:FROM|JOIN)\s+' . $ident . '/i', $text, $mm, PREG_SET_ORDER | PREG_OFFSET_CAPTURE)) {
            foreach ($mm as $m) {
                $pos = $m[0][1];
                if (preg_match('/\bDELETE\s+$/i', substr($text, max(0, $pos - 12), 12))) {
                    continue; // DELETE FROM x is a write, not a read
                }
                $t = $resolve($m);
                if ($t) {
                    $reads[$t] = true;
                }
            }
        }

        // INSERT ... SELECT FROM same table (read & write) is rare; keep both.
        $steps = [];
        if (preg_match_all('/^[ \t]*--[ \t]*(.+)$/m', $p['raw'], $cm)) {
            foreach ($cm[1] as $c) {
                $c = trim($c);
                if ($c !== '') {
                    $steps[] = $c;
                }
            }
        }

        $bulkFile = null;
        if (preg_match("/BULK\s+INSERT\s+[^\n]+\s+FROM\s+'([^']+)'/is", $p['raw'], $bf)) {
            $bulkFile = str_replace('\\', '/', $bf[1]);
            $bulkFile = basename($bulkFile);
        }

        $writesList = array_keys($writes);
        $readsList = array_keys($reads);

        return [
            'schema' => $p['schema'],
            'name' => $p['name'],
            'full' => $full,
            'reads' => $readsList,
            'writes' => $writesList,
            'operations' => array_map('array_keys', $ops),
            'steps' => $steps,
            'source_file' => $bulkFile,
            'uses_transaction' => (bool) preg_match('/\bBEGIN\s+TRAN(?:SACTION)?\b/i', $text),
            'uses_try_catch' => (bool) preg_match('/\bBEGIN\s+TRY\b/i', $text),
            'line_count' => substr_count($p['raw'], "\n") + 1,
            'sql' => $p['raw'],
        ];
    }

    private function buildLineage(array $procs): array
    {
        $edges = [];
        foreach ($procs as $p) {
            foreach ($p['reads'] as $r) {
                // Lookups against a table the procedure also fills (joins on
                // freshly-loaded silver tables) are not upstream sources.
                if (in_array($r, $p['writes'], true)) {
                    continue;
                }
                $edges[] = ['from' => $r, 'to' => $p['full'], 'type' => 'read'];
            }
            foreach ($p['writes'] as $w) {
                $edges[] = ['from' => $p['full'], 'to' => $w, 'type' => 'write'];
            }
        }
        return $edges;
    }

    private function stats(array $schemas, array $tables, array $rels, array $procs): array
    {
        $byLayer = [];
        foreach ($tables as $t) {
            $byLayer[$t['schema']]['tables'] = ($byLayer[$t['schema']]['tables'] ?? 0) + 1;
            $byLayer[$t['schema']]['columns'] = ($byLayer[$t['schema']]['columns'] ?? 0) + count($t['columns']);
        }
        return [
            'schemas' => count($schemas),
            'tables' => count($tables),
            'columns' => array_sum(array_map(fn ($t) => count($t['columns']), $tables)),
            'relationships' => count($rels),
            'procedures' => count($procs),
            'by_layer' => $byLayer,
            'facts' => count(array_filter($tables, fn ($t) => $t['kind'] === 'fact')),
            'dimensions' => count(array_filter($tables, fn ($t) => $t['kind'] === 'dimension')),
        ];
    }

    // --------------------------------------------------------------- helpers

    private function normaliseEncoding(string $s): string
    {
        if (str_starts_with($s, "\xFF\xFE")) {
            return mb_convert_encoding(substr($s, 2), 'UTF-8', 'UTF-16LE');
        }
        if (str_starts_with($s, "\xFE\xFF")) {
            return mb_convert_encoding(substr($s, 2), 'UTF-8', 'UTF-16BE');
        }
        if (str_starts_with($s, "\xEF\xBB\xBF")) {
            return substr($s, 3);
        }
        return $s;
    }

    /** Remove -- and block comments while leaving quoted strings intact. */
    private function stripComments(string $sql): string
    {
        $out = '';
        $len = strlen($sql);
        $i = 0;
        while ($i < $len) {
            $c = $sql[$i];
            $n = $sql[$i + 1] ?? '';
            if ($c === "'") {
                $j = $i + 1;
                while ($j < $len) {
                    if ($sql[$j] === "'") {
                        if (($sql[$j + 1] ?? '') === "'") {
                            $j += 2;
                            continue;
                        }
                        break;
                    }
                    $j++;
                }
                $out .= substr($sql, $i, $j - $i + 1);
                $i = $j + 1;
            } elseif ($c === '-' && $n === '-') {
                while ($i < $len && $sql[$i] !== "\n") {
                    $i++;
                }
            } elseif ($c === '/' && $n === '*') {
                $end = strpos($sql, '*/', $i + 2);
                $i = $end === false ? $len : $end + 2;
                $out .= ' ';
            } else {
                $out .= $c;
                $i++;
            }
        }
        return $out;
    }

    /** Replace the content of '...' literals so keywords inside them are ignored. */
    private function blankStrings(string $sql): string
    {
        return preg_replace_callback("/'(?:[^']|'')*'/s", fn ($m) => "''", $sql);
    }

    /** Return the text inside the parenthesis starting at $open (bracket-aware). */
    private function matchParens(string $s, int $open): string
    {
        $depth = 0;
        $inBracket = false;
        $len = strlen($s);
        for ($i = $open; $i < $len; $i++) {
            $c = $s[$i];
            if ($inBracket) {
                if ($c === ']') {
                    $inBracket = false;
                }
                continue;
            }
            if ($c === '[') {
                $inBracket = true;
            } elseif ($c === '(') {
                $depth++;
            } elseif ($c === ')') {
                $depth--;
                if ($depth === 0) {
                    return substr($s, $open + 1, $i - $open - 1);
                }
            }
        }
        return substr($s, $open + 1);
    }

    private function splitTopLevel(string $s): array
    {
        $parts = [];
        $depth = 0;
        $inBracket = false;
        $buf = '';
        $len = strlen($s);
        for ($i = 0; $i < $len; $i++) {
            $c = $s[$i];
            if ($inBracket) {
                $buf .= $c;
                if ($c === ']') {
                    $inBracket = false;
                }
                continue;
            }
            if ($c === '[') {
                $inBracket = true;
            } elseif ($c === '(') {
                $depth++;
            } elseif ($c === ')') {
                $depth--;
            } elseif ($c === ',' && $depth === 0) {
                $parts[] = $buf;
                $buf = '';
                continue;
            }
            $buf .= $c;
        }
        if (trim($buf) !== '') {
            $parts[] = $buf;
        }
        return $parts;
    }

    private function identList(string $s): array
    {
        $out = [];
        foreach (explode(',', $s) as $p) {
            if (preg_match('/\[([^\]]+)\]/', $p, $m)) {
                $out[] = $m[1];
            }
        }
        return $out;
    }

    private function unwrapParens(string $v): string
    {
        $v = trim($v);
        while (strlen($v) > 1 && $v[0] === '(' && substr($v, -1) === ')') {
            $v = trim(substr($v, 1, -1));
        }
        return $v;
    }
}
