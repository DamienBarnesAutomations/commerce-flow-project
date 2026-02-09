<template>
  <div class="ledger-container">
    <header class="view-header">
      <div class="title-meta">
        <h1>Balance Sheet</h1>
        <div class="pill">
          <span class="pulse"></span>
          As of {{ new Date().toLocaleDateString() }}
        </div>
      </div>
      <button @click="fetchData" class="sync-btn" :class="{ spinning: loading }">
        <svg viewBox="0 0 24 24" width="18" height="18" stroke="currentColor" stroke-width="2.5" fill="none"><path d="M23 4v6h-6M1 20v-6h6M3.51 9a9 9 0 0 1 14.85-3.36L23 10M1 14l4.64 4.36A9 9 0 0 0 20.49 15"></path></svg>
      </button>
    </header>

    <div class="ledger-scroller" v-if="!loading">
      <section class="report-section">
        <h2 class="section-title">Assets</h2>
        <div v-for="(accounts, category) in groupedData.asset" :key="category" class="category-block">
          <h3 class="category-name">{{ category }}</h3>
          <div v-for="acc in accounts" :key="acc.code" class="report-row">
            <span>{{ acc.code }} - {{ acc.name }}</span>
            <span class="amount">{{ formatCurrency(acc.balance) }}</span>
          </div>
          <div class="category-total">
            <span>Total {{ category }}</span>
            <span>{{ formatCurrency(sumCategory(accounts)) }}</span>
          </div>
        </div>
        <div class="grand-total asset-bg">
          <span>Total Assets</span>
          <span>{{ formatCurrency(totalAssets) }}</span>
        </div>
      </section>

      <section class="report-section">
        <h2 class="section-title">Liabilities</h2>
        <div v-for="(accounts, category) in groupedData.liability" :key="category" class="category-block">
          <h3 class="category-name">{{ category }}</h3>
          <div v-for="acc in accounts" :key="acc.code" class="report-row">
            <span>{{ acc.code }} - {{ acc.name }}</span>
            <span class="amount">{{ formatCurrency(acc.balance) }}</span>
          </div>
          <div class="category-total">
            <span>Total {{ category }}</span>
            <span>{{ formatCurrency(sumCategory(accounts)) }}</span>
          </div>
        </div>
        <div class="grand-total liability-bg">
          <span>Total Liabilities</span>
          <span>{{ formatCurrency(totalLiabilities) }}</span>
        </div>
      </section>

      <section class="report-section">
        <h2 class="section-title">Equity</h2>
        <div v-for="(accounts, category) in groupedData.equity" :key="category" class="category-block">
          <h3 class="category-name">{{ category }}</h3>
          <div v-for="acc in accounts" :key="acc.code" class="report-row">
            <span>{{ acc.code }} - {{ acc.name }}</span>
            <span class="amount">{{ formatCurrency(acc.balance) }}</span>
          </div>
        </div>
        <div class="grand-total equity-bg">
          <span>Total Equity</span>
          <span>{{ formatCurrency(totalEquity) }}</span>
        </div>
      </section>

      <footer class="equation-footer" :class="{ 'error-border': !isBalanced }">
        <div class="check-item">
          <label>Total Assets</label>
          <div class="val">{{ formatCurrency(totalAssets) }}</div>
        </div>
        <div class="operator">=</div>
        <div class="check-item">
          <label>Liabilities + Equity</label>
          <div class="val">{{ formatCurrency(totalLiabilities + totalEquity) }}</div>
        </div>
        <div class="status-icon" :title="isBalanced ? 'Balanced' : 'Out of Balance'">
          {{ isBalanced ? '✅' : '❌' }}
        </div>
      </footer>
    </div>

    <div v-else class="loading-state">Calculating ledger balances...</div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue';

const rawData = ref([]);
const loading = ref(true);

const fetchData = async () => {
  loading.value = true;
  try {
    const res = await fetch(import.meta.env.VITE_GET_BALANCE_SHEET_WEBHOOK);
    const data = await res.json();
    rawData.value = data;
  } catch (e) {
    console.error("Failed to fetch balance sheet", e);
  } finally {
    loading.value = false;
  }
};

const groupedData = computed(() => {
  const groups = { asset: {}, liability: {}, equity: {} };
  rawData.value.forEach(item => {
    if (!groups[item.type]) return;
    if (!groups[item.type][item.category_label]) {
      groups[item.type][item.category_label] = [];
    }
    groups[item.type][item.category_label].push(item);
  });
  return groups;
});

const sumCategory = (accounts) => accounts.reduce((s, a) => s + Number(a.balance), 0);

const totalAssets = computed(() => 
  Object.values(groupedData.value.asset).flat().reduce((s, a) => s + Number(a.balance), 0)
);

const totalLiabilities = computed(() => 
  Object.values(groupedData.value.liability).flat().reduce((s, a) => s + Number(a.balance), 0)
);

const totalEquity = computed(() => 
  Object.values(groupedData.value.equity).flat().reduce((s, a) => s + Number(a.balance), 0)
);

const isBalanced = computed(() => Math.abs(totalAssets.value - (totalLiabilities.value + totalEquity.value)) < 0.01);

const formatCurrency = (val) => new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(val);

onMounted(fetchData);
</script>

<style scoped>
.report-section { margin-bottom: 2rem; background: var(--bg-card); padding: 1.5rem; border-radius: 8px; }
.section-title { font-size: 1.2rem; border-bottom: 2px solid var(--accent); padding-bottom: 0.5rem; margin-bottom: 1rem; }
.category-block { margin-bottom: 1.5rem; }
.category-name { font-size: 0.9rem; color: var(--text-muted); text-transform: uppercase; letter-spacing: 0.05em; margin-bottom: 0.5rem; }
.report-row { display: flex; justify-content: space-between; padding: 0.4rem 0; border-bottom: 1px dotted var(--border); font-size: 0.95rem; }
.category-total { display: flex; justify-content: space-between; font-weight: bold; padding-top: 0.5rem; border-top: 1px solid var(--text-muted); margin-top: 0.5rem; }
.grand-total { display: flex; justify-content: space-between; font-size: 1.1rem; font-weight: 800; padding: 1rem; border-radius: 4px; margin-top: 1rem; }
.asset-bg { background: rgba(16, 185, 129, 0.1); color: #10b981; }
.liability-bg { background: rgba(239, 68, 68, 0.1); color: #ef4444; }
.equity-bg { background: rgba(59, 130, 246, 0.1); color: #3b82f6; }
.equation-footer { display: flex; align-items: center; justify-content: center; gap: 2rem; background: var(--bg-card); padding: 1.5rem; border-radius: 8px; border: 2px solid #10b981; margin-top: 2rem; }
.error-border { border-color: #ef4444; }
.operator { font-size: 2rem; font-weight: 300; }
.check-item label { display: block; font-size: 0.75rem; text-transform: uppercase; color: var(--text-muted); }
.check-item .val { font-size: 1.5rem; font-weight: bold; }
.sync-btn { background: none; border: none; color: var(--text-dim); cursor: pointer; transition: 0.2s; }
.sync-btn:hover { color: var(--text-main); }
.spinning { animation: spin 1s linear infinite; }
@keyframes spin { to { transform: rotate(360deg); } }
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
</style>
