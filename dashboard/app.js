import { initializeApp } from 'https://www.gstatic.com/firebasejs/11.9.0/firebase-app.js';
  import { getFirestore, collection, addDoc, getDocs, query, where, orderBy, serverTimestamp, onSnapshot, doc, updateDoc } from 'https://www.gstatic.com/firebasejs/11.9.0/firebase-firestore.js';

  // Firebase config — will be filled after project setup
  const firebaseConfig = {
    apiKey: "AIzaSyA4kzkhQ9O3g5uG5i3-uJ0IkK4OU7hOBiM",
    authDomain: "alerta-cbba-2026.firebaseapp.com",
    projectId: "alerta-cbba-2026",
    storageBucket: "alerta-cbba-2026.firebasestorage.app",
    messagingSenderId: "970959623297",
    appId: "1:970959623297:web:7d8f9a32de95685edda980"
  };

  const app = initializeApp(firebaseConfig);
  const db = getFirestore(app);

  // Expose to global scope for use in existing script
  window.fbDb = db;
  window.fbCollection = collection;
  window.fbAddDoc = addDoc;
  window.fbGetDocs = getDocs;
  window.fbQuery = query;
  window.fbWhere = where;
  window.fbOrderBy = orderBy;
  window.fbServerTimestamp = serverTimestamp;
  window.fbOnSnapshot = onSnapshot;
  window.fbDoc = doc;
  window.fbUpdateDoc = updateDoc;
  window.firebaseReady = true;

  console.log('[Firebase] SDK cargado correctamente');

// ---- BOUNDS ----
const BOL = { w:-69.65, s:-22.9, e:-57.45, n:-9.67 };
const REGIONS = {
  occ: { w:-69.65, s:-22.9, e:-63.5,  n:-14.0, name:'Occidente' },
  ori: { w:-63.5,  s:-22.9, e:-57.45, n:-14.0, name:'Oriente' },
  ama: { w:-69.65, s:-14.0, e:-57.45, n:-9.67,  name:'Amazonía' },
};

// ---- STATE ----
let fires = [];
let activeSensor = 'VIIRS_NOAA20_NRT';
let activeDays   = '1';
let activeRegion = 'ALL';
let activeFRP    = 'ALL';
let markers = [];

// ---- MAP ----
const map = L.map('map', { zoomControl:true }).setView([-16.5, -64.5], 6);
L.tileLayer('https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png', {
  attribution:'&copy; OpenStreetMap &copy; CARTO', subdomains:'abcd', maxZoom:19
}).addTo(map);
L.rectangle([[-22.9,-69.65],[-9.67,-57.45]], {
  color:'#4ECDC4', weight:1.2, fill:false, dashArray:'5 5', opacity:.35
}).addTo(map);

// ---- HELPERS ----
function frpColor(frp) {
  if (frp > 50) return '#FF4757';
  if (frp > 10) return '#FF6B35';
  return '#F7B731';
}
function frpLabel(frp) {
  if (frp > 50) return ['Alta','b-high'];
  if (frp > 10) return ['Media','b-med'];
  return ['Baja','b-nom'];
}
function frpSize(frp) {
  if (frp > 100) return 14;
  if (frp > 50)  return 11;
  if (frp > 10)  return 8;
  return 6;
}
function regionName(lat, lon) {
  for (const [k, r] of Object.entries(REGIONS)) {
    if (lat>=r.s && lat<=r.n && lon>=r.w && lon<=r.e) return r.name;
  }
  return '';
}
function makeIcon(frp) {
  const c = frpColor(frp);
  const sz = frpSize(frp);
  return L.divIcon({
    className:'',
    html:`<div class="pm-dot" style="width:${sz}px;height:${sz}px;background:${c};color:${c};box-shadow:0 0 6px ${c};"></div>`,
    iconSize:[sz,sz], iconAnchor:[sz/2,sz/2]
  });
}
function clearMarkers() { markers.forEach(m=>map.removeLayer(m)); markers=[]; }

// ---- PARSE CSV ----
function parseCSV(text) {
  const lines = text.trim().split('\n');
  if (lines.length < 2) return [];
  const headers = lines[0].split(',').map(h=>h.trim());
  return lines.slice(1).map(line => {
    const vals = line.split(',');
    const obj = {};
    headers.forEach((h,i) => obj[h] = vals[i]?.trim());
    return obj;
  }).filter(r => r.latitude && r.longitude);
}

