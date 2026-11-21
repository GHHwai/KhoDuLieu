<?php

namespace App\Http\Controllers;

use App\Services\GoldDataService;
use App\Services\SchemaRepository;
use App\Services\SiteFinderService;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;

class SchemaController extends Controller
{
    public function __construct(private SchemaRepository $repo, private GoldDataService $gold, private SiteFinderService $finder)
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

    public function finder(Request $request)
    {
        $schema = $this->repo->get();
        $submitted = $request->has('q');
        $q = trim((string) $request->query('q', ''));
        $opt = [
            'limit' => (int) $request->query('limit', 10),
            'exclude_admin' => $submitted ? $request->boolean('exclude_admin') : true,
            'exclude_school' => $submitted ? $request->boolean('exclude_school') : true,
            'hospital_only' => $request->boolean('hospital_only'),
        ];
        $view = ['schema' => $schema, 'q' => $q, 'opt' => $opt, 'results' => null, 'center' => null, 'error' => null];

        if ($q === '') {
            return view('finder', $view);
        }

        try {
            if (preg_match('/^(\d{5})(-\d{4})?$/', $q, $m)) {
                $center = $this->finder->geocodeZip($m[1]);
                if ($center === null) {
                    $view['error'] = "No sites are located in ZIP {$m[1]}, so its centre is unknown. Try a nearby ZIP or enter latitude,longitude.";
                    return view('finder', $view);
                }
                $center['label'] = "ZIP {$m[1]}";
            } elseif (preg_match('/^\s*(-?\d{1,3}(?:\.\d+)?)\s*,\s*(-?\d{1,3}(?:\.\d+)?)\s*$/', $q, $m)
                && abs((float) $m[1]) <= 90 && abs((float) $m[2]) <= 180) {
                $center = ['lat' => (float) $m[1], 'lon' => (float) $m[2], 'label' => 'your point'];
            } else {
                $view['error'] = 'Enter a 5-digit ZIP code, or coordinates like 38.9072, -77.0369.';
                return view('finder', $view);
            }

            $view['center'] = $center;
            $view['results'] = $this->finder->nearest($center['lat'], $center['lon'], $opt);
        } catch (\Throwable $e) {
            $view['error'] = 'Could not reach the database: ' . \Illuminate\Support\Str::limit($e->getMessage(), 240);
        }

        return view('finder', $view);
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
