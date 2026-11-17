@extends('layouts.app')
@section('title', 'Overview')
@section('content')
<header class="page-head">
    <h1>{{ $schema['database'] }}</h1>
    <p>Medallion warehouse: raw CSV is landed in <b>bronze</b>, cleaned and normalised in <b>silver</b>, and published as a star schema in <b>gold</b>.</p>
</header>

<section class="stats">
    <div class="stat"><b>{{ $schema['stats']['tables'] }}</b><span>tables</span></div>
    <div class="stat"><b>{{ $schema['stats']['columns'] }}</b><span>columns</span></div>
    <div class="stat"><b>{{ $schema['stats']['relationships'] }}</b><span>foreign keys</span></div>
    <div class="stat"><b>{{ $schema['stats']['facts'] }} / {{ $schema['stats']['dimensions'] }}</b><span>facts / dimensions</span></div>
    <div class="stat"><b>{{ $schema['stats']['procedures'] }}</b><span>load procedures</span></div>
</section>

<section class="layers">
    @foreach ($schema['schemas'] as $s)
        <div class="layer-card layer-{{ strtolower($s) }}-card">
            <h2><span class="dot layer-{{ strtolower($s) }}"></span>{{ $s }}
                <small>{{ $schema['stats']['by_layer'][$s]['tables'] ?? 0 }} tables</small></h2>
            <ul>
                @foreach ($schema['tables'] as $t)
                    @if ($t['schema'] === $s)
                        <li>
                            <a href="{{ route('table', ['schemaName' => $t['schema'], 'name' => $t['name']]) }}">{{ $t['name'] }}</a>
                            <span class="chip">{{ $t['kind'] }}</span>
                            <span class="muted">{{ count($t['columns']) }} cols</span>
                        </li>
                    @endif
                @endforeach
            </ul>
            @foreach ($schema['procedures'] as $p)
                @if ($p['schema'] === $s)
                    <a class="proc-link" href="{{ route('procedure', ['schemaName' => $p['schema'], 'name' => $p['name']]) }}">ƒ {{ $p['full'] }}</a>
                @endif
            @endforeach
        </div>
    @endforeach
</section>

<section class="cta">
    <a class="btn" href="{{ route('diagram') }}">Open ER diagram →</a>
    <a class="btn ghost" href="{{ route('pipeline') }}">See load pipeline →</a>
    <a class="btn ghost" href="{{ route('api.schema') }}">JSON</a>
</section>
@endsection
