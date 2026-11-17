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
