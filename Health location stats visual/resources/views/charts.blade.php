@extends('layouts.app')
@section('title', 'Charts')
@section('content')
<header class="page-head">
    <h1>Charts</h1>
    <p>Structure of the warehouse as charts, computed from the schema script (no row data is involved).</p>
</header>
<div id="charts" data-url="{{ route('api.schema') }}" class="chart-grid">
    <section class="card wide"><h2>Columns per table</h2><div id="c-cols"></div></section>
    <section class="card"><h2>Tables per layer</h2><div id="c-layers"></div></section>
    <section class="card"><h2>Column data types</h2><div id="c-types"></div></section>
    <section class="card wide"><h2>Nullable vs NOT NULL columns, by layer</h2><div id="c-null"></div></section>
    <section class="card wide"><h2>Foreign keys: outgoing vs incoming</h2><div id="c-fk"></div></section>
    <section class="card wide"><h2>Which procedure touches which table</h2><div id="c-matrix"></div></section>
</div>
@endsection
@push('scripts')
<script src="{{ asset('js/charts.js') }}"></script>
@endpush
