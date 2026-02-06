<script setup>
import { ref, computed, onMounted } from 'vue'

const entryDate = ref(new Date().toISOString().slice(0, 10))
const reference = ref('')
const description = ref('')
const accounts = ref([])
const loadingAccounts = ref(false)

const rows = ref([
  { account_id: '', debit: null, credit: null },
  { account_id: '', debit: null, credit: null }
])

const addRow = () => rows.value.push({ account_id: '', debit: null, credit: null })
const removeRow = (i) => rows.value.length > 2 && rows.value.splice(i, 1)

const onDebitInput = (r) => { if (r.debit > 0) r.credit = null }
const onCreditInput = (r) => { if (r.credit > 0) r.debit = null }

const totalDebit = computed(() => {
  const sum = rows.value.reduce((s, r) => s + (Number(r.debit) || 0), 0);
  return Math.round((sum + Number.EPSILON) * 100) / 100;
});

const totalCredit = computed(() => {
  const sum = rows.value.reduce((s, r) => s + (Number(r.credit) || 0), 0);
  return Math.round((sum + Number.EPSILON) * 100) / 100;
});

const balance = computed(() => {
  // Subtracting two rounded numbers is safe
  return Math.round((totalDebit.value - totalCredit.value + Number.EPSILON) * 100) / 100;
});

const isBalanced = computed(() => {
  // Check if exactly zero and that there is actually a transaction
  return Math.abs(balance.value) === 0 && totalDebit.value > 0;
});


const submitEntry = async () => {
  if (!isBalanced.value) return
  const cleanedLines = rows.value
    .filter(r => r.account_id && (Number(r.debit) || Number(r.credit)))
    .map(r => ({
      account_id: r.account_id,
      debit: Number(r.debit) || 0,
      credit: Number(r.credit) || 0
    }))

  if (cleanedLines.length < 2) {
    alert('Journal entry must have at least two lines')
    return
  }

  const payload = {
    date: entryDate.value,
    reference: reference.value,
    description: description.value?.trim() || null,
    lines: cleanedLines
  }

  try {
    const res = await fetch(import.meta.env.VITE_POST_JOURNAL_ENTRIES_WEBHOOK, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload)
    })
    if (!res.ok) throw new Error(`HTTP ${res.status}`)

    description.value = ''
    reference.value = ''
    rows.value = [
      { account_id: '', debit: null, credit: null },
      { account_id: '', debit: null, credit: null }
    ]
    entryDate.value = new Date().toISOString().slice(0, 10)
    alert('Entry posted successfully!')
  } catch (err) {
    alert('Failed to save journal entry')
  }
}

onMounted(async () => {
  loadingAccounts.value = true
  try {
    const res = await fetch(import.meta.env.VITE_GET_ACCOUNTS_WEBHOOK)
    const data = await res.json()
    accounts.value = Array.isArray(data) ? data : []
  } catch (e) { console.error(e) }
  finally { loadingAccounts.value = false }
})
</script>

<template>
  <div class="ledger-container">
    <header class="view-header">
      <div class="title-meta">
        <h1>New Journal Entry</h1>
        <div class="pill">
          <span class="pulse" :class="{ 'pulse-error': !isBalanced }"></span>
          {{ isBalanced ? 'Ready to Post' : 'Out of Balance' }}
        </div>
      </div>
      <div class="header-actions">
        <button class="post-btn" :disabled="!isBalanced" @click="submitEntry">
          Post Transaction
        </button>
      </div>
    </header>

    <div class="ledger-scroller">
      <div class="acct-card meta-section compact-bar">
        <div class="meta-grid">
          <div class="input-group">
            <label>Date</label>
            <input type="date" v-model="entryDate" class="min-input" />
          </div>
          <div class="input-group ref-width">
            <label>Ref</label>
            <input type="text" v-model="reference" placeholder="Ref #" class="min-input" />
          </div>
          <div class="input-group grow">
            <label>Memo</label>
            <input type="text" v-model="description" placeholder="Entry description..." class="min-input" />
          </div>
        </div>
      </div>

      <div class="acct-card">
        <div class="acct-head">
          <span class="acct-id">LINES</span>
          <span class="acct-label">Account Distributions</span>
        </div>

        <div class="acct-entries">
          <div class="table-head">
            <div class="col-main">Account Selection</div>
            <div class="text-right">Debit</div>
            <div class="text-right">Credit</div>
            <div class="col-action"></div>
          </div>

          <div v-for="(row, i) in rows" :key="i" class="entry-line">
            <div class="col-main">
              <select v-model="row.account_id" class="ledger-select">
                <option disabled value="">Select Account...</option>
                <option v-for="a in accounts" :key="a.id" :value="a.id">{{ a.code }} - {{ a.name }}</option>
              </select>
            </div>
            
            <div class="col-val">
              <input type="number" v-model.number="row.debit" @input="onDebitInput(row)" placeholder="0.00" class="amt-input dr-field" />
            </div>

            <div class="col-val">
              <input type="number" v-model.number="row.credit" @input="onCreditInput(row)" placeholder="0.00" class="amt-input cr-field" />
            </div>

            <div class="col-action">
              <button @click="removeRow(i)" class="remove-btn" :disabled="rows.length <= 2">✕</button>
            </div>
          </div>
        </div>

        <div class="card-footer">
          <button @click="addRow" class="add-line-btn">
            <svg viewBox="0 0 24 24" width="14" height="14" stroke="currentColor" stroke-width="3" fill="none"><line x1="12" y1="5" x2="12" y2="19"></line><line x1="5" y1="12" x2="19" y2="12"></line></svg>
            Add Line
          </button>
          
          <div class="running-totals">
            <div class="total-box dr">
              <label>Total Debit</label>
              <span>{{ totalDebit.toFixed(2) }}</span>
            </div>
            <div class="total-box cr">
              <label>Total Credit</label>
              <span>{{ totalCredit.toFixed(2) }}</span>
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
  font-family: 'Inter', sans-serif;
}

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

