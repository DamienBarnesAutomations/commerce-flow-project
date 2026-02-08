<script setup>
import { ref, computed, onMounted } from 'vue'

const rawEntries = ref([])
const loading = ref(false)
const error = ref(null)

const LEDGER_WEBHOOK = import.meta.env.VITE_GET_GENERAL_LEDGER_WEBHOOK

const groupedLedger = computed(() => {
  if (!rawEntries.value.length) return {}
  return rawEntries.value.reduce((acc, entry) => {
    const key = `${entry.account_code} · ${entry.account_name}`
    if (!acc[key]) acc[key] = []
    acc[key].push(entry)
    return acc
  }, {})
})

async function fetchLedger() {
  loading.value = true
  error.value = null
  try {
    const res = await fetch(LEDGER_WEBHOOK)
    if (!res.ok) throw new Error('FETCH_ERROR')
    const data = await res.json()
    
    // Filter out empty objects [ {} ] so the array length becomes 0 if no real data exists
    if (Array.isArray(data)) {
      rawEntries.value = data.filter(entry => 
        entry && Object.keys(entry).length > 0
      )
    } else {
      rawEntries.value = []
    }
    
    // This will now show an empty array [] instead of [{}]
  } catch (err) {
    error.value = err.message
  } finally {
    loading.value = false
  }
}

onMounted(fetchLedger)

const fmt = (val) => {
  const n = Number(val)
  return n > 0 ? "$" + n.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 }) : '—'
}
</script>

<template>
  <div class="ledger-container">
    <header class="view-header">
      <div class="title-meta">
        <h1>General Ledger</h1>
        <div class="pill">
          <span class="pulse"></span>
          {{ rawEntries.length }} Entries
        </div>
      </div>
      <button @click="fetchLedger" class="sync-btn" :class="{ spinning: loading }">
        <svg viewBox="0 0 24 24" width="18" height="18" stroke="currentColor" stroke-width="2.5" fill="none"><path d="M23 4v6h-6M1 20v-6h6M3.51 9a9 9 0 0 1 14.85-3.36L23 10M1 14l4.64 4.36A9 9 0 0 0 20.49 15"></path></svg>
      </button>
    </header>

    <div v-if="loading" class="empty-state">Syncing Ledger Data...</div>
    <div v-else-if="error" class="empty-state error">{{ error }}</div>
    <div v-else-if="!groupedLedger.length" class="empty-state">No activity found.</div>

    <div v-else class="ledger-scroller">
      <div v-for="(rows, account) in groupedLedger" :key="account" class="acct-card">
        <div class="acct-head">
          <span class="acct-id">{{ account.split(' · ')[0] }}</span>
          <span class="acct-label">{{ account.split(' · ')[1] }}</span>
        </div>

        <div class="acct-entries">
          <div class="table-head">
            <div>Date / Ref</div>
            <div>Description</div>
            <div class="text-right">Debit</div>
            <div class="text-right">Credit</div>
          </div>

          <div v-for="(row, i) in rows" :key="i" class="entry-line">
            <div class="entry-meta">
              <span class="entry-date">{{ new Date(row.entry_date).toLocaleDateString('en-GB') }}</span>
              <span class="entry-ref">#{{ row.reference || '0000' }}</span>
            </div>

            <div class="entry-desc" :class="{ 'dimmed': !row.description }">
              {{ row.description || "—" }}
            </div>

            <div class="entry-values">
              <div class="v-group dr text-right">
                <span class="v-label">DR</span>
                <span class="v-num">{{ fmt(row.debit) }}</span>
              </div>
              <div class="v-group cr text-right">
                <span class="v-label">CR</span>
                <span class="v-num">{{ fmt(row.credit) }}</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.ledger-container {
  --bg: #09090b;
  --surface: #18181b;
  --border: rgba(255,255,255,0.06);
  --accent: #22d3ee;
  --text-main: #fafafa;
  --text-dim: #a1a1aa;
  --dr: #4ade80;
  --cr: #f87171;
  background: var(--bg);
  min-height: 100vh;
  color: var(--text-main);
  font-family: 'Inter', -apple-system, sans-serif;
}

.view-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1.5rem;
  border-bottom: 1px solid var(--border);
  background: rgba(9, 9, 11, 0.8);
  backdrop-filter: blur(12px);
  position: sticky;
  top: 0;
  z-index: 20;
}

