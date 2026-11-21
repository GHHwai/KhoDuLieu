/* Finder map: real map (Leaflet + OpenStreetMap tiles); falls back to a plain dot map offline. */
(function () {
  const host = document.getElementById('finder-map');
  if (!host) return;
  const center = JSON.parse(host.dataset.center), pts = JSON.parse(host.dataset.points);
  const esc = (s) => String(s).replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));

  if (window.L) {
    const map = L.map(host, { scrollWheelZoom: false });
    L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
      maxZoom: 18,
      attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors',
    }).addTo(map);

    const bounds = [[center.lat, center.lon]];
    L.marker([center.lat, center.lon], {
      icon: L.divIcon({ className: '', html: '<div class="pin me"></div>', iconSize: [18, 18], iconAnchor: [9, 9] }),
      zIndexOffset: 1000,
    }).addTo(map).bindPopup('Search point');

    pts.forEach((p, i) => {
      L.marker([p.lat, p.lon], {
        icon: L.divIcon({ className: '', html: `<div class="pin">${i + 1}</div>`, iconSize: [26, 26], iconAnchor: [13, 13] }),
      }).addTo(map).bindPopup(`<b>${i + 1}. ${esc(p.name)}</b>${p.miles !== undefined ? `<br>${p.miles} miles` : ''}`);
      bounds.push([p.lat, p.lon]);
    });

    map.fitBounds(bounds, { padding: [30, 30], maxZoom: 14 });
    // Wheel zoom only after the map is clicked, so the page still scrolls normally.
    map.on('click', () => map.scrollWheelZoom.enable());
    return;
  }

  /* ---- fallback: plain dot map (no tiles) ---- */
  const all = pts.concat([center]);
  const lats = all.map((p) => p.lat), lons = all.map((p) => p.lon);
  const y0 = Math.min(...lats), y1 = Math.max(...lats), x0 = Math.min(...lons), x1 = Math.max(...lons);
  const k = Math.cos((((y0 + y1) / 2) * Math.PI) / 180);
  const w = 420, h = 360, pad = 34;
  const spanX = Math.max((x1 - x0) * k, 0.02), spanY = Math.max(y1 - y0, 0.02);
  const sc = Math.min((w - pad * 2) / spanX, (h - pad * 2) / spanY);
  const ox = (w - spanX * sc) / 2, oy = (h - spanY * sc) / 2;
  const X = (lon) => ox + (lon - x0) * k * sc, Y = (lat) => h - oy - (lat - y0) * sc;
  let s = '';
  pts.forEach((p, i) => {
    s += `<circle cx="${X(p.lon)}" cy="${Y(p.lat)}" r="11" fill="var(--gold)"><title>${esc(p.name)}</title></circle>`;
    s += `<text x="${X(p.lon)}" y="${Y(p.lat) + 4}" text-anchor="middle" style="fill:#fff;font:700 11px sans-serif">${i + 1}</text>`;
  });
  s += `<rect x="${X(center.lon) - 6}" y="${Y(center.lat) - 6}" width="12" height="12" fill="var(--fk)"><title>Search point</title></rect>`;
  host.innerHTML = `<svg viewBox="0 0 ${w} ${h}" style="width:100%;height:100%" role="img" aria-label="Map of the closest sites">${s}</svg>`;
})();