// ---- FILTER ----
function filtered() {
  return fires.filter(f => {
    const lat = parseFloat(f.latitude);
    const lon = parseFloat(f.longitude);
    const frp = parseFloat(f.frp || 0);

    if (activeRegion !== 'ALL') {
      const r = REGIONS[activeRegion];
      if (lat<r.s||lat>r.n||lon<r.w||lon>r.e) return false;
    }
    if (activeFRP === 'high' && frp <= 50) return false;
    if (activeFRP === 'med'  && (frp<=10||frp>50)) return false;
    if (activeFRP === 'low'  && frp > 10) return false;
    return true;
  });
}

// ---- RENDER MAP ----
function plotFires(data) {
  clearMarkers();
  data.forEach(f => {
    const lat = parseFloat(f.latitude);
    const lon = parseFloat(f.longitude);
    const frp = parseFloat(f.frp || 0);
    const acq = f.acq_date || '';
    const time = f.acq_time || '';
    const conf = f.confidence || f.conf || '—';
    const reg = regionName(lat, lon);
    const [fl, fc] = frpLabel(frp);

    const m = L.marker([lat,lon], { icon:makeIcon(frp) }).addTo(map);
    const popupId = `fire-${lat.toFixed(4)}-${lon.toFixed(4)}`;
    m.bindPopup(`
      <div class="pt">🔥 Foco activo</div>
      <div class="pm">
        FRP: <span class="pfrp">${frp.toFixed(1)} MW</span> — ${fl}<br>
        Fecha: ${acq} ${time.slice(0,2)}:${time.slice(2)}<br>
        Confianza: ${conf}<br>
        Coords: ${lat.toFixed(3)}, ${lon.toFixed(3)}<br>
        ${reg ? `Región: ${reg}` : ''}
      </div>
      <button class="dispatch-btn" id="dsp-${popupId}" onclick="dispatchAlert(${lat},${lon},${frp},'${conf}','${acq}','${activeSensor}','${reg}','urgente',this)">
        🚨 ENVIAR AL GUARDIA (Urgente)
      </button>
      <button class="dispatch-btn-review" onclick="dispatchAlert(${lat},${lon},${frp},'${conf}','${acq}','${activeSensor}','${reg}','revision',this)">
        📋 Enviar para Revisión
      </button>
    `);
    markers.push(m);
  });
}

// ---- RENDER LIST ----
function renderList(data) {
  const el = document.getElementById('list');
  if (data.length === 0) {
    el.innerHTML = `<div class="empty"><span class="empty-ico">🗺️</span>No se detectaron focos de incendio en esta selección.</div>`;
    return;
  }
  // sort by FRP desc
  const sorted = [...data].sort((a,b) => parseFloat(b.frp||0) - parseFloat(a.frp||0));
  el.innerHTML = sorted.map(f => {
    const lat = parseFloat(f.latitude);
    const lon = parseFloat(f.longitude);
    const frp = parseFloat(f.frp||0);
    const [fl, fc] = frpLabel(frp);
    const reg = regionName(lat,lon);
    const conf = f.confidence || f.conf || '—';
    return `
      <div class="card" data-lat="${lat}" data-lon="${lon}">
        <div class="card-top">
          <span style="font-size:13px">🔥</span>
          <span class="card-title">${frp.toFixed(1)} MW <span class="badge ${fc}">${fl}</span></span>
        </div>
        <div class="card-meta">
          <span>${f.acq_date || ''}</span>
          <span>${lat.toFixed(2)}, ${lon.toFixed(2)}</span>
          ${reg ? `<span style="color:var(--sat)">${reg}</span>` : ''}
          <span>conf: ${conf}</span>
        </div>
      </div>`;
  }).join('');

  el.querySelectorAll('.card').forEach(c => {
    c.addEventListener('click', () => {
      const lat = parseFloat(c.dataset.lat);
      const lon = parseFloat(c.dataset.lon);
      if (!isNaN(lat)) map.flyTo([lat,lon], 11, { duration:1.4 });
    });
  });
}

// ---- STATS ----
function updateStats(data) {
  const high = data.filter(f=>parseFloat(f.frp||0)>50).length;
  const med  = data.filter(f=>{ const v=parseFloat(f.frp||0); return v>10&&v<=50; }).length;
  document.getElementById('s-high').textContent  = high;
  document.getElementById('s-med').textContent   = med;
  document.getElementById('s-total').textContent = data.length;

  if (high >= 3) {
    document.getElementById('alert-txt').textContent =
      `${high} focos de ALTA potencia (>50 MW) detectados en Bolivia. Riesgo elevado.`;
    document.getElementById('alert-banner').classList.add('on');
  } else {
    document.getElementById('alert-banner').classList.remove('on');
  }
}

