<?php

namespace App\Http\Controllers;

use App\Services\GoldDataService;
use App\Services\SchemaRepository;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;

class SchemaController extends Controller
{
    public function __construct(private SchemaRepository $repo, private GoldDataService $gold)
    {
    }

    public function overview()
    {
        $schema = $this->repo->get();

        return view('overview', ['schema' => $schema]);
    }

    public function diagram()
    {
        return view('diagram', ['schema' => $this->repo->get()]);
    }

    public function charts()
    {
        return view('charts', ['schema' => $this->repo->get()]);
    }

    public function data()
    {
        return view('data', ['schema' => $this->repo->get(), 'result' => $this->gold->summary()]);
    }

    public function dataApi()
    {
        return response()->json($this->gold->summary());
    }

    public function pipeline()
    {
        return view('pipeline', ['schema' => $this->repo->get()]);
    }

    public function table(string $schemaName, string $name)
    {
        $schema = $this->repo->get();
        $table = $this->findTable($schema, "{$schemaName}.{$name}");
        abort_if($table === null, 404);

        $sample = $table['layer'] === 'gold' ? $this->gold->sample($table['name']) : null;

        return view('table', ['schema' => $schema, 'table' => $table, 'sample' => $sample]);
    }

    public function procedure(string $schemaName, string $name)
    {
        $schema = $this->repo->get();
        foreach ($schema['procedures'] as $p) {
            if (strcasecmp($p['full'], "{$schemaName}.{$name}") === 0) {
                return view('procedure', ['schema' => $schema, 'proc' => $p]);
            }
        }
        abort(404);
    }

    public function api()
    {
        $schema = $this->repo->get();
        foreach ($schema['procedures'] as &$p) {
            unset($p['sql']);
        }
        unset($p);

        return response()->json($schema);
    }

    public function upload(Request $request): RedirectResponse
    {
        $request->validate(['script' => ['required', 'file', 'max:10240']]);

        try {
            $this->repo->store($request->file('script')->get());
        } catch (\Throwable $e) {
            return redirect()->route('overview')->withErrors(['script' => $e->getMessage()]);
        }

        return redirect()->route('overview')->with('status', 'Schema script loaded.');
    }

    public function reset(): RedirectResponse
    {
        $this->repo->reset();

        return redirect()->route('overview')->with('status', 'Switched back to the bundled script.');
    }

    private function findTable(array $schema, string $full): ?array
    {
        foreach ($schema['tables'] as $t) {
            if (strcasecmp($t['full'], $full) === 0) {
                return $t;
            }
        }

        return null;
    }
}
