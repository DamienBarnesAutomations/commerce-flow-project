<script setup>
import { ref, watch } from 'vue'

const loading = ref(false)
const code = ref('')
const name = ref('')
const type = ref('asset')
const normalBalance = ref('debit')

// Logic helper: Auto-assign normal balance based on account type
watch(type, (newType) => {
  if (['asset', 'expense'].includes(newType)) {
    normalBalance.value = 'debit'
  } else {
    normalBalance.value = 'credit'
  }
})

const submitAccount = async () => {
  if (!code.value || !name.value) return
  
  loading.value = true
  const payload = {
    code: code.value.trim(),
    name: name.value.trim(),
    type: type.value,
    normal_balance: normalBalance.value
  }

  try {
    const res = await fetch(import.meta.env.VITE_CREATE_ACCOUNT_WEBHOOK, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload)
    })

    if (!res.ok) throw new Error('Failed to create account')

    // Reset Form
    code.value = ''
    name.value = ''
    alert('Account created successfully')
  } catch (err) {
    alert(err.message)
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <div class="ledger-container">
    <header class="view-header">
      <div class="title-meta">
        <h1>Chart of Accounts</h1>
        <div class="pill">
          <span class="pulse"></span>
          New Account Setup
        </div>
      </div>
      <div class="header-actions">
        <button class="post-btn" :disabled="loading || !code || !name" @click="submitAccount">
          {{ loading ? 'Saving...' : 'Create Account' }}
        </button>
      </div>
    </header>

    <div class="ledger-scroller">
      <div class="acct-card form-card">
        <div class="acct-head">
          <span class="acct-id">NEW</span>
          <span class="acct-label">Account Configuration</span>
        </div>

        <div class="form-body">
          <div class="form-grid">
            <div class="input-group">
              <label>Account Code</label>
              <input 
                v-model="code" 
                type="text" 
                placeholder="e.g. 1001" 
                class="min-input"
              />
            </div>

            <div class="input-group grow">
              <label>Account Name</label>
              <input 
                v-model="name" 
                type="text" 
                placeholder="e.g. Petty Cash" 
                class="min-input"
              />
            </div>
          </div>

          <div class="form-grid secondary">
            <div class="input-group">
              <label>Account Type</label>
              <select v-model="type" class="min-input">
                <option value="asset">Asset</option>
                <option value="liability">Liability</option>
                <option value="equity">Equity</option>
                <option value="income">Income</option>
                <option value="expense">Expense</option>
              </select>
            </div>

            <div class="input-group">
              <label>Normal Balance</label>
              <div class="toggle-group">
                <button 
                  :class="{ active: normalBalance === 'debit', dr: true }" 
                  @click="normalBalance = 'debit'"
                >Debit</button>
                <button 
                  :class="{ active: normalBalance === 'credit', cr: true }" 
                  @click="normalBalance = 'credit'"
                >Credit</button>
              </div>
            </div>
          </div>
        </div>

        <div class="card-footer hint">
          <svg viewBox="0 0 24 24" width="14" height="14" stroke="currentColor" stroke-width="2" fill="none"><circle cx="12" cy="12" r="10"></circle><line x1="12" y1="16" x2="12" y2="12"></line><line x1="12" y1="8" x2="12.01" y2="8"></line></svg>
          Ensure account codes follow your firm's naming convention (e.g. 1000s for Assets).
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
  position: sticky; top: 0; z-index: 50;
}

.title-meta h1 { font-size: 1.25rem; font-weight: 800; letter-spacing: -0.02em; margin: 0; }
.pill { display: flex; align-items: center; gap: 6px; font-size: 11px; color: var(--text-dim); background: #27272a; padding: 4px 10px; border-radius: 99px; border: 1px solid var(--border); margin-top: 4px; }
.pulse { width: 6px; height: 6px; background: var(--accent); border-radius: 50%; box-shadow: 0 0 8px var(--accent); }

.post-btn {
  background: var(--accent);
  color: #022c22;
  border: none;
  padding: 10px 24px;
  border-radius: 8px;
  font-size: 13px;
  font-weight: 800;
  cursor: pointer;
  transition: opacity 0.2s;
}
.post-btn:disabled { opacity: 0.15; cursor: not-allowed; }

.ledger-scroller { padding: 2rem; max-width: 800px; margin: 0 auto; }

.acct-card { background: var(--surface); border: 1px solid var(--border); border-radius: 12px; overflow: hidden; box-shadow: 0 10px 30px -10px rgba(0,0,0,0.5); }
.acct-head { padding: 1rem 1.5rem; background: linear-gradient(to right, rgba(16, 185, 129, 0.1), transparent); border-bottom: 1px solid var(--border); display: flex; align-items: center; gap: 12px; }
.acct-id { background: var(--accent); color: #000; font-family: 'JetBrains Mono', monospace; font-weight: 900; padding: 2px 8px; border-radius: 4px; font-size: 0.8rem; }
.acct-label { font-weight: 700; text-transform: uppercase; font-size: 0.85rem; }

.form-body { padding: 1.5rem; display: flex; flex-direction: column; gap: 2rem; }
.form-grid { display: flex; gap: 1.5rem; }
.form-grid.secondary { align-items: flex-end; }
.grow { flex: 1; }

.input-group { display: flex; flex-direction: column; gap: 8px; }
.input-group label { font-size: 10px; font-weight: 800; text-transform: uppercase; color: var(--text-dim); letter-spacing: 0.05em; }

.min-input {
  background: #09090b;
  border: 1px solid var(--border);
  border-radius: 6px;
  height: 42px;
  padding: 0 14px;
  color: white;
  font-size: 14px;
  transition: border-color 0.2s;
}
.min-input:focus { border-color: var(--accent); outline: none; }

/* Toggle Switch Styling */
.toggle-group { display: flex; background: #09090b; padding: 4px; border-radius: 8px; border: 1px solid var(--border); }
.toggle-group button {
  flex: 1;
  border: none;
  background: none;
  color: var(--text-dim);
  padding: 6px 20px;
  font-size: 12px;
  font-weight: 700;
  border-radius: 5px;
  cursor: pointer;
  transition: all 0.2s;
}
.toggle-group button.active.dr { background: var(--dr); color: #064e3b; }
.toggle-group button.active.cr { background: var(--cr); color: #450a0a; }

.card-footer.hint {
  background: rgba(0,0,0,0.2);
  padding: 1rem 1.5rem;
  font-size: 12px;
  color: var(--text-dim);
  display: flex;
  align-items: center;
  gap: 10px;
  border-top: 1px solid var(--border);
}

@media (max-width: 600px) {
  .form-grid { flex-direction: column; }
  .ledger-scroller { padding: 1rem; }
}
</style>
