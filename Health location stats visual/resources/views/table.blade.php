@extends('layouts.app')
@section('title', $table['name'])
@section('content')
<header class="page-head">
    <p class="crumb"><a href="{{ route('overview') }}">Overview</a> / <span class="dot layer-{{ $table['layer'] }}"></span>{{ $table['schema'] }}</p>
    <h1>{{ $table['name'] }} <span class="chip">{{ $table['kind'] }}</span></h1>
    <p class="muted">{{ count($table['columns']) }} columns
        @if ($table['primary_key']) · PK ({{ implode(', ', $table['primary_key']) }}) @endif
    </p>
</header>

<section class="card">
    <table class="grid">
        <thead><tr><th>#</th><th>Column</th><th>Type</th><th>Null</th><th>Keys</th><th>Notes</th></tr></thead>
        <tbody>
        @foreach ($table['columns'] as $i => $c)
            <tr>
                <td class="muted">{{ $i + 1 }}</td>
                <td class="mono">{{ $c['name'] }}</td>
                <td class="mono">{{ $c['type_full'] }}</td>
                <td>{{ $c['nullable'] ? 'yes' : 'no' }}</td>
                <td>
                    @if ($c['pk'])<span class="badge pk">PK</span>@endif
                    @if ($c['fk'])<span class="badge fk">FK</span>@endif
                    @if ($c['unique'])<span class="badge uq">UQ</span>@endif
                </td>
                <td class="muted">
                    @if ($c['identity']) identity @endif
                    @if ($c['default'] !== null) default {{ $c['default'] }} @endif
                </td>
            </tr>
        @endforeach
        </tbody>
    </table>
</section>

<div class="two">
    <section class="card">
        <h2>References</h2>
        @forelse ($table['foreign_keys'] as $fk)
            @php [$rs, $rn] = explode('.', $fk['ref_table'], 2); @endphp
            <p class="rel"><span class="mono">{{ implode(', ', $fk['columns']) }}</span> →
                <a href="{{ route('table', ['schemaName' => $rs, 'name' => $rn]) }}">{{ $fk['ref_table'] }}</a>
                (<span class="mono">{{ implode(', ', $fk['ref_columns']) }}</span>)
                <small class="muted">{{ $fk['name'] }}</small></p>
        @empty
            <p class="muted">No foreign keys.</p>
        @endforelse
    </section>
    <section class="card">
        <h2>Referenced by</h2>
        @forelse ($table['referenced_by'] as $r)
            @php [$rs, $rn] = explode('.', $r['table'], 2); @endphp
            <p class="rel"><a href="{{ route('table', ['schemaName' => $rs, 'name' => $rn]) }}">{{ $r['table'] }}</a>
                <small class="muted">{{ $r['name'] }}</small></p>
        @empty
            <p class="muted">Not referenced by other tables.</p>
        @endforelse
    </section>
</div>

@if ($sample)
<section class="card">
    <h2>Sample rows <small class="muted">(first 20, read-only)</small></h2>
    @if ($sample['status'] === 'ok')
        @if (count($sample['rows']))
            <table class="grid">
                <thead><tr>@foreach (array_keys($sample['rows'][0]) as $k)<th>{{ $k }}</th>@endforeach</tr></thead>
                <tbody>
                @foreach ($sample['rows'] as $row)
                    <tr>@foreach ($row as $v)<td class="mono">{{ \Illuminate\Support\Str::limit((string) $v, 40) }}</td>@endforeach</tr>
                @endforeach
                </tbody>
            </table>
        @else
            <p class="muted">The table is empty.</p>
        @endif
    @else
        <p class="muted">Database not connected. <a href="{{ route('data') }}">See setup</a>.</p>
    @endif
</section>
@endif

<section class="card">
    <h2>Loaded by</h2>
    @forelse ($table['loaded_by'] as $p)
        @php [$ps, $pn] = explode('.', $p, 2); @endphp
        <a class="chip" href="{{ route('procedure', ['schemaName' => $ps, 'name' => $pn]) }}">ƒ {{ $p }}</a>
    @empty
        <p class="muted">No stored procedure writes to this table.</p>
    @endforelse
</section>
@endsection
