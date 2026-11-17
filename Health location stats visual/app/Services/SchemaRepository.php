<?php

namespace App\Services;

/**
 * Locates the active schema script (an uploaded one wins over the bundled
 * sample) and returns its parsed form, cached per file modification time.
 */
class SchemaRepository
{
    public function __construct(private SchemaParser $parser)
    {
    }

    public function bundledPath(): string
    {
        return resource_path('sql/schemascript.sql');
    }

    public function uploadedPath(): string
    {
        return storage_path('app/schemascript.sql');
    }

    public function activePath(): string
    {
        return is_file($this->uploadedPath()) ? $this->uploadedPath() : $this->bundledPath();
    }

    public function isUploaded(): bool
    {
        return is_file($this->uploadedPath());
    }

    public function get(): array
    {
        $path = $this->activePath();
        $key = 'schema.parsed.' . md5($path . '|' . filemtime($path) . '|' . filesize($path));

        $schema = cache()->remember($key, 3600, fn () => $this->parser->parseFile($path));
        $schema['source'] = [
            'file' => $this->isUploaded() ? 'uploaded script' : 'resources/sql/schemascript.sql',
            'uploaded' => $this->isUploaded(),
        ];

        return $schema;
    }

    public function store(string $contents): void
    {
        // Validate before replacing the active script.
        $parsed = $this->parser->parse($contents);
        if ($parsed['stats']['tables'] === 0) {
            throw new \InvalidArgumentException('No CREATE TABLE statements were found in that file.');
        }

        @mkdir(dirname($this->uploadedPath()), 0775, true);
        file_put_contents($this->uploadedPath(), $contents);
    }

    public function reset(): void
    {
        if ($this->isUploaded()) {
            unlink($this->uploadedPath());
        }
    }
}