.view-header h1 { font-size: 1.25rem; font-weight: 800; letter-spacing: -0.02em; margin: 0; }
.pill { display: flex; align-items: center; gap: 6px; font-size: 11px; color: var(--text-dim); background: #27272a; padding: 4px 10px; border-radius: 99px; margin-top: 4px; border: 1px solid var(--border); }
.pulse { width: 6px; height: 6px; background: var(--accent); border-radius: 50%; box-shadow: 0 0 8px var(--accent); }

.sync-btn { background: none; border: none; color: var(--text-dim); cursor: pointer; transition: 0.2s; }
.sync-btn:hover { color: var(--text-main); }
.spinning { animation: spin 1s linear infinite; }
@keyframes spin { to { transform: rotate(360deg); } }

.ledger-scroller { padding: 1rem; }
.acct-card {
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: 12px;
  margin-bottom: 2rem;
  overflow: hidden;
  box-shadow: 0 10px 30px -10px rgba(0,0,0,0.5);
}

.acct-head {
  padding: 1rem 1.25rem;
  background: linear-gradient(to right, rgba(34, 211, 238, 0.1), transparent);
  border-bottom: 1px solid var(--border);
  display: flex;
  align-items: center;
  gap: 12px;
}
.acct-id { background: var(--accent); color: #000; font-family: 'JetBrains Mono', monospace; font-weight: 900; padding: 2px 8px; border-radius: 4px; font-size: 0.9rem; }
.acct-label { font-weight: 700; text-transform: uppercase; letter-spacing: 0.05em; font-size: 0.9rem; color: var(--text-main); }

/* --- STRICT GRID SYNC --- */
.table-head, .entry-line {
  display: grid;
  grid-template-columns: 140px 1fr 140px 140px;
  padding: 0.75rem 1.25rem;
}

.table-head {
  font-size: 10px;
  font-weight: 800;
  color: var(--text-dim);
  text-transform: uppercase;
  letter-spacing: 0.1em;
  background: rgba(0,0,0,0.2);
  border-bottom: 1px solid var(--border);
}

.entry-line {
  padding: 1rem 1.25rem;
  border-bottom: 1px solid var(--border);
  align-items: center;
  transition: background 0.2s;
}
.entry-line:last-child { border-bottom: none; }
.entry-line:hover { background: rgba(255,255,255,0.02); }

.entry-meta { display: flex; flex-direction: column; gap: 2px; }
.entry-date { font-family: 'JetBrains Mono', monospace; font-size: 12px; color: var(--text-main); }
.entry-ref { font-size: 10px; color: var(--text-dim); font-weight: 600; }

.entry-desc { font-size: 14px; color: #d4d4d8; line-height: 1.4; padding-right: 1.5rem; }

/* The fix: display contents lets the children (dr/cr) jump into the 3rd and 4th columns */
.entry-values { display: contents; } 

.v-num { font-family: 'JetBrains Mono', monospace; font-weight: 600; font-size: 14px; }
.dr .v-num { color: var(--dr); }
.cr .v-num { color: var(--cr); }
.text-right { text-align: right; }
.v-label { display: none; }

/* --- MOBILE UPGRADE --- */
@media (max-width: 800px) {
  .table-head { display: none; }
  .entry-line {
    display: flex;
    flex-direction: column;
    align-items: flex-start;
    padding: 1.25rem;
    gap: 12px;
  }
  .entry-meta { flex-direction: row; justify-content: space-between; width: 100%; border-bottom: 1px solid var(--border); padding-bottom: 8px; }
  .entry-desc { font-size: 15px; font-weight: 500; color: #fff; padding-right: 0; }
  .entry-values { display: flex; width: 100%; gap: 12px; }
  .v-group {
    flex: 1;
    background: rgba(255,255,255,0.03);
    padding: 10px;
    border-radius: 6px;
    display: flex;
    flex-direction: column;
    gap: 4px;
    text-align: left !important;
  }
  .v-label { display: block; font-size: 9px; font-weight: 900; color: var(--text-dim); }
  .v-num { font-size: 16px; }
  .dr { border-left: 3px solid var(--dr); }
  .cr { border-left: 3px solid var(--cr); }
}

.empty-state { padding: 6rem 2rem; text-align: center; color: var(--text-dim); font-size: 13px; text-transform: uppercase; letter-spacing: 0.1em; }
.error { color: var(--cr); }
</style>
