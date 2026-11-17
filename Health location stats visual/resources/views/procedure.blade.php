@extends('layouts.app')
@section('title', $proc['full'])
@section('content')
<header class="page-head">
    <p class="crumb"><a href="{{ route('pipeline') }}">Load pipeline</a> / procedure</p>
    <h1>ƒ {{ $proc['full'] }}</h1>
    <p class="muted">{{ $proc['uses_transaction'] ? 'Transactional' : 'No explicit transaction' }} · {{ $proc['uses_try_catch'] ? 'TRY/CATCH' : 'no error handling' }} · {{ $proc['line_count'] }} lines</p>
</header>

<div class="two">
    <section class="card">
        <h2>Reads</h2>
        @foreach ($proc['reads'] as $r)
            @php [$s, $n] = explode('.', $r, 2); @endphp
            <a class="chip" href="{{ route('table', ['schemaName' => $s, 'name' => $n]) }}">{{ $r }}</a>
        @endforeach
        @if ($proc['source_file'])<span class="chip file">{{ $proc['source_file'] }}</span>@endif
    </section>
    <section class="card">
        <h2>Writes</h2>
        @foreach ($proc['writes'] as $w)
            @php [$s, $n] = explode('.', $w, 2); @endphp
            <a class="chip" href="{{ route('table', ['schemaName' => $s, 'name' => $n]) }}">{{ $w }}
                <em>{{ implode('+', $proc['operations'][$w] ?? []) }}</em></a>
        @endforeach
    </section>
</div>

@if (count($proc['steps']))
<section class="card">
    <h2>Commented steps</h2>
    <ol>@foreach ($proc['steps'] as $s)<li>{{ $s }}</li>@endforeach</ol>
</section>
@endif

<section class="card">
    <h2>Definition</h2>
    <pre class="sql">{{ $proc['sql'] }}</pre>
</section>
@endsection