// ---- APPLY ----
function apply() {
  const f = filtered();
  plotFires(f);
  renderList(f);
  updateStats(fires); // stats always on full Bolivia data
  if (fires.length > 0) saveHistoricalData(fires);
}

// ---- FETCH ----
function getMapKey() {
  const inputEl = document.getElementById('map-key');
  return inputEl ? inputEl.value.trim() : '2f9b09b9de898d0ba26a41145baffb46';
}

async function loadFires() {
  const mapKey = getMapKey();
  if (!mapKey) {
    showToast('⚠️ Por favor ingresa una MAP KEY de NASA FIRMS', 'warn');
    document.getElementById('status').textContent = 'Falta MAP KEY';
    document.getElementById('list').innerHTML = '<div class="loading">Ingresa tu MAP KEY y presiona "Cargar datos"</div>';
    return;
  }

  // Guardar la clave en localStorage
  localStorage.setItem('firms_map_key', mapKey);

  // Actualizar el enlace de transacciones
  const statusLink = document.getElementById('mapkey-status-link');
  if (statusLink) {
    statusLink.href = `https://firms.modaps.eosdis.nasa.gov/mapserver/mapkey_status/?MAP_KEY=${mapKey}`;
  }

  document.getElementById('status').textContent = 'Descargando…';
  document.getElementById('list').innerHTML = '<div class="loading">Consultando FIRMS…</div>';

  const bbox = `${BOL.w},${BOL.s},${BOL.e},${BOL.n}`;
  const url = `https://firms.modaps.eosdis.nasa.gov/api/area/csv/${mapKey}/${activeSensor}/${bbox}/${activeDays}`;

  try {
    const res = await fetch(url);
    if (!res.ok) throw new Error(`HTTP ${res.status}`);
    const text = await res.text();

    if (text.includes('Invalid MAP_KEY') || text.includes('Invalid key')) {
      throw new Error('MAP KEY inválida.');
    }

    fires = parseCSV(text);
    apply();

    const now = new Date().toLocaleTimeString('es-BO',{hour:'2-digit',minute:'2-digit'});
    document.getElementById('status').textContent = `${fires.length} focos · ${now}`;
  } catch(err) {
    document.getElementById('status').textContent = 'Error';
    document.getElementById('list').innerHTML = `
      <div class="empty">
        <span class="empty-ico">📡</span>
        ${err.message}<br><br>
        <button onclick="loadFires()" style="font-family:var(--mono);font-size:11px;background:var(--panel-2);color:var(--sat);border:1px solid var(--sat);padding:6px 14px;border-radius:100px;cursor:pointer;">↺ Reintentar</button>
      </div>`;
  }
}

// Auto-carga al abrir
window.addEventListener('load', () => {
  const savedKey = localStorage.getItem('firms_map_key');
  const inputEl = document.getElementById('map-key');
  if (savedKey && inputEl) {
    inputEl.value = savedKey;
  }
  loadFires();
});
// Auto-refresh cada 10 minutos
setInterval(loadFires, 10 * 60 * 1000);

// ---- TABS & CHIPS ----
document.getElementById('sensor-tabs').addEventListener('click', e => {
  const t = e.target.closest('.tab'); if(!t) return;
  activeSensor = t.dataset.s;
  document.querySelectorAll('#sensor-tabs .tab').forEach(x=>x.classList.remove('on'));
  t.classList.add('on');
  if (fires.length) loadFires();
});

document.getElementById('day-tabs').addEventListener('click', e => {
  const t = e.target.closest('.tab'); if(!t) return;
  activeDays = t.dataset.d;
  document.querySelectorAll('#day-tabs .tab').forEach(x=>x.classList.remove('on'));
  t.classList.add('on');
  if (fires.length) loadFires();
});

document.getElementById('region-chips').addEventListener('click', e => {
  const t = e.target.closest('.chip'); if(!t) return;
  activeRegion = t.dataset.r;
  document.querySelectorAll('#region-chips .chip').forEach(x=>x.classList.remove('on'));
  t.classList.add('on');
  if (activeRegion === 'ALL') {
    map.flyTo([-16.5,-64.5], 6, {duration:1});
  } else {
    const r = REGIONS[activeRegion];
    map.flyToBounds([[r.s,r.w],[r.n,r.e]], {padding:[30,30],duration:1});
  }
  apply();
});

