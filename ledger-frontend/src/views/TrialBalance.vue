<script setup>
import { ref, computed, onMounted } from 'vue'

const loading = ref(false)
const error = ref(null)
const rows = ref([])

const fetchTrialBalance = async () => {
  loading.value = true
  error.value = null
  try {
    const res = await fetch(import.meta.env.VITE_GET_TRIAL_BALANCE_WEBHOOK)
    if (!res.ok) throw new Error(`HTTP ${res.status}`)
    const data = await res.json()
    rows.value = Array.isArray(data) ? data : []
  } catch (e) {
    error.value = 'Failed to load trial balance'
  } finally {
    loading.value = false
  }
}

const computedRows = computed(() =>
  rows.value.map(r => {
    const debit = Number(r.debit) || 0
    const credit = Number(r.credit) || 0
    return {
      ...r,
      dr_balance: debit > credit ? debit - credit : 0,
      cr_balance: credit > debit ? credit - debit : 0
    }

  })

)

const totalDebit = computed(() =>
  computedRows.value.reduce((s, r) => s + r.dr_balance, 0)
)

const totalCredit = computed(() =>
  computedRows.value.reduce((s, r) => s + r.cr_balance, 0)
)

const isBalanced = computed(() =>
  Math.abs(totalDebit.value - totalCredit.value) < 0.01 && computedRows.value.length > 0
)

const fmt = (val) => {
  return val > 0 ? "$" + val.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 }) : '—'
}

onMounted(fetchTrialBalance)
</script>

<template>
  <div class="ledger-container">
    <header class="view-header">
      <div class="title-meta">
        <h1>Trial Balance</h1>
        <div class="pill">
          <span class="pulse" :class="{ 'pulse-error': !isBalanced }"></span>
          {{ isBalanced ? 'System Balanced' : 'Out of Balance' }}
        </div>
      </div>

      <div class="header-actions">
        <button @click="fetchTrialBalance" class="sync-btn" :class="{ spinning: loading }">
          <svg viewBox="0 0 24 24" width="18" height="18" stroke="currentColor" stroke-width="2.5" fill="none"><path d="M23 4v6h-6M1 20v-6h6M3.51 9a9 9 0 0 1 14.85-3.36L23 10M1 14l4.64 4.36A9 9 0 0 0 20.49 15"></path></svg>
        </button>
      </div>
    </header>

    <div class="ledger-scroller">
      <div class="acct-card">
        <div class="acct-head">
          <span class="acct-id">TB</span>
          <span class="acct-label">Summary of Balances</span>
        </div>

        <div class="acct-entries">
          <div class="table-head">
            <div>Account</div>
            <div class="text-right">Debit Balance</div>
            <div class="text-right">Credit Balance</div>
          </div>

          <div v-if="loading" class="empty-state">Calculating Balances...</div>
          <div v-else-if="error" class="empty-state error">{{ error }}</div>
          
          <div
            v-for="row in computedRows"
            :key="row.account_id"
            class="entry-line"
          >
            <div class="col-main">
              <span class="acct-code">{{ row.code }}</span>
              <span class="acct-name">{{ row.name }}</span>
            </div>

            <div class="col-val dr text-right">
              {{ fmt(row.dr_balance) }}
            </div>

            <div class="col-val cr text-right">
              {{ fmt(row.cr_balance) }}
            </div>
          </div>
        </div>

        <div class="card-footer">
          <div class="footer-label">Verified Totals</div>
          <div class="running-totals">
            <div class="total-box dr">
              <label>Total Debit</label>
              <span>${{ totalDebit.toFixed(2) }}</span>
            </div>
            <div class="total-box cr">
              <label>Total Credit</label>
              <span>${{ totalCredit.toFixed(2) }}</span>
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
  font-family: 'Inter', sans-serif;
}

/* --- Shared Header --- */
.view-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1.25rem 1.5rem;
  border-bottom: 1px solid var(--border);
  background: rgba(9, 9, 11, 0.85);
  backdrop-filter: blur(12px);
  position: sticky;
  top: 0;
  z-index: 50;
}

