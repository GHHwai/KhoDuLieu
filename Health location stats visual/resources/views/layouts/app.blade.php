<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>@yield('title', 'Schema') · {{ $schema['database'] }}</title>
    <script>
        (function () {
            try { var t = localStorage.getItem('theme'); if (t === 'light' || t === 'dark') document.documentElement.setAttribute('data-theme', t); } catch (e) {}
        })();
    </script>
    <link rel="stylesheet" href="{{ asset('css/schema.css') }}">
    @stack('head')
</head>
<body>
<div class="shell">
    <aside class="side">
        <a class="brand" href="{{ route('overview') }}">
            <span class="brand-mark"></span>
            <span><strong>{{ $schema['database'] }}</strong><small>schema visualizer</small></span>
        </a>

        <button type="button" class="theme-toggle" id="theme-toggle" aria-label="Switch between light and dark mode">
            <span class="ico" id="theme-ico">◐</span><span id="theme-label">Theme</span>
        </button>

        <nav>
            <a href="{{ route('overview') }}" class="{{ request()->routeIs('overview') ? 'on' : '' }}">Overview</a>
            <a href="{{ route('diagram') }}" class="{{ request()->routeIs('diagram') ? 'on' : '' }}">ER diagram</a>
            <a href="{{ route('charts') }}" class="{{ request()->routeIs('charts') ? 'on' : '' }}">Charts</a>
            <a href="{{ route('data') }}" class="{{ request()->routeIs('data') ? 'on' : '' }}">Gold data</a>
            <a href="{{ route('finder') }}" class="{{ request()->routeIs('finder') ? 'on' : '' }}">Find a site</a>
            <a href="{{ route('pipeline') }}" class="{{ request()->routeIs('pipeline', 'procedure') ? 'on' : '' }}">Load pipeline</a>
        </nav>

        @foreach ($schema['schemas'] as $s)
            <div class="nav-group">
                <div class="nav-title"><span class="dot layer-{{ strtolower($s) }}"></span>{{ $s }}</div>
                @foreach ($schema['tables'] as $t)
                    @if ($t['schema'] === $s)
                        <a class="tbl {{ request()->route('schemaName') === $t['schema'] && request()->route('name') === $t['name'] ? 'on' : '' }}"
                           href="{{ route('table', ['schemaName' => $t['schema'], 'name' => $t['name']]) }}">{{ $t['name'] }}</a>
                    @endif
                @endforeach
            </div>
        @endforeach

        <div class="side-foot">
            <div class="muted">Source: {{ $schema['source']['file'] }}</div>
            <form method="post" action="{{ route('script.upload') }}" enctype="multipart/form-data">
                @csrf
                <label class="btn small">Load another script
                    <input type="file" name="script" accept=".sql,.txt" hidden onchange="this.form.submit()">
                </label>
            </form>
            @if ($schema['source']['uploaded'])
                <form method="post" action="{{ route('script.reset') }}">
                    @csrf
                    <button class="btn small ghost" type="submit">Use bundled script</button>
                </form>
            @endif
        </div>
    </aside>

    <main class="main">
        @if (session('status'))
            <div class="flash">{{ session('status') }}</div>
        @endif
        @if ($errors->any())
            <div class="flash err">{{ $errors->first() }}</div>
        @endif
        @yield('content')
    </main>
</div>
<script>
    (function () {
        var root = document.documentElement, btn = document.getElementById('theme-toggle');
        function effective() {
            var t = root.getAttribute('data-theme');
            if (t) return t;
            return window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
        }
        function paint() {
            var dark = effective() === 'dark';
            document.getElementById('theme-ico').textContent = dark ? '☾' : '☀';
            document.getElementById('theme-label').textContent = dark ? 'Dark mode' : 'Light mode';
        }
        btn.addEventListener('click', function () {
            var next = effective() === 'dark' ? 'light' : 'dark';
            root.setAttribute('data-theme', next);
            try { localStorage.setItem('theme', next); } catch (e) {}
            paint();
        });
        paint();
    })();
</script>
@stack('scripts')
</body>
</html>