document.getElementById('frp-chips').addEventListener('click', e => {
  const t = e.target.closest('.chip'); if(!t) return;
  activeFRP = t.dataset.f;
  document.querySelectorAll('#frp-chips .chip').forEach(x=>x.classList.remove('on'));
  t.classList.add('on');
  apply();
});

// ═══════════════════════════════════════════
// GUARD CHECKPOINT SYSTEM (con Firebase)
// ═══════════════════════════════════════════
let guardMode = false;
let guardMarkers = [];
let guardCount = 0;
const guardNames = ['Sgt. Mamani', 'Cap. Quispe', 'Tte. Flores', 'Sgt. Condori', 'Vol. García', 'Tte. Rojas', 'Cap. López'];
const guardRoles = ['Guardabosque', 'Bombero', 'Voluntario SAR', 'Guardabosque', 'Voluntario SAR', 'Bombero', 'Guardabosque'];

function toggleGuardMode() {
  guardMode = !guardMode;
  const btn = document.getElementById('guard-toggle');
  if (guardMode) {
    btn.classList.add('on');
    btn.textContent = '✋ Modo Guardia ACTIVO';
    map.getContainer().style.cursor = 'crosshair';
    showToast('📍 Haz clic en el mapa para colocar un punto de vigilancia', 'warn');
  } else {
    btn.classList.remove('on');
    btn.textContent = '📍 Colocar Guardia';
    map.getContainer().style.cursor = '';
  }
}

function clearGuards() {
  guardMarkers.forEach(m => map.removeLayer(m));
  guardMarkers = [];
  guardCount = 0;
  document.getElementById('guard-count').textContent = '0 guardias';
}

map.on('click', async function(e) {
  if (!guardMode) return;
  const {lat, lng} = e.latlng;
  const name = guardNames[guardCount % guardNames.length];
  const role = guardRoles[guardCount % guardRoles.length];
  guardCount++;

  // Generar credenciales de login para este guardia
  const username = `guardia${guardCount}`;
  const password = `alerta${guardCount}`;

  const guardIcon = L.divIcon({
    className: '',
    html: `<div style="width:14px;height:14px;background:#2ED573;border:2.5px solid #fff;border-radius:50%;box-shadow:0 0 8px rgba(46,213,115,0.5);position:relative;"><div style="position:absolute;inset:0;border-radius:50%;animation:pr 2.5s ease-out infinite;color:#2ED573;"></div></div>`,
    iconSize: [14, 14],
    iconAnchor: [7, 7]
  });

  const m = L.marker([lat, lng], { icon: guardIcon }).addTo(map);
  m.bindPopup(`
    <div class="guard-popup-name">🛡️ ${name}</div>
    <div class="guard-popup-meta">
      Rol: ${role}<br>
      Coords: ${lat.toFixed(4)}, ${lng.toFixed(4)}<br>
      Estado: <span style="color:#2ED573">En servicio</span><br>
      Radio cobertura: ~5 km<br>
      <span style="color:#F7B731;">👤 Usuario: <b>${username}</b></span><br>
      <span style="color:#F7B731;">🔑 Clave: <b>${password}</b></span>
    </div>
  `);
  guardMarkers.push(m);
  document.getElementById('guard-count').textContent = `${guardCount} guardias`;

  // Guardar en Firebase para que la App pueda autenticarse
  if (window.firebaseReady && window.fbDb) {
    try {
      await window.fbAddDoc(window.fbCollection(window.fbDb, 'guards'), {
        name: name,
        role: role,
        username: username,
        password: password,
        lat: lat,
        lon: lng,
        status: 'active',
        assigned_at: new Date().toISOString(),
        created_at: window.fbServerTimestamp()
      });
      console.log(`[Firebase] Guardia ${name} guardado con usuario: ${username}`);
    } catch(err) {
      console.warn('[Firebase] Error guardando guardia:', err.message);
    }
  }

  showToast(`✅ ${name} (${role}) registrado — Usuario: ${username} / Clave: ${password}`, 'success');
});

// ═══════════════════════════════════════════
// DISPATCH ALERTS TO FIREBASE
// ═══════════════════════════════════════════
let dispatchedCount = 0;