.title-meta h1 { font-size: 1.25rem; font-weight: 800; letter-spacing: -0.02em; margin: 0; }
.pill { display: flex; align-items: center; gap: 6px; font-size: 11px; color: var(--text-dim); background: #27272a; padding: 4px 10px; border-radius: 99px; border: 1px solid var(--border); margin-top: 4px; width: fit-content; }
.pulse { width: 6px; height: 6px; background: var(--accent); border-radius: 50%; box-shadow: 0 0 8px var(--accent); }
.pulse-error { background: var(--cr); box-shadow: 0 0 8px var(--cr); }

.sync-btn { background: none; border: none; color: var(--text-dim); cursor: pointer; transition: 0.2s; display: flex; align-items: center; }
.sync-btn:hover { color: var(--text-main); }
.spinning { animation: spin 1s linear infinite; }
@keyframes spin { to { transform: rotate(360deg); } }

/* --- Table & Cards --- */
.ledger-scroller { padding: 1.5rem; width: 100%; box-sizing: border-box; }
.acct-card { background: var(--surface); border: 1px solid var(--border); border-radius: 12px; overflow: hidden; box-shadow: 0 10px 30px -10px rgba(0,0,0,0.5); }

.acct-head {
  padding: 1rem 1.5rem;
  background: linear-gradient(to right, rgba(34, 211, 238, 0.1), transparent);
  border-bottom: 1px solid var(--border);
  display: flex; align-items: center; gap: 12px;
}
.acct-id { background: var(--accent); color: #000; font-family: 'JetBrains Mono', monospace; font-weight: 900; padding: 2px 8px; border-radius: 4px; font-size: 0.8rem; }
.acct-label { font-weight: 700; text-transform: uppercase; font-size: 0.85rem; letter-spacing: 0.05em; }

/* --- Strict Grid Layout --- */
.table-head, .entry-line {
  display: grid;
  grid-template-columns: 1fr 180px 180px;
  padding: 0 1.5rem;
}

.table-head {
  height: 40px;
  align-items: center;
  background: rgba(0,0,0,0.2);
  font-size: 10px;
  font-weight: 800;
  color: var(--text-dim);
  text-transform: uppercase;
  border-bottom: 1px solid var(--border);
}

.entry-line {
  height: 48px;
  align-items: center;
  border-bottom: 1px solid var(--border);
  transition: background 0.2s;
}
.entry-line:hover { background: rgba(255,255,255,0.02); }

/* --- Account Styling --- */
.acct-code { font-family: 'JetBrains Mono', monospace; font-weight: 800; color: var(--accent); margin-right: 12px; font-size: 14px; }
.acct-name { font-weight: 500; font-size: 14px; color: var(--text-main); }

.col-val { font-family: 'JetBrains Mono', monospace; font-size: 14px; font-weight: 600; }
.dr { color: var(--dr); }
.cr { color: var(--cr); }
.text-right { text-align: right; }

/* --- Footer --- */
.card-footer {
  padding: 1.25rem 1.5rem;
  display: flex;
  justify-content: space-between;
  align-items: center;
  background: rgba(0,0,0,0.15);
  border-top: 1px solid var(--border);
}

.footer-label { font-size: 11px; font-weight: 900; text-transform: uppercase; color: var(--text-dim); letter-spacing: 0.1em; }
.running-totals { display: flex; gap: 3rem; }
.total-box { display: flex; flex-direction: column; align-items: flex-end; }
.total-box label { font-size: 9px; text-transform: uppercase; color: var(--text-dim); font-weight: 800; margin-bottom: 2px; }
.total-box span { font-family: 'JetBrains Mono', monospace; font-weight: 700; font-size: 18px; }
.total-box.dr span { color: var(--dr); }
.total-box.cr span { color: var(--cr); }

/* --- States --- */
.empty-state { padding: 4rem; text-align: center; color: var(--text-dim); font-size: 13px; text-transform: uppercase; letter-spacing: 0.1em; }
.error { color: var(--cr); }

/* --- Mobile --- */
@media (max-width: 800px) {
  .table-head { display: none; }
  .entry-line {
    grid-template-columns: 1fr 1fr;
    height: auto;
    padding: 1.25rem;
    gap: 12px;
  }
  .col-main { grid-column: span 2; padding-bottom: 8px; border-bottom: 1px solid var(--border); }
  .running-totals { gap: 1.5rem; }
}
</style>
