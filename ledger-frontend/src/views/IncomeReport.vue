<script setup>
import { ref, computed, onMounted } from 'vue'

const rawEntries = ref([])
const loading = ref(false)
const error = ref(null)

const INCOME_WEBHOOK = import.meta.env.VITE_GET_INCOME_WEBHOOK

const groupedIncome = computed(() => {
  // If rawEntries is empty or contains the [ {} ] placeholder from n8n
  if (!rawEntries.value.length) return {}
  
  return rawEntries.value.reduce((acc, entry) => {
    // We use the 'category' alias from the SQL query (ac.label)
    const key = entry.category || 'Uncategorized Income'
    if (!acc[key]) acc[key] = []
    acc[key].push(entry)
    return acc
  }, {})
})

async function fetchIncome() {
  loading.value = true
  error.value = null
  try {
    const res = await fetch(INCOME_WEBHOOK)
    if (!res.ok) throw new Error(`SERVER_ERROR: ${res.status}`)
    
    const data = await res.json()
    
    // Filter out n8n's potential empty object return [ {} ]
    if (Array.isArray(data)) {
      rawEntries.value = data.filter(e => e && Object.keys(e).length > 0)
    } else {
      rawEntries.value = []
    }
  } catch (err) {
    error.value = err.message
    rawEntries.value = []
  } finally {
    loading.value = false
  }
}

onMounted(fetchIncome)

const fmt = (val) => {
  const n = Number(val)
  return "$" + n.toLocaleString(undefined, { 
    minimumFractionDigits: 2, 
    maximumFractionDigits: 2 
  })
}

const totalIncome = computed(() => {
  return rawEntries.value.reduce((sum, e) => sum + Number(e.amount || 0), 0)
})
</script>


<template>
  <div class="report-container income-theme">
    <header class="view-header">
      <div class="title-meta">
        <h1>Revenue Report</h1>
        <div class="pill">Total: {{ fmt(totalIncome) }}</div>
      </div>
      <button @click="fetchIncome" class="sync-btn" :class="{ spinning: loading }">
        <svg viewBox="0 0 24 24" width="18" height="18" stroke="currentColor" stroke-width="2.5" fill="none"><path d="M23 4v6h-6M1 20v-6h6M3.51 9a9 9 0 0 1 14.85-3.36L23 10M1 14l4.64 4.36A9 9 0 0 0 20.49 15"></path></svg>
      </button>
    </header>

    <div v-if="loading" class="empty-state">Calculating Revenue...</div>
    <div v-else-if="Object.keys(groupedIncome).length === 0" class="empty-state">No income recorded.</div>

    <div v-else class="ledger-scroller">
      <div v-for="(rows, category) in groupedIncome" :key="category" class="acct-card">
        <div class="acct-head">
          <span class="acct-id">INC</span>
          <span class="acct-label">{{ category }}</span>
        </div>

        <div class="acct-entries">
          <div class="table-head">
            <div>Date</div>
            <div>Source / Description</div>
            <div class="text-right">Amount</div>
          </div>

          <div v-for="(row, i) in rows" :key="i" class="entry-line">
            <div class="entry-date">{{ new Date(row.created_at).toLocaleDateString('en-GB') }}</div>
            <div class="entry-desc">{{ row.description || "Direct Sale" }}</div>
            <div class="entry-val text-right">{{ fmt(row.amount) }}</div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.income-theme { --accent: #4ade80; --bg: #09090b; --surface: #121214; --border: rgba(255,255,255,0.06); --text-main: #fafafa; --text-dim: #a1a1aa; }
.report-container { background: var(--bg); min-height: 100vh; color: var(--text-main); font-family: 'Inter', sans-serif; }
.view-header { display: flex; justify-content: space-between; padding: 1.5rem; border-bottom: 1px solid var(--border); position: sticky; top: 0; background: rgba(9,9,11,0.8); backdrop-filter: blur(10px); z-index: 10; }
.view-header h1 { font-size: 1.1rem; text-transform: uppercase; letter-spacing: 0.1em; }
.pill { font-size: 11px; background: rgba(74, 222, 128, 0.1); color: var(--accent); padding: 4px 12px; border-radius: 99px; border: 1px solid rgba(74, 222, 128, 0.2); margin-top: 5px; font-weight: 700; }
.acct-card { background: var(--surface); border: 1px solid var(--border); border-radius: 12px; margin: 1rem; overflow: hidden; }
.acct-head { padding: 1rem; background: linear-gradient(to right, rgba(74, 222, 128, 0.05), transparent); display: flex; gap: 12px; align-items: center; border-bottom: 1px solid var(--border); }
.acct-id { background: var(--accent); color: #064e3b; font-weight: 900; padding: 2px 6px; border-radius: 4px; font-size: 0.75rem; }
.table-head, .entry-line { display: grid; grid-template-columns: 120px 1fr 140px; column-gap: 2.5rem; padding: 0.75rem 1.25rem; align-items: center; }
.table-head { font-size: 10px; color: var(--text-dim); text-transform: uppercase; background: rgba(0,0,0,0.2); }
.entry-line { border-bottom: 1px solid var(--border); font-size: 14px; }
.entry-date { font-family: 'JetBrains Mono', monospace; color: var(--text-dim); }
.entry-val { color: var(--accent); font-family: 'JetBrains Mono', monospace; font-weight: 700; }
.text-right { text-align: right; }
.sync-btn { background: none; border: none; color: var(--text-dim); cursor: pointer; transition: 0.2s; }
.sync-btn:hover { color: var(--text-main); }
.spinning { animation: spin 1s linear infinite; }
@keyframes spin { to { transform: rotate(360deg); } }
.empty-state { padding: 4rem; text-align: center; color: var(--text-dim); }
</style>
