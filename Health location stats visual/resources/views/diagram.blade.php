@extends('layouts.app')
@section('title', 'ER diagram')
@section('content')
<header class="page-head row">
    <div>
        <h1>ER diagram</h1>
        <p>Drag tables, scroll to zoom, drag the background to pan. Hover a table to trace its relationships; double-click for details.</p>
    </div>
    <div class="controls" id="layer-toggles"></div>
</header>
<div class="canvas-wrap">
    <svg id="canvas" class="canvas" data-mode="er" data-url="{{ route('api.schema') }}" data-table-url="{{ url('/tables') }}"></svg>
    <div class="zoom">
        <button id="zin" title="Zoom in">+</button>
        <button id="zout" title="Zoom out">−</button>
        <button id="zfit" title="Fit">⤢</button>
    </div>
    <div class="legend">
        <span><i class="k pk"></i>primary key</span>
        <span><i class="k fk"></i>foreign key</span>
    </div>
</div>
@endsection
@push('scripts')
<script src="{{ asset('js/diagram.js') }}"></script>
@endpush
