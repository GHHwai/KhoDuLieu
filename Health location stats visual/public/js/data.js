/* Charts for live gold-layer aggregates (/api/data). Dependency-free SVG. */
(function () {
  const host = document.getElementById('data-charts');
  if (!host) return;
  const css = (n) => getComputedStyle(document.documentElement).getPropertyValue(n).trim();
  const esc = (s) => String(s).replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));
  const fmt = (n) => Number(n).toLocaleString();
  const put = (id, html) => { const e = document.getElementById(id); if (e) e.innerHTML = html; };
  const empty = (id) => put(id, '<p class="muted">No data.</p>');
  const gold = () => css('--gold');

  // horizontal bars
  function hbar(id, rows, color) {
    if (!rows || !rows.length) return empty(id);
    const max = Math.max(...rows.map((r) => +r.value)), L = 190, R = 60, rh = 24, w = 560, h = rows.length * rh + 8;
    let s = '';
    rows.forEach((r, i) => {
      const y = 4 + i * rh, bw = Math.max(1, ((w - L - R) * r.value) / max);
      const label = String(r.label).length > 28 ? String(r.label).slice(0, 27) + '…' : r.label;
      s += `<text class="c-lab" x="${L - 8}" y="${y + 15}" text-anchor="end">${esc(label)}</text>`;
      s += `<rect x="${L}" y="${y + 3}" width="${bw}" height="${rh - 8}" rx="3" fill="${color}"><title>${esc(r.label)}: ${fmt(r.value)}</title></rect>`;
      s += `<text class="c-val" x="${L + bw + 6}" y="${y + 15}">${fmt(r.value)}</text>`;
    });
    put(id, `<svg viewBox="0 0 ${w} ${h}" role="img">${s}</svg>`);
  }

  // vertical columns (ordered categories)
  function columns(id, rows, color) {
    if (!rows || !rows.length) return empty(id);
    const max = Math.max(...rows.map((r) => +r.value)), w = 560, h = 240, base = 200, left = 10;
    const slot = (w - left * 2) / rows.length, bw = Math.min(46, slot * 0.7);
    let s = `<line class="c-axis" x1="${left}" y1="${base}" x2="${w - left}" y2="${base}"/>`;
    rows.forEach((r, i) => {
      const bh = (r.value / max) * (base - 28), x = left + i * slot + (slot - bw) / 2;
      s += `<rect x="${x}" y="${base - bh}" width="${bw}" height="${bh}" rx="3" fill="${color}"><title>${esc(r.label)}: ${fmt(r.value)}</title></rect>`;
      s += `<text class="c-val" x="${x + bw / 2}" y="${base - bh - 5}" text-anchor="middle">${fmt(r.value)}</text>`;
      s += `<text class="c-lab" x="${x + bw / 2}" y="${base + 16}" text-anchor="middle">${esc(r.label)}</text>`;
    });
    put(id, `<svg viewBox="0 0 ${w} ${h}" role="img">${s}</svg>`);
  }

  function scatter(id, pts) {
    if (!pts || !pts.length) return empty(id);
    const w = 900, h = 440, pad = 30;
    const xs = pts.map((p) => p.x), ys = pts.map((p) => p.y);
    const x0 = Math.min(...xs), x1 = Math.max(...xs), y0 = Math.min(...ys), y1 = Math.max(...ys);
    // equirectangular with a rough cos(lat) correction so the shape is not stretched
    const k = Math.cos((((y0 + y1) / 2) * Math.PI) / 180);
    const sx = (w - pad * 2) / ((x1 - x0) * k || 1), sy = (h - pad * 2) / (y1 - y0 || 1), sc = Math.min(sx, sy);
    const ox = (w - (x1 - x0) * k * sc) / 2, oy = (h - (y1 - y0) * sc) / 2;
    let s = '';
    pts.forEach((p) => {
      const cx = ox + (p.x - x0) * k * sc, cy = h - oy - (p.y - y0) * sc;
      s += `<circle cx="${cx.toFixed(1)}" cy="${cy.toFixed(1)}" r="2.2" fill="${gold()}" fill-opacity=".45"/>`;
    });
    put(id, `<svg viewBox="0 0 ${w} ${h}" role="img">${s}</svg>`);
  }

  fetch(host.dataset.url).then((r) => r.json()).then((res) => {
    if (res.status !== 'ok') return;
    const d = res.data;
    hbar('d-state', d.by_state, gold());
    hbar('d-region', d.by_region, css('--fk'));
    hbar('d-status', d.by_status, css('--silver'));
    hbar('d-type', d.by_type, css('--bronze'));
    hbar('d-setting', d.by_setting, css('--fk'));
    const order = ['< 20', '20-39', '40-59', '60+', 'unknown'];
    columns('d-hours', (d.hours || []).slice().sort((a, b) => order.indexOf(a.label) - order.indexOf(b.label)), gold());
    columns('d-year', d.by_year, css('--fk'));
    scatter('d-map', d.points);
  });
})();