async function dispatchAlert(lat, lon, frp, conf, date, sensor, region, type, btn) {
  if (btn.classList.contains('sent')) return;

  const alertData = {
    lat: lat,
    lon: lon,
    frp: frp,
    confidence: conf,
    acq_date: date,
    sensor: sensor,
    region: region || 'Bolivia',
    type: type, // 'urgente' or 'revision'
    status: 'pending',
    dispatched_at: new Date().toISOString(),
    dispatched_by: 'Operador Plataforma',
  };

  // Save to Firebase if available
  if (window.firebaseReady && window.fbDb) {
    try {
      await window.fbAddDoc(window.fbCollection(window.fbDb, 'alerts'), {
        ...alertData,
        created_at: window.fbServerTimestamp()
      });
      console.log('[Firebase] Alerta guardada en Firestore');
    } catch(err) {
      console.warn('[Firebase] Error:', err.message);
    }
  }

  // Save to localStorage as backup
  const stored = JSON.parse(localStorage.getItem('alertacbba_dispatched') || '[]');
  stored.push(alertData);
  localStorage.setItem('alertacbba_dispatched', JSON.stringify(stored));

  btn.classList.add('sent');
  btn.innerHTML = type === 'urgente' ? '✓ ENVIADO AL GUARDIA' : '✓ ENVIADO PARA REVISIÓN';
  dispatchedCount++;
  document.getElementById('hist-alerts').textContent = dispatchedCount;

  const emoji = type === 'urgente' ? '🚨' : '📋';
  showToast(`${emoji} Alerta ${type.toUpperCase()} enviada — FRP ${frp.toFixed(1)} MW en ${region || 'Bolivia'}`, type === 'urgente' ? 'warn' : 'success');
}

// ═══════════════════════════════════════════
// HISTORICAL DATA (saved on every load)
// ═══════════════════════════════════════════
async function saveHistoricalData(data) {
  const today = new Date().toISOString().split('T')[0];
  const key = `alertacbba_hist_${today}`;
  const existing = JSON.parse(localStorage.getItem(key) || '[]');

  // Merge — only add unique fires by coords
  const existingCoords = new Set(existing.map(e => `${e.latitude}_${e.longitude}`));
  const newFires = data.filter(f => !existingCoords.has(`${f.latitude}_${f.longitude}`));
  const merged = [...existing, ...newFires];
  localStorage.setItem(key, JSON.stringify(merged));

  // Firebase — save batch
  if (window.firebaseReady && window.fbDb && newFires.length > 0) {
    try {
      for (const f of newFires.slice(0, 20)) { // limit to avoid quota
        await window.fbAddDoc(window.fbCollection(window.fbDb, 'historical_data'), {
          latitude: parseFloat(f.latitude),
          longitude: parseFloat(f.longitude),
          frp: parseFloat(f.frp || 0),
          confidence: f.confidence || f.conf || '',
          sensor: activeSensor,
          acq_date: f.acq_date || today,
          acq_time: f.acq_time || '',
          saved_at: window.fbServerTimestamp()
        });
      }
      console.log(`[Firebase] ${newFires.length} registros históricos guardados`);
    } catch(err) {
      console.warn('[Firebase] Historical save error:', err.message);
    }
  }

  // Update UI
  document.getElementById('hist-today').textContent = merged.length;

  // Count all historical
  let totalHist = 0;
  for (let i = 0; i < localStorage.length; i++) {
    const k = localStorage.key(i);
    if (k.startsWith('alertacbba_hist_')) {
      totalHist += JSON.parse(localStorage.getItem(k)).length;
    }
  }
  document.getElementById('hist-total').textContent = totalHist;
}

// (Hook removed, functionality merged directly into main apply() function)

// ═══════════════════════════════════════════
// TOAST NOTIFICATIONS
// ═══════════════════════════════════════════
function showToast(msg, type = 'success') {
  const stack = document.getElementById('toast-stack');
  const toast = document.createElement('div');
  toast.className = `toast-msg t-${type}`;
  const icon = type === 'warn' ? '🔥' : '✅';
  toast.innerHTML = `<span>${icon}</span><span>${msg}</span>`;
  stack.appendChild(toast);
  setTimeout(() => {
    toast.style.animation = 'slideOut .3s ease-in forwards';
    setTimeout(() => toast.remove(), 300);
  }, 4000);
}

// Init dispatched count
document.getElementById('hist-alerts').textContent = JSON.parse(localStorage.getItem('alertacbba_dispatched') || '[]').length;
dispatchedCount = JSON.parse(localStorage.getItem('alertacbba_dispatched') || '[]').length;

window.loadFires = loadFires;
window.toggleGuardMode = toggleGuardMode;
window.clearGuards = clearGuards;
window.dispatchAlert = dispatchAlert;
