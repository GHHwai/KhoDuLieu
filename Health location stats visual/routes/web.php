<?php

use App\Http\Controllers\SchemaController;
use Illuminate\Support\Facades\Route;

Route::get('/', [SchemaController::class, 'overview'])->name('overview');
Route::get('/diagram', [SchemaController::class, 'diagram'])->name('diagram');
Route::get('/charts', [SchemaController::class, 'charts'])->name('charts');
Route::get('/data', [SchemaController::class, 'data'])->name('data');
Route::get('/api/data', [SchemaController::class, 'dataApi'])->name('api.data');
Route::get('/pipeline', [SchemaController::class, 'pipeline'])->name('pipeline');
Route::get('/tables/{schemaName}/{name}', [SchemaController::class, 'table'])->name('table');
Route::get('/procedures/{schemaName}/{name}', [SchemaController::class, 'procedure'])->name('procedure');
Route::get('/api/schema', [SchemaController::class, 'api'])->name('api.schema');
Route::post('/script', [SchemaController::class, 'upload'])->name('script.upload');
Route::post('/script/reset', [SchemaController::class, 'reset'])->name('script.reset');