.title-meta h1 { font-size: 1.1rem; font-weight: 800; letter-spacing: -0.02em; margin: 0; }
.pill { display: flex; align-items: center; gap: 6px; font-size: 10px; color: var(--text-dim); background: #27272a; padding: 2px 8px; border-radius: 99px; border: 1px solid var(--border); margin-top: 4px; width: fit-content; }
.pulse { width: 6px; height: 6px; background: var(--accent); border-radius: 50%; box-shadow: 0 0 8px var(--accent); }
.pulse-error { background: var(--cr); box-shadow: 0 0 8px var(--cr); }

.post-btn {
  background: var(--accent);
  color: #022c22;
  border: none;
  padding: 8px 18px;
  border-radius: 6px;
  font-size: 12px;
  font-weight: 800;
  cursor: pointer;
}
.post-btn:disabled { opacity: 0.15; cursor: not-allowed; filter: grayscale(1); }

.ledger-scroller { padding: 1rem 1.5rem; width: 100%; box-sizing: border-box; }

/* --- Compact Meta Bar --- */
.meta-section.compact-bar { 
  padding: 0.75rem 1.25rem; 
  margin-bottom: 1rem;
  background: rgba(24, 24, 27, 0.5);
}

.meta-grid { display: flex; gap: 1.5rem; align-items: center; }
.input-group { display: flex; align-items: center; gap: 10px; }
.ref-width { width: 180px; }
.input-group.grow { flex: 1; }
.input-group label { font-size: 9px; font-weight: 800; text-transform: uppercase; color: var(--text-dim); white-space: nowrap; }

.min-input {
  background: #09090b !important;
  border: 1px solid var(--border) !important;
  border-radius: 4px !important;
  height: 32px !important;
  padding: 0 10px !important;
  font-size: 13px !important;
  color: white;
  width: 100%;
}

/* --- Entry Table --- */
.acct-card { background: var(--surface); border: 1px solid var(--border); border-radius: 12px; margin-bottom: 1.5rem; overflow: hidden; }
.acct-head { padding: 0.75rem 1.25rem; background: linear-gradient(to right, rgba(16, 185, 129, 0.1), transparent); border-bottom: 1px solid var(--border); display: flex; align-items: center; gap: 12px; }
.acct-id { background: var(--accent); color: #000; font-family: 'JetBrains Mono', monospace; font-weight: 900; padding: 1px 6px; border-radius: 3px; font-size: 0.7rem; }
.acct-label { font-weight: 700; text-transform: uppercase; font-size: 0.75rem; color: var(--text-dim); }

.table-head, .entry-line { display: grid; grid-template-columns: 1fr 160px 160px 50px; padding: 0 1.25rem; }
.table-head { height: 36px; align-items: center; background: rgba(0,0,0,0.2); font-size: 9px; font-weight: 800; color: var(--text-dim); text-transform: uppercase; border-bottom: 1px solid var(--border); }
.entry-line { height: 50px; align-items: center; border-bottom: 1px solid var(--border); }

.ledger-select, .amt-input { width: 100%; background: transparent; border: 1px solid transparent; color: white; height: 36px; font-size: 14px; border-radius: 4px; padding: 0 8px; }
.ledger-select:focus, .amt-input:focus { border-color: var(--accent); background: rgba(16, 185, 129, 0.05); outline: none; }
.amt-input { text-align: right; font-family: 'JetBrains Mono', monospace; }
.dr-field { color: var(--dr); }
.cr-field { color: var(--cr); }

.remove-btn { background: none; border: none; color: var(--text-dim); cursor: pointer; width: 30px; height: 30px; border-radius: 50%; transition: 0.2s; }
.remove-btn:hover:not(:disabled) { background: rgba(248, 113, 113, 0.1); color: var(--cr); }
.remove-btn:disabled { opacity: 0; }

.card-footer { padding: 1rem 1.25rem; display: flex; justify-content: space-between; align-items: center; background: rgba(0,0,0,0.15); }
.add-line-btn { background: rgba(255,255,255,0.05); border: 1px solid var(--border); color: white; padding: 6px 14px; border-radius: 6px; font-size: 11px; font-weight: 700; cursor: pointer; display: flex; align-items: center; gap: 6px; }
.add-line-btn:hover { background: var(--accent); color: #000; }

.running-totals { display: flex; gap: 2rem; }
.total-box { display: flex; flex-direction: column; align-items: flex-end; }
.total-box label { font-size: 8px; text-transform: uppercase; color: var(--text-dim); font-weight: 800; }
.total-box span { font-family: 'JetBrains Mono', monospace; font-weight: 700; font-size: 16px; }
.total-box.dr span { color: var(--dr); }
.total-box.cr span { color: var(--cr); }

.text-right { text-align: right; }

@media (max-width: 900px) {
  .meta-grid { flex-direction: column; align-items: stretch; gap: 0.75rem; }
  .table-head { display: none; }
  .entry-line { grid-template-columns: 1fr 1fr 40px; height: auto; padding: 1rem; gap: 8px; }
  .col-main { grid-column: span 3; }
}
</style>
