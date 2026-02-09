<script setup>
import { ref, computed, onMounted } from 'vue'

const rawEntries = ref([])
const loading = ref(false)
const error = ref(null) // Added for better UI feedback

const EXPENSE_WEBHOOK = import.meta.env.VITE_GET_EXPENSE_WEBHOOK

const groupedExpenses = computed(() => {
  // Return empty object if no entries or only placeholder objects exist
  if (!rawEntries.value.length) return {}
  
  return rawEntries.value.reduce((acc, entry) => {
    // Maps to 'vendor' alias in your SQL (ac.label)
    const key = entry.vendor || 'Operational Costs'
    if (!acc[key]) acc[key] = []
    acc[key].push(entry)
    return acc
  }, {})
})

async function fetchExpenses() {
  loading.value = true
  error.value = null
  try {
    const res = await fetch(EXPENSE_WEBHOOK)
    if (!res.ok) throw new Error(`FETCH_ERROR: ${res.status}`)
    
    const data = await res.json()
    
    // Ensure we have a clean array without empty objects
    if (Array.isArray(data)) {
      rawEntries.value = data.filter(e => e && Object.keys(e).length > 0)
    } else {
      rawEntries.value = []
    }
  } catch (err) {
    console.error('Expense Fetch Failed:', err)
    error.value = err.message
    rawEntries.value = []
  } finally {
    loading.value = false
  }
}

onMounted(fetchExpenses)

const fmt = (val) => {
  const n = Number(val)
  // Standard financial formatting for costs
  return "$" + n.toLocaleString(undefined, { 
    minimumFractionDigits: 2, 
    maximumFractionDigits: 2 
  })
}

// Optional: Useful for a header summary
const totalExpenses = computed(() => {
  return rawEntries.value.reduce((sum, e) => sum + Number(e.amount || 0), 0)
})
</script>


<template>
  <div class="report-container expense-theme">
    <header class="view-header">
      <div class="title-meta">
        <h1>Expense Ledger</h1>
        <div class="pill">Outflow Analysis</div>
      </div>
      <button @click="fetchExpenses" class="sync-btn" :class="{ spinning: loading }">
        <svg viewBox="0 0 24 24" width="18" height="18" stroke="currentColor" stroke-width="2.5" fill="none"><path d="M23 4v6h-6M1 20v-6h6M3.51 9a9 9 0 0 1 14.85-3.36L23 10M1 14l4.64 4.36A9 9 0 0 0 20.49 15"></path></svg>
      </button>
    </header>

    <div v-if="loading" class="empty-state">Fetching Expenditures...</div>

    <div v-else class="ledger-scroller">
      <div v-for="(rows, vendor) in groupedExpenses" :key="vendor" class="acct-card">
        <div class="acct-head">
          <span class="acct-id">EXP</span>
          <span class="acct-label">{{ vendor }}</span>
        </div>

        <div class="acct-entries">
          <div class="table-head">
            <div>Ref Date</div>
            <div>Description</div>
            <div class="text-right">Cost</div>
          </div>

          <div v-for="(row, i) in rows" :key="i" class="entry-line">
            <div class="entry-date">{{ new Date(row.entry_date).toLocaleDateString('en-GB') }}</div>
            <div class="entry-desc">{{ row.description || "Fixed Cost" }}</div>
            <div class="entry-val text-right">({{ fmt(row.amount) }})</div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.expense-theme { --accent: #f87171; --bg: #09090b; --surface: #121214; --border: rgba(255,255,255,0.06); --text-main: #fafafa; --text-dim: #a1a1aa; }
.report-container { background: var(--bg); min-height: 100vh; color: var(--text-main); font-family: 'Inter', sans-serif; }
.view-header { display: flex; justify-content: space-between; padding: 1.5rem; border-bottom: 1px solid var(--border); background: rgba(9,9,11,0.8); backdrop-filter: blur(10px); }
.view-header h1 { font-size: 1.1rem; text-transform: uppercase; letter-spacing: 0.1em; }
.pill { font-size: 11px; background: rgba(248, 113, 113, 0.1); color: var(--accent); padding: 4px 12px; border-radius: 99px; border: 1px solid rgba(248, 113, 113, 0.2); margin-top: 5px; font-weight: 700; }
.acct-card { background: var(--surface); border: 1px solid var(--border); border-radius: 12px; margin: 1rem; overflow: hidden; border-left: 4px solid var(--accent); }
.acct-head { padding: 1rem; background: linear-gradient(to right, rgba(248, 113, 113, 0.05), transparent); display: flex; gap: 12px; align-items: center; }
.acct-id { background: var(--accent); color: #450a0a; font-weight: 900; padding: 2px 6px; border-radius: 4px; font-size: 0.75rem; }
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
