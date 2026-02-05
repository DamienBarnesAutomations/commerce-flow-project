<script setup>
import { ref, onMounted } from 'vue'

const entries = ref([])
const loading = ref(false)
const error = ref(null)

const JOURNAL_WEBHOOK = import.meta.env.VITE_GET_JOURNAL_ENTRIES_WEBHOOK

async function fetchEntries() {
  loading.value = true
  error.value = null
  try {
    const res = await fetch(JOURNAL_WEBHOOK)
    if (!res.ok) throw new Error('FETCH_ERROR')
    const data = await res.json()
    entries.value = Array.isArray(data) ? data : []
  } catch (err) {
    error.value = err.message
  } finally {
    loading.value = false
  }
}

onMounted(fetchEntries)

const fmt = (val) => {
  const n = Number(val)
  return n > 0 ? n.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 }) : '—'
}
</script>

<template>
  <div class="ledger-container">
    <header class="view-header">
      <div class="title-meta">
        <h1>Journal Entries</h1>
        <div class="pill">
          <span class="pulse"></span>
          {{ entries.length }} Transactions
        </div>
      </div>

      <div class="header-actions">
        <button @click="fetchEntries" class="sync-btn" :class="{ spinning: loading }">
          <svg viewBox="0 0 24 24" width="18" height="18" stroke="currentColor" stroke-width="2.5" fill="none">
            <path d="M23 4v6h-6M1 20v-6h6M3.51 9a9 9 0 0 1 14.85-3.36L23 10M1 14l4.64 4.36A9 9 0 0 0 20.49 15"></path>
          </svg>
        </button>
        <RouterLink to="/accounting/journal/new" class="add-btn">
          <span>+ New Entry</span>
        </RouterLink>
      </div>
    </header>

    <div v-if="loading" class="empty-state">Syncing Journal Records...</div>
    <div v-else-if="error" class="empty-state error">{{ error }}</div>
    <div v-else-if="!entries.length" class="empty-state">No journal activity found.</div>

    <div v-else class="ledger-scroller">
      <div class="acct-card">
        <div class="acct-head">
          <span class="acct-id">JRNL</span>
          <span class="acct-label">General Journal Activity</span>
        </div>

        <div class="acct-entries">
          <div class="table-head">
            <div class="col-meta">Date / Ref</div>
            <div class="col-desc">Description</div>
            <div class="col-amt text-right">Debit</div>
            <div class="col-amt text-right">Credit</div>
          </div>

          <div v-for="e in entries" :key="e.id" class="entry-line">
            <div class="entry-meta col-meta">
              <span class="entry-date">{{ new Date(e.entry_date).toLocaleDateString('en-GB') }}</span>
              <span class="entry-ref">#{{ e.reference || '0000' }}</span>
            </div>
            
            <div class="entry-desc col-desc">{{ e.description }}</div>
            
            <div class="entry-values">
              <div class="v-group dr col-amt text-right">
                <span class="v-label">DEBIT</span>
                <span class="v-num">{{ fmt(e.total_debit) }}</span>
              </div>
              <div class="v-group cr col-amt text-right">
                <span class="v-label">CREDIT</span>
                <span class="v-num">{{ fmt(e.total_credit) }}</span>
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
  --accent: #10b981;
  --text-main: #fafafa;
  --text-dim: #a1a1aa;
  --dr: #4ade80;
  --cr: #f87171;
  background: var(--bg);
  min-height: 100vh;
  color: var(--text-main);
  font-family: 'Inter', -apple-system, sans-serif;
}

/* --- Header Section --- */
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

.title-meta h1 { font-size: 1.25rem; font-weight: 800; letter-spacing: -0.02em; margin: 0; }
.pill { display: flex; align-items: center; gap: 6px; font-size: 11px; color: var(--text-dim); background: #27272a; padding: 4px 10px; border-radius: 99px; margin-top: 4px; border: 1px solid var(--border); }
.pulse { width: 6px; height: 6px; background: var(--accent); border-radius: 50%; box-shadow: 0 0 8px var(--accent); }

.header-actions { display: flex; align-items: center; gap: 1.25rem; }

.sync-btn { background: none; border: none; color: var(--text-dim); cursor: pointer; transition: 0.2s; }
.sync-btn:hover { color: var(--text-main); }
.spinning { animation: spin 1s linear infinite; }
@keyframes spin { to { transform: rotate(360deg); } }

.add-btn {
  background: var(--accent);
  color: #022c22;
  text-decoration: none;
  padding: 6px 14px;
  border-radius: 6px;
  font-size: 12px;
  font-weight: 800;
  transition: opacity 0.2s;
}
.add-btn:hover { opacity: 0.9; }

/* --- Card Logic --- */
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
  background: linear-gradient(to right, rgba(16, 185, 129, 0.1), transparent);
  border-bottom: 1px solid var(--border);
  display: flex;
  align-items: center;
  gap: 12px;
}
.acct-id { background: var(--accent); color: #000; font-family: 'JetBrains Mono', monospace; font-weight: 900; padding: 2px 8px; border-radius: 4px; font-size: 0.8rem; }
.acct-label { font-weight: 700; text-transform: uppercase; letter-spacing: 0.05em; font-size: 0.85rem; color: var(--text-main); }

/* --- THE KEY FIX: Shared Grid Definition --- */
.table-head, .entry-line {
  display: grid;
  grid-template-columns: 140px 1fr 140px 140px;
  padding: 0.75rem 1.25rem; /* Strict horizontal padding sync */
  align-items: center;
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
  padding-top: 1.25rem;
  padding-bottom: 1.25rem;
  border-bottom: 1px solid var(--border);
  transition: background 0.2s;
}
.entry-line:last-child { border-bottom: none; }
.entry-line:hover { background: rgba(255,255,255,0.02); }

.entry-meta { display: flex; flex-direction: column; gap: 2px; }
.entry-date { font-family: 'JetBrains Mono', monospace; font-size: 12px; color: var(--text-main); }
.entry-ref { font-size: 10px; color: var(--text-dim); font-weight: 600; }

.entry-desc { font-size: 14px; color: #d4d4d8; line-height: 1.4; padding-right: 1.5rem; }

.entry-values { display: contents; } /* Allows dr/cr v-groups to occupy the grid columns */
.v-num { font-family: 'JetBrains Mono', monospace; font-weight: 600; font-size: 14px; }
.dr .v-num { color: var(--dr); }
.cr .v-num { color: var(--cr); }
.text-right { text-align: right; }
.v-label { display: none; } /* Hidden on desktop */

/* --- Mobile Logic --- */
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
