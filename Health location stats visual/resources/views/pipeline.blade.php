@extends('layouts.app')
@section('title', 'Load pipeline')
@section('content')
<header class="page-head">
    <h1>Load pipeline</h1>
    <p>Data flow derived from the stored procedures: which tables each procedure reads and which it writes.</p>
</header>
<div class="canvas-wrap short">
    <svg id="canvas" class="canvas" data-mode="pipeline" data-url="{{ route('api.schema') }}" data-table-url="{{ url('/tables') }}" data-proc-url="{{ url('/procedures') }}"></svg>
    <div class="zoom">
        <button id="zin">+</button><button id="zout">−</button><button id="zfit">⤢</button>
    </div>
</div>

<section class="procs">
    @foreach ($schema['procedures'] as $p)
        <article class="proc-card">
            <h2><a href="{{ route('procedure', ['schemaName' => $p['schema'], 'name' => $p['name']]) }}">{{ $p['full'] }}</a></h2>
            <p class="muted">
                {{ $p['uses_transaction'] ? 'transactional' : 'no explicit transaction' }}
                · {{ $p['uses_try_catch'] ? 'TRY/CATCH' : 'no error handling' }}
                · {{ $p['line_count'] }} lines
            </p>
            <div class="io">
                <div>
                    <h3>Reads</h3>
                    @forelse ($p['reads'] as $r)
                        <span class="chip">{{ $r }}</span>
                    @empty
                        <span class="muted">—</span>
                    @endforelse
                    @if ($p['source_file'])
                        <span class="chip file">{{ $p['source_file'] }}</span>
                    @endif
                </div>
                <div>
                    <h3>Writes</h3>
                    @foreach ($p['writes'] as $w)
                        <span class="chip">{{ $w }}
                            <em>{{ implode('+', $p['operations'][$w] ?? []) }}</em></span>
                    @endforeach
                </div>
            </div>
        </article>
    @endforeach
</section>
@endsection
@push('scripts')
<script src="{{ asset('js/diagram.js') }}"></script>
@endpush
