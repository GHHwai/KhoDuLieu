/* Schema visualiser: ER diagram + pipeline view (plain SVG, no dependencies). */
(function () {
  const svg = document.getElementById('canvas');
  if (!svg) return;
  const NS = 'http://www.w3.org/2000/svg';
  const mode = svg.dataset.mode;
  const css = (n) => `var(${n})`;
  const layerColor = (l) => `var(--${l}, var(--muted))`;
  const el = (name, attrs = {}, parent) => {
    const e = document.createElementNS(NS, name);
    for (const k in attrs) e.setAttribute(k, attrs[k]);
    if (parent) parent.appendChild(e);
    return e;
  };
  const text = (parent, x, y, s, cls, extra = {}) => {
    const t = el('text', Object.assign({ x, y, class: cls }, extra), parent);
    t.textContent = s;
    return t;
  };

  const root = el('g', {}, svg);
  const edgeLayer = el('g', {}, root);
  const nodeLayer = el('g', {}, root);
  const view = { x: 0, y: 0, k: 1 };
  const applyView = () => root.setAttribute('transform', `translate(${view.x} ${view.y}) scale(${view.k})`);

  let nodes = {}; // id -> {x,y,w,h,g,rows:{col:y}}
  let edges = [];

  fetch(svg.dataset.url).then((r) => r.json()).then((data) => {
    mode === 'er' ? buildER(data) : buildPipeline(data);
    fit();
  });

  /* ------------------------------------------------------------ ER */
  const ROW = 20, HEAD = 30, W = 270, MAXROWS = 14;

  function buildER(data) {
    const tables = data.tables;
    const active = {};
    data.schemas.forEach((s) => (active[s.toLowerCase()] = s.toLowerCase() !== 'bronze'));

    const toggles = document.getElementById('layer-toggles');
    data.schemas.forEach((s) => {
      const b = document.createElement('button');
      b.className = 'toggle' + (active[s.toLowerCase()] ? '' : ' off');
      b.innerHTML = `<span class="dot layer-${s.toLowerCase()}"></span>${s}`;
      b.onclick = () => {
        active[s.toLowerCase()] = !active[s.toLowerCase()];
        b.classList.toggle('off');
        render();
        fit();
      };
      toggles.appendChild(b);
    });

    const pos = {}; // remembered drag positions
    function render() {
      edgeLayer.innerHTML = '';
      nodeLayer.innerHTML = '';
      nodes = {};
      edges = [];
      const shown = tables.filter((t) => active[t.layer]);

      // column slot: layer order, with referencing (fact-like) tables to the right of their parents
      const order = {};
      data.schemas.forEach((s, i) => (order[s.toLowerCase()] = i));
      const colOf = (t) => order[t.layer] * 2 + (t.foreign_keys.length ? 1 : 0);
      const cols = {};
      shown.forEach((t) => (cols[colOf(t)] = cols[colOf(t)] || []).push(t));
      const colKeys = Object.keys(cols).map(Number).sort((a, b) => a - b);

      colKeys.forEach((ck, ci) => {
        let y = 20;
        cols[ck].forEach((t) => {
          const rows = visibleRows(t);
          const h = HEAD + rows.length * ROW + (t.columns.length > rows.length ? ROW : 0) + 8;
          const p = pos[t.full] || { x: 20 + ci * (W + 110), y };
          drawTable(t, rows, p.x, p.y, h);
          y += h + 26;
        });
      });

      tables_fk(shown);
      drawEdges();
    }

    function visibleRows(t) {
      if (t.columns.length <= MAXROWS) return t.columns;
      const key = t.columns.filter((c) => c.pk || c.fk);
      const rest = t.columns.filter((c) => !(c.pk || c.fk));
      return key.concat(rest).slice(0, MAXROWS - 1).concat([]);
    }

    function drawTable(t, rows, x, y, h) {
      const g = el('g', { class: 'node', transform: `translate(${x} ${y})` }, nodeLayer);
      el('rect', { class: 'node-box', width: W, height: h, rx: 8 }, g);
      el('path', { d: `M0 8a8 8 0 0 1 8-8h${W - 16}a8 8 0 0 1 8 8v${HEAD - 8}H0z`, fill: layerColor(t.layer) }, g);
      text(g, 12, 20, t.name, 'svg-h');
      text(g, W - 12, 20, t.kind, 'svg-h', { 'text-anchor': 'end', opacity: 0.8 });
      const rowY = {};
      rows.forEach((c, i) => {
        const cy = HEAD + i * ROW + 15;
        rowY[c.name] = HEAD + i * ROW + ROW / 2;
        if (c.pk || c.fk) el('rect', { x: 8, y: cy - 10, width: 4, height: 14, rx: 2, fill: css(c.pk ? '--pk' : '--fk') }, g);
        text(g, 18, cy, c.name.length > 27 ? c.name.slice(0, 26) + '\u2026' : c.name, 'svg-t');
        text(g, W - 10, cy, c.type_full, 'svg-m', { 'text-anchor': 'end' });
      });
      if (t.columns.length > rows.length) text(g, 18, HEAD + rows.length * ROW + 15, `\u2026 ${t.columns.length - rows.length} more columns`, 'svg-m');
      nodes[t.full] = { x, y, w: W, h, g, rowY, t };
      makeDraggable(g, t.full);
      g.addEventListener('mouseenter', () => highlight(t.full));
      g.addEventListener('mouseleave', () => highlight(null));
      g.addEventListener('dblclick', () => (location.href = `${svg.dataset.tableUrl}/${t.schema}/${t.name}`));
    }

    function tables_fk(shown) {
      const ids = new Set(shown.map((t) => t.full));
      data.relationships.forEach((r) => {
        if (ids.has(r.table) && ids.has(r.ref_table)) {
          edges.push({ from: r.table, fromCol: r.columns[0], to: r.ref_table, toCol: r.ref_columns[0], path: el('path', { class: 'edge' }, edgeLayer) });
        }
      });
    }

    window.__pos = pos;
    render();
  }

  function anchor(n, col, towardX) {
    const y = n.y + (n.rowY && n.rowY[col] !== undefined ? n.rowY[col] : HEAD / 2);
    const left = towardX < n.x + n.w / 2;
    return { x: left ? n.x : n.x + n.w, y, dir: left ? -1 : 1 };
  }

  function drawEdges() {
    edges.forEach((e) => {
      const a = nodes[e.from], b = nodes[e.to];
      if (!a || !b) return;
      const ac = a.x + a.w / 2, bc = b.x + b.w / 2;
      const p1 = anchor(a, e.fromCol, bc), p2 = anchor(b, e.toCol, ac);
      const d = Math.max(40, Math.abs(p2.x - p1.x) / 2);
      e.path.setAttribute('d', `M${p1.x} ${p1.y} C${p1.x + p1.dir * d} ${p1.y} ${p2.x + p2.dir * d} ${p2.y} ${p2.x} ${p2.y}`);
    });
  }

  function highlight(id) {
    const linked = new Set(id ? [id] : []);
    edges.forEach((e) => {
      const hot = id && (e.from === id || e.to === id);
      if (hot) { linked.add(e.from); linked.add(e.to); }
      e.path.classList.toggle('hot', !!hot);
      e.path.classList.toggle('dim', !!id && !hot);
    });
    Object.entries(nodes).forEach(([k, n]) => n.g.classList.toggle('dim', !!id && !linked.has(k)));
  }

  /* ------------------------------------------------------- pipeline */
  function buildPipeline(data) {
    const NW = 210, NH = 34;
    const procIds = new Set(data.procedures.map((p) => p.full));
    const info = {};
    const ensure = (id, type, label, extra = {}) => (info[id] = info[id] || Object.assign({ id, type, label }, extra));
    data.tables.forEach((t) => ensure(t.full, 'table', t.name, { layer: t.layer, sub: t.schema }));
    data.procedures.forEach((p) => ensure(p.full, 'proc', p.name, { layer: p.schema.toLowerCase(), sub: p.schema }));

    const es = [];
    data.lineage.forEach((l) => es.push({ from: l.from, to: l.to }));
    data.procedures.forEach((p) => {
      if (p.source_file) {
        const id = 'file:' + p.source_file;
        ensure(id, 'file', p.source_file, { layer: 'file', sub: 'source file' });
        es.push({ from: id, to: p.full });
      }
    });

    // keep only nodes that take part in the flow
    const used = new Set();
    es.forEach((e) => { used.add(e.from); used.add(e.to); });

    // longest-path depth
    const depth = {};
    used.forEach((id) => (depth[id] = 0));
    for (let i = 0; i < used.size; i++) {
      let changed = false;
      es.forEach((e) => { if (depth[e.to] < depth[e.from] + 1) { depth[e.to] = depth[e.from] + 1; changed = true; } });
      if (!changed) break;
    }
    const byDepth = {};
    used.forEach((id) => (byDepth[depth[id]] = byDepth[depth[id]] || []).push(id));

    Object.keys(byDepth).map(Number).sort((a, b) => a - b).forEach((d) => {
      byDepth[d].forEach((id, i) => drawNode(info[id], 20 + d * (NW + 70), 20 + i * (NH + 14), NW, NH));
    });
    es.forEach((e) => edges.push({ from: e.from, to: e.to, path: el('path', { class: 'edge' }, edgeLayer), pipe: true }));
    drawEdges2();

    function drawNode(n, x, y, w, h) {
      const g = el('g', { class: 'node', transform: `translate(${x} ${y})` }, nodeLayer);
      const color = n.layer === 'file' ? css('--muted') : layerColor(n.layer);
      el('rect', { class: 'node-box', width: w, height: h, rx: n.type === 'proc' ? 17 : 7, stroke: color, 'stroke-width': n.type === 'proc' ? 2 : 1.2, 'stroke-dasharray': n.type === 'file' ? '4 3' : '' }, g);
      el('rect', { x: 0, y: 0, width: 5, height: h, rx: 2, fill: color }, g);
      text(g, 16, 15, (n.type === 'proc' ? 'ƒ ' : '') + n.label, 'svg-t');
      text(g, 16, 28, n.sub, 'svg-m');
      nodes[n.id] = { x, y, w, h, g, rowY: {} };
      makeDraggable(g, n.id, drawEdges2);
      g.addEventListener('mouseenter', () => highlight(n.id));
      g.addEventListener('mouseleave', () => highlight(null));
      g.addEventListener('dblclick', () => {
        if (n.type === 'proc') location.href = `${svg.dataset.procUrl}/${n.id.replace('.', '/')}`;
        else if (n.type === 'table') location.href = `${svg.dataset.tableUrl}/${n.id.replace('.', '/')}`;
      });
    }
  }

  function drawEdges2() {
    edges.forEach((e) => {
      const a = nodes[e.from], b = nodes[e.to];
      if (!a || !b) return;
      const x1 = a.x + a.w, y1 = a.y + a.h / 2, x2 = b.x, y2 = b.y + b.h / 2;
      const d = Math.max(30, Math.abs(x2 - x1) / 2);
      e.path.setAttribute('d', `M${x1} ${y1} C${x1 + d} ${y1} ${x2 - d} ${y2} ${x2} ${y2}`);
    });
  }

  /* --------------------------------------------------- interaction */
  function makeDraggable(g, id, after) {
    g.addEventListener('pointerdown', (ev) => {
      ev.stopPropagation();
      g.setPointerCapture(ev.pointerId);
      const n = nodes[id];
      const sx = ev.clientX, sy = ev.clientY, ox = n.x, oy = n.y;
      const move = (e) => {
        n.x = ox + (e.clientX - sx) / view.k;
        n.y = oy + (e.clientY - sy) / view.k;
        g.setAttribute('transform', `translate(${n.x} ${n.y})`);
        if (window.__pos) window.__pos[id] = { x: n.x, y: n.y };
        (after || (mode === 'er' ? drawEdges : drawEdges2))();
      };
      const up = () => { g.removeEventListener('pointermove', move); g.removeEventListener('pointerup', up); };
      g.addEventListener('pointermove', move);
      g.addEventListener('pointerup', up);
    });
  }

  svg.addEventListener('pointerdown', (ev) => {
    svg.classList.add('panning');
    const sx = ev.clientX, sy = ev.clientY, ox = view.x, oy = view.y;
    const move = (e) => { view.x = ox + e.clientX - sx; view.y = oy + e.clientY - sy; applyView(); };
    const up = () => { svg.classList.remove('panning'); window.removeEventListener('pointermove', move); window.removeEventListener('pointerup', up); };
    window.addEventListener('pointermove', move);
    window.addEventListener('pointerup', up);
  });

  function zoomAt(factor, cx, cy) {
    const k = Math.min(2.5, Math.max(0.1, view.k * factor));
    const r = k / view.k;
    view.x = cx - (cx - view.x) * r;
    view.y = cy - (cy - view.y) * r;
    view.k = k;
    applyView();
  }
  svg.addEventListener('wheel', (ev) => {
    ev.preventDefault();
    const b = svg.getBoundingClientRect();
    zoomAt(ev.deltaY < 0 ? 1.12 : 1 / 1.12, ev.clientX - b.left, ev.clientY - b.top);
  }, { passive: false });

  function fit() {
    const ns = Object.values(nodes);
    if (!ns.length) return;
    const x0 = Math.min(...ns.map((n) => n.x)), y0 = Math.min(...ns.map((n) => n.y));
    const x1 = Math.max(...ns.map((n) => n.x + n.w)), y1 = Math.max(...ns.map((n) => n.y + n.h));
    const b = svg.getBoundingClientRect();
    const k = Math.min(1, Math.min((b.width - 40) / (x1 - x0), (b.height - 40) / (y1 - y0)));
    view.k = Math.max(0.1, k);
    view.x = (b.width - (x1 - x0) * view.k) / 2 - x0 * view.k;
    view.y = (b.height - (y1 - y0) * view.k) / 2 - y0 * view.k;
    applyView();
  }

  const center = () => { const b = svg.getBoundingClientRect(); return [b.width / 2, b.height / 2]; };
  document.getElementById('zin').onclick = () => zoomAt(1.25, ...center());
  document.getElementById('zout').onclick = () => zoomAt(0.8, ...center());
  document.getElementById('zfit').onclick = fit;
})();
