@extends('layouts.app')
@section('title', 'Find a site')
@section('content')
<header class="page-head">
    <h1>Find the closest site</h1>
    <p>Enter a ZIP code or coordinates. Results come from the live gold tables and are sorted by straight-line distance, so check the hours and call ahead.</p>
</header>

<form method="get" action="{{ route('finder') }}" class="finder-form card">
    <div class="row-fields">
        <label class="grow">ZIP or latitude, longitude
            <input type="text" name="q" value="{{ $q }}" placeholder="20001   or   38.9072, -77.0369" autofocus>
        </label>
        <label>Results
            <select name="limit">
                @foreach ([5, 10, 20] as $n)
                    <option value="{{ $n }}" {{ $opt['limit'] === $n ? 'selected' : '' }}>{{ $n }}</option>
                @endforeach
            </select>
        </label>
        <button class="btn" type="submit">Search</button>
    </div>
    <div class="checks">
        <label><input type="checkbox" name="exclude_admin" value="1" {{ $opt['exclude_admin'] ? 'checked' : '' }}> Hide administrative-only sites</label>
        <label><input type="checkbox" name="exclude_school" value="1" {{ $opt['exclude_school'] ? 'checked' : '' }}> Hide school-based sites</label>
        <label><input type="checkbox" name="hospital_only" value="1" {{ $opt['hospital_only'] ? 'checked' : '' }}> Hospital-setting sites only</label>
    </div>
</form>

@if ($error)
    <div class="flash err">{{ $error }}</div>
@endif

@if ($results !== null)
    @if (count($results) === 0)
        <section class="card"><p class="muted">No sites matched near {{ $center['label'] }} with these filters. Try turning a filter off.</p></section>
    @else
        <p class="muted">Closest {{ count($results) }} to {{ $center['label'] }}
            ({{ number_format($center['lat'], 4) }}, {{ number_format($center['lon'], 4) }})</p>

        <div class="finder-grid">
            <section class="card">
                <table class="grid">
                    <thead><tr><th>#</th><th>Site</th><th>Miles</th><th>Hours / week</th><th>Setting</th></tr></thead>
                    <tbody>
                    @foreach ($results as $i => $r)
                        <tr>
                            <td class="muted">{{ $i + 1 }}</td>
                            <td>
                                <b>{{ $r['name'] ?? 'Unnamed site' }}</b>
                                @if (! empty($r['is_new']))<span class="chip new">added in the last year</span>@endif<br>
                                <span class="muted">{{ $r['address'] }}, {{ $r['city'] }}, {{ $r['state'] }} {{ \Illuminate\Support\Str::limit((string) $r['zip'], 5, '') }}</span><br>
                                @if ($r['phone'])<span class="mono">{{ $r['phone'] }}</span> · @endif
                                <a href="https://www.google.com/maps/search/?api=1&query={{ urlencode($r['lat'] . ',' . $r['lon']) }}" target="_blank" rel="noopener">map</a>
                            </td>
                            <td>{{ number_format($r['miles'], 1) }}</td>
                            <td>
                                @if ($r['hours'] === null)
                                    <span class="chip">not listed</span>
                                @elseif ($r['hours'] < 20)
                                    {{ rtrim(rtrim(number_format($r['hours'], 1), '0'), '.') }} <span class="chip warn">short hours</span>
                                @else
                                    {{ rtrim(rtrim(number_format($r['hours'], 1), '0'), '.') }}
                                @endif
                            </td>
                            <td class="muted">{{ $r['setting'] ?? '—' }}</td>
                        </tr>
                    @endforeach
                    </tbody>
                </table>
            </section>
            <section class="card">
                <h2>Where they are</h2>
                @php
                    $mapCenter = ['lat' => $center['lat'], 'lon' => $center['lon']];
                    $mapPoints = [];
                    foreach ($results as $row) {
                        $mapPoints[] = ['lat' => $row['lat'], 'lon' => $row['lon'], 'name' => $row['name'] ?? '', 'miles' => $row['miles']];
                    }
                @endphp
                <div id="finder-map" data-center="{{ json_encode($mapCenter) }}" data-points="{{ json_encode($mapPoints) }}"></div>
                <p class="muted small-note">The square is your search point; numbers match the table. Click the map, then scroll to zoom.</p>
            </section>
        </div>
    @endif
@endif
@endsection
@push('head')
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/leaflet.css">
@endpush
@push('scripts')
<script src="https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/leaflet.js"></script>
<script src="{{ asset('js/finder.js') }}"></script>
@endpush
