/* Dependency-free SVG charts computed from /api/schema. */
(function () {
  const host = document.getElementById('charts');
  if (!host) return;
  const NS = 'http://www.w3.org/2000/svg';
  const css = (n) => getComputedStyle(document.documentElement).getPropertyValue(n).trim();
  const layerCol = (l) => css('--' + l) || css('--muted');
  const esc = (s) => String(s).replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));
  const svg = (w, h, inner) => `<svg viewBox="0 0 ${w} ${h}" role="img">${inner}</svg>`;
  const legend = (items) => `<div class="leg">${items.map(([c, t]) => `<span><i style="background:${c}"></i>${esc(t)}</span>`).join('')}</div>`;
  const put = (id, html) => (document.getElementById(id).innerHTML = html);
  const kindCol = ['--bronze', '--silver', '--gold'];
  const palette = () => ['--fk', '#5b9e8a', '#a566a0', '#c25b56', '#6fa3c9', '#8a7bc4', '#d08a8a', '#4c8f4c', '#999999'].map((v) => (v[0] === '-' ? css(v) : v));

  fetch(host.dataset.url).then((r) => r.json()).then(draw);

  function draw(d) {
    const T = d.tables;
    const layers = d.schemas.map((s) => s.toLowerCase());

    /* 1. columns per table (horizontal bars) */
    {
      const rows = T.slice().sort((a, b) => b.columns.length - a.columns.length);
      const max = Math.max(...rows.map((t) => t.columns.length));
      const L = 260, R = 50, rh = 24, w = 760, h = rows.length * rh + 10;
      let s = '';
      rows.forEach((t, i) => {
        const y = 5 + i * rh, bw = ((w - L - R) * t.columns.length) / max;
        s += `<text class="c-lab" x="${L - 8}" y="${y + 15}" text-anchor="end">${esc(t.full)}</text>`;
        s += `<rect x="${L}" y="${y + 3}" width="${bw}" height="${rh - 8}" rx="3" fill="${layerCol(t.layer)}"><title>${esc(t.full)}: ${t.columns.length} columns</title></rect>`;
        s += `<text class="c-val" x="${L + bw + 6}" y="${y + 15}">${t.columns.length}</text>`;
      });
      put('c-cols', svg(w, h, s) + legend(layers.map((l) => [layerCol(l), l])));
    }

    /* 2. tables per layer, stacked by kind */
    {
      const kinds = [...new Set(T.map((t) => t.kind))];
      const kc = palette();
      const w = 360, h = 260, base = 220, left = 30;
      const counts = layers.map((l) => kinds.map((k) => T.filter((t) => t.layer === l && t.kind === k).length));
      const max = Math.max(...counts.map((c) => c.reduce((a, b) => a + b, 0)));
      const bw = 60, gap = (w - left - bw * layers.length) / (layers.length + 1);
      let s = `<line class="c-axis" x1="${left}" y1="${base}" x2="${w}" y2="${base}"/>`;
      layers.forEach((l, i) => {
        let y = base;
        const x = left + gap + i * (bw + gap);
        kinds.forEach((k, ki) => {
          const n = counts[i][ki];
          if (!n) return;
          const bh = (n / max) * (base - 30);
          y -= bh;
          s += `<rect x="${x}" y="${y}" width="${bw}" height="${bh}" fill="${kc[ki % kc.length]}" stroke="${css('--panel')}" stroke-width="1.5"><title>${l} / ${k}: ${n}</title></rect>`;
          s += `<text x="${x + bw / 2}" y="${y + bh / 2 + 4}" text-anchor="middle" style="fill:#fff;font:600 11px sans-serif">${n}</text>`;
        });
        s += `<text class="c-lab" x="${x + bw / 2}" y="${base + 18}" text-anchor="middle">${esc(l)}</text>`;
      });
      put('c-layers', svg(w, h, s) + legend(kinds.map((k, i) => [kc[i % kc.length], k])));
    }

    /* 3. data types donut */
    {
      const cnt = {};
      T.forEach((t) => t.columns.forEach((c) => (cnt[c.type_full] = (cnt[c.type_full] || 0) + 1)));
      const ent = Object.entries(cnt).sort((a, b) => b[1] - a[1]);
      const total = ent.reduce((a, [, n]) => a + n, 0);
      const kc = palette();
      const cx = 130, cy = 130, r = 100, ir = 62;
      let a0 = -Math.PI / 2, s = '';
      ent.forEach(([k, n], i) => {
        const a1 = a0 + (n / total) * Math.PI * 2, big = a1 - a0 > Math.PI ? 1 : 0;
        const p = (a, rr) => `${cx + rr * Math.cos(a)} ${cy + rr * Math.sin(a)}`;
        s += `<path d="M${p(a0, r)} A${r} ${r} 0 ${big} 1 ${p(a1 - 0.0001, r)} L${p(a1 - 0.0001, ir)} A${ir} ${ir} 0 ${big} 0 ${p(a0, ir)}Z" fill="${kc[i % kc.length]}" stroke="${css('--panel')}" stroke-width="1.5"><title>${esc(k)}: ${n} (${Math.round((n / total) * 100)}%)</title></path>`;
        a0 = a1;
      });
      s += `<text x="${cx}" y="${cy + 4}" text-anchor="middle" style="fill:var(--ink);font:600 22px sans-serif">${total}</text><text x="${cx}" y="${cy + 22}" text-anchor="middle" class="c-val">columns</text>`;
      put('c-types', svg(260, 260, s) + legend(ent.map(([k, n], i) => [kc[i % kc.length], `${k} · ${n}`])));
    }

    /* 4. nullable vs not null per layer (100% bars) */
    {
      const w = 760, L = 80, rh = 36, h = layers.length * rh + 20;
      let s = '';
      layers.forEach((l, i) => {
        const cols = T.filter((t) => t.layer === l).flatMap((t) => t.columns);
        const nn = cols.filter((c) => !c.nullable).length, nl = cols.length - nn, y = 10 + i * rh;
        const full = w - L - 20, w1 = (nn / cols.length) * full;
        s += `<text class="c-lab" x="${L - 8}" y="${y + 18}" text-anchor="end">${esc(l)}</text>`;
        s += `<rect x="${L}" y="${y + 4}" width="${w1}" height="22" fill="${css('--fk')}"><title>NOT NULL: ${nn}</title></rect>`;
        s += `<rect x="${L + w1}" y="${y + 4}" width="${full - w1}" height="22" fill="${css('--silver')}" opacity=".55"><title>NULL: ${nl}</title></rect>`;
        if (w1 > 30) s += `<text x="${L + 8}" y="${y + 19}" style="fill:#fff;font:600 11px sans-serif">${nn}</text>`;
        s += `<text x="${w - 28}" y="${y + 19}" text-anchor="end" class="c-lab">${nl}</text>`;
      });
      put('c-null', svg(w, h, s) + legend([[css('--fk'), 'NOT NULL'], [css('--silver'), 'NULL (nullable)']]));
    }

    /* 5. FK out vs in (grouped bars, tables with any FK) */
    {
      const rows = T.map((t) => ({ t, out: t.foreign_keys.length, inn: t.referenced_by.length })).filter((r) => r.out || r.inn);
      const max = Math.max(...rows.map((r) => Math.max(r.out, r.inn)), 1);
      const w = 760, L = 260, rh = 30, h = rows.length * rh + 10, scale = (w - L - 40) / max;
      let s = '';
      rows.forEach((r, i) => {
        const y = 5 + i * rh;
        s += `<text class="c-lab" x="${L - 8}" y="${y + 18}" text-anchor="end">${esc(r.t.full)}</text>`;
        s += `<rect x="${L}" y="${y + 2}" width="${r.out * scale}" height="11" rx="2" fill="${css('--fk')}"><title>${r.out} outgoing</title></rect>`;
        s += `<rect x="${L}" y="${y + 15}" width="${r.inn * scale}" height="11" rx="2" fill="${css('--pk')}"><title>${r.inn} incoming</title></rect>`;
        if (r.out) s += `<text class="c-val" x="${L + r.out * scale + 5}" y="${y + 12}">${r.out}</text>`;
        if (r.inn) s += `<text class="c-val" x="${L + r.inn * scale + 5}" y="${y + 25}">${r.inn}</text>`;
      });
      put('c-fk', svg(w, h, s) + legend([[css('--fk'), 'outgoing (references)'], [css('--pk'), 'incoming (referenced by)']]));
    }

    /* 6. procedure x table matrix */
    {
      const procs = d.procedures;
      const tabs = T.filter((t) => procs.some((p) => p.reads.includes(t.full) || p.writes.includes(t.full)));
      const L = 260, cw = 130, rh = 24, w = L + procs.length * cw + 10, h = 40 + tabs.length * rh;
      let s = '';
      procs.forEach((p, j) => (s += `<text class="c-lab" x="${L + j * cw + cw / 2}" y="22" text-anchor="middle">${esc(p.full)}</text>`));
      tabs.forEach((t, i) => {
        const y = 36 + i * rh;
        s += `<text class="c-lab" x="${L - 8}" y="${y + 16}" text-anchor="end">${esc(t.full)}</text>`;
        procs.forEach((p, j) => {
          const x = L + j * cw, ops = (p.operations[t.full] || []).map((o) => ({ INSERT: 'I', DELETE: 'D', TRUNCATE: 'T', 'BULK INSERT': 'B' }[o] || o[0]));
          const w_ = p.writes.includes(t.full), r_ = p.reads.includes(t.full);
          const fill = w_ ? layerCol(t.layer) : r_ ? css('--grid') : 'none';
          s += `<rect x="${x + 2}" y="${y + 2}" width="${cw - 4}" height="${rh - 4}" rx="4" fill="${fill}" stroke="${css('--line')}"><title>${esc(p.full)} → ${esc(t.full)}: ${w_ ? 'writes ' + ops.join('') : ''}${r_ ? ' reads' : ''}</title></rect>`;
          const lab = (w_ ? ops.join('·') : '') + (r_ ? (w_ ? ' + R' : 'R') : '');
          if (lab) s += `<text x="${x + cw / 2}" y="${y + 16}" text-anchor="middle" style="fill:${w_ ? '#fff' : 'var(--ink)'};font:600 11px sans-serif">${lab}</text>`;
        });
      });
      put('c-matrix', svg(w, h, s) + `<div class="leg"><span>I insert · D delete · T truncate · B bulk insert · R read. Colored cells = writes.</span></div>`);
    }
  }
})();
