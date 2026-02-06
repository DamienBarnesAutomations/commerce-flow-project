<template>
  <div class="ledger-container">
    <header class="view-header">
      <div class="title-meta">
        <h1>Profit & Loss</h1>
        <div class="pill">Current Fiscal Year</div>
      </div>
      <div class="header-actions">
        <button class="post-btn" @click="fetchData">Refresh</button>
      </div>
    </header>
    
    <div class="ledger-scroller" v-if="!loading">
      <section class="report-section">
        <h2 class="section-title">Revenue</h2>
        <div v-for="(accounts, label) in groupedData.income" :key="label" class="category-block">
          <div v-for="acc in accounts" :key="acc.code" class="report-row">
            <span>{{ acc.name }}</span>
            <span class="amount">{{ formatCurrency(acc.balance) }}</span>
          </div>
        </div>
        <div class="category-total">
          <span>Total Revenue</span>
          <span>{{ formatCurrency(totalIncome) }}</span>
        </div>
      </section>

      <section class="report-section highlight-box">
        <div class="report-row">
          <span>Cost of Goods Sold (COGS)</span>
          <span class="amount">({{ formatCurrency(totalCOGS) }})</span>
        </div>
        <div class="grand-total gross-margin">
          <span>Gross Profit</span>
          <span>{{ formatCurrency(totalIncome - totalCOGS) }}</span>
        </div>
      </section>

      <section class="report-section">
        <h2 class="section-title">Operating Expenses</h2>
        <div v-for="(accounts, label) in groupedData.expense" :key="label" class="category-block">
          <template v-if="accounts[0].category_name !== 'cogs'">
            <h3 class="category-name">{{ label }}</h3>
            <div v-for="acc in accounts" :key="acc.code" class="report-row">
              <span>{{ acc.name }}</span>
              <span class="amount">{{ formatCurrency(acc.balance) }}</span>
            </div>
          </template>
        </div>
        <div class="category-total">
          <span>Total Operating Expenses</span>
          <span>{{ formatCurrency(totalOpEx) }}</span>
        </div>
      </section>

      <footer class="net-income-footer" :class="netIncome >= 0 ? 'profit' : 'loss'">
        <div class="check-item">
          <label>Net Income / (Loss)</label>
          <div class="val">{{ formatCurrency(netIncome) }}</div>
        </div>
      </footer>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue';

const rawData = ref([]);
const loading = ref(true);

const fetchData = async () => {
  loading.value = true;
  try {
    const res = await fetch(import.meta.env.VITE_PROFIT_LOSS_WEBHOOK);
    rawData.value = await res.json();
  } catch (e) {
    console.error("P&L Fetch Error", e);
  } finally {
    loading.value = false;
  }
};

const groupedData = computed(() => {
  const groups = { income: {}, expense: {} };
  rawData.value.forEach(item => {
    if (!groups[item.type][item.category_label]) {
      groups[item.type][item.category_label] = [];
    }
    groups[item.type][item.category_label].push(item);
  });
  return groups;
});

const totalIncome = computed(() => 
  rawData.value.filter(i => i.type === 'income').reduce((s, a) => s + Number(a.balance), 0)
);

const totalCOGS = computed(() => 
  rawData.value.filter(i => i.category_name === 'cogs').reduce((s, a) => s + Number(a.balance), 0)
);

const totalOpEx = computed(() => 
  rawData.value.filter(i => i.type === 'expense' && i.category_name !== 'cogs')
               .reduce((s, a) => s + Number(a.balance), 0)
);

const netIncome = computed(() => totalIncome.value - totalCOGS.value - totalOpEx.value);

const formatCurrency = (val) => new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(val);

onMounted(fetchData);
</script>

<style scoped>
.report-section { margin-bottom: 1.5rem; background: var(--bg-card); padding: 1.5rem; border-radius: 8px; }
.highlight-box { background: rgba(255, 255, 255, 0.03); border-left: 4px solid var(--accent); }
.section-title { font-size: 1rem; color: var(--accent); text-transform: uppercase; margin-bottom: 1rem; }
.report-row { display: flex; justify-content: space-between; padding: 0.5rem 0; border-bottom: 1px solid rgba(255,255,255,0.05); }
.category-total { display: flex; justify-content: space-between; font-weight: 700; margin-top: 1rem; font-size: 1.1rem; }
.gross-margin { color: var(--accent); border-top: 1px solid var(--accent); padding-top: 1rem; }
.net-income-footer { margin-top: 2rem; padding: 2rem; border-radius: 8px; text-align: center; }
.profit { background: #10b981; color: white; }
.loss { background: #ef4444; color: white; }
.val { font-size: 2.5rem; font-weight: 900; }
</style>
