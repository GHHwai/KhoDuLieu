@extends('layouts.app')
@section('title', 'Gold data')
@section('content')
<header class="page-head">
    <h1>Gold data</h1>
    <p>Live aggregates from the <b>gold</b> star schema (read-only). Results are cached for 10 minutes.</p>
</header>

@if ($result['status'] !== 'ok')
    <section class="card">
        <h2>Database not connected</h2>
        <p class="muted">{{ $result['message'] }}</p>
        <ol>
            <li>Install the <code>pdo_sqlsrv</code> PHP extension and the Microsoft ODBC driver.</li>
            <li>Set <code>DB_CONNECTION=sqlsrv</code>, <code>DB_HOST</code>, <code>DB_PORT</code>, <code>DB_DATABASE=Healthcare_location</code>, <code>DB_USERNAME</code>, <code>DB_PASSWORD</code> in <code>.env</code>.</li>
            <li>Run the load procedures so the gold tables have rows, then <code>php artisan cache:clear</code> and reload.</li>
        </ol>
    </section>
@else
    @php $k = $result['data']['kpi']; @endphp
    <section class="stats">
        <div class="stat"><b>{{ number_format($k['sites'] ?? 0) }}</b><span>sites</span></div>
        <div class="stat"><b>{{ number_format($k['health_centers'] ?? 0) }}</b><span>distinct health centers ({{ number_format($k['health_center_rows'] ?? 0) }} rows in the dimension: one per site type / operator)</span></div>
        <div class="stat"><b>{{ number_format($k['locations'] ?? 0) }}</b><span>locations</span></div>
        <div class="stat"><b>{{ number_format($k['states'] ?? 0) }}</b><span>states / territories</span></div>
        <div class="stat"><b>{{ number_format($result['data']['recent']['recent_sites'] ?? 0) }}</b><span>added in the last year of data{{ ! empty($result['data']['recent']['newest']) ? ' (newest ' . $result['data']['recent']['newest'] . ')' : '' }}</span></div>
        <div class="stat"><b>{{ isset($k['avg_hours']) ? number_format($k['avg_hours'], 1) : '—' }}</b><span>avg hours / week</span></div>
    </section>

    <div id="data-charts" data-url="{{ route('api.data') }}" class="chart-grid">
        <section class="card wide"><h2>Sites by state (top 15)</h2><div id="d-state"></div></section>
        <section class="card"><h2>Sites by HHS region</h2><div id="d-region"></div></section>
        <section class="card"><h2>Sites by status</h2><div id="d-status"></div></section>
        <section class="card"><h2>Sites by health center type</h2><div id="d-type"></div></section>
        <section class="card"><h2>Operating hours per week</h2><div id="d-hours"></div></section>
        <section class="card"><h2>Sites by location setting</h2><div id="d-setting"></div></section>
        <section class="card"><h2>Sites added to scope, by year</h2><div id="d-year"></div></section>
        <section class="card"><h2>Fewest sites per 1,000 residents <small class="muted">(approx. population)</small></h2><div id="d-percap"></div></section>
        <section class="card"><h2>Highest share of part-time sites <small class="muted">(under 40 h/week)</small></h2><div id="d-parttime"></div></section>
        <section class="card"><h2>Hospital-setting sites by state (top 15)</h2><div id="d-hosp"></div></section>
        <section class="card"><h2>Do the schedule fields say when sites are open?</h2>
            <p class="muted small-note">The most common values. If they name days and times, an "open now" flag is possible; if they only repeat hours per week, it is not.</p>
            <table class="grid sched">
                <thead><tr><th>Description</th><th>Calendar</th><th>Sites</th><th>Hours / week</th></tr></thead>
                <tbody>
                @forelse ($result['data']['schedules'] ?? [] as $row)
                    <tr>
                        <td>{{ $row['description'] ?: '—' }}</td>
                        <td>{{ $row['calendar'] ?: '—' }}</td>
                        <td>{{ number_format($row['sites']) }}</td>
                        <td>@if ($row['min_hours'] === null)—@elseif ((float) $row['min_hours'] === (float) $row['max_hours']){{ (float) $row['min_hours'] }}@else{{ (float) $row['min_hours'] }} to {{ (float) $row['max_hours'] }}@endif</td>
                    </tr>
                @empty
                    <tr><td colspan="4" class="muted">No schedule rows.</td></tr>
                @endforelse
                </tbody>
            </table>
        </section>
        <section class="card wide"><h2>Who a "closest site" search would return</h2><div id="d-funnel"></div></section>
        <section class="card wide"><h2>Site locations (sample of up to 4,000)</h2><div id="d-map"></div></section>
    </div>
@endif
@endsection
@push('scripts')
@if ($result['status'] === 'ok')
<script src="{{ asset('js/data.js') }}"></script>
@endif
@endpush
