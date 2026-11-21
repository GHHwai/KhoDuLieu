# Healthcare_location schema visualizer

A Laravel 12 site that **parses `resources/sql/schemascript.sql`** (an SSMS-generated T-SQL script) and visualises it. No database connection is needed.

- **Overview** – counts and every table grouped by bronze / silver / gold
- **ER diagram** – draggable, zoomable SVG with FK lines (bronze hidden by default; toggle layers)
- **Load pipeline** – CSV → bronze → silver → gold flow derived from the stored procedures
- **Table / procedure pages** – columns, types, PK/FK/UQ, defaults, referenced-by, full procedure SQL
- `/api/schema` – the parsed schema as JSON
- Sidebar: **Load another script** (upload) replaces the active script; **Use bundled script** reverts

## Setup
Copy these files over a fresh/your Laravel 12 project (they overwrite `routes/web.php`, `.env.example`, and delete `welcome.blade.php`), then:

```
composer install
cp .env.example .env && php artisan key:generate
php artisan serve
php artisan test
```

`.env.example` uses file session/cache so no database or migrations are required.

## Note on the bundled script
`resources/sql/schemascript.sql` is a **condensed** copy: all tables, columns, keys, defaults and FKs are complete, but server settings were removed and stored-procedure bodies are shortened. Use *Load another script* to upload your full original.

## Gold data (live, read-only)
The **Gold data** page and the *Sample rows* block on gold table pages query the real database. Only `gold.*` tables are read, with aggregate queries in `app/Services/GoldDataService.php`.

1. Install the `pdo_sqlsrv` PHP extension and the Microsoft ODBC driver.
2. Fill in the `DB_*` values in `.env` (see `.env.example`).
3. Run `load_bronze`, `load_silver`, `load_gold` so the gold tables have rows, then `php artisan cache:clear`.

Without a connection the page shows setup steps instead of failing. Results are cached for 10 minutes.

## Find a site (nearest-site search)
`/finder` takes a 5-digit ZIP or `lat, lon` and returns the closest sites from the gold tables, sorted by straight-line miles, with hours per week, setting, phone and a map link. Filters: hide administrative-only sites, hide school-based sites, hospital-setting only. The results sit on a real map (Leaflet with OpenStreetMap tiles, loaded from cdnjs and OSM, so the browser needs internet access; offline it falls back to a plain dot map). Sites added within a year of the newest site in the data get an "added in the last year" badge. A ZIP's centre is the average position of the sites already in that ZIP, so a ZIP with no sites cannot be searched (use coordinates). Distance is as-the-crow-flies, not driving time.

The **Gold data** page also charts sites per 1,000 residents, the share of part-time sites, and how many sites a finder would return after each filter. Per-resident figures use rounded 2020 Census populations in `config/state_population.php` (approximate; replace with the official file for formal use).

## Light and dark mode
The sidebar button switches between light and dark. With no choice made it follows the operating system setting; a choice is remembered in the browser. Charts follow the theme live (colours are CSS variables).

## Also on the Gold data page
Sites added in the last year of data, hospital-setting sites by state, and the most common schedule values (to check whether "open now" is possible).
