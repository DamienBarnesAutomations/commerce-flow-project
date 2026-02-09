<template>
  <div class="app-shell">
    <Transition name="fade">
      <div v-if="mobileOpen" class="backdrop" @click="mobileOpen = false" />
    </Transition>

    <aside :class="['sidebar', { collapsed, 'mobile-open': mobileOpen }]">
      <div class="sidebar-header">
        <span class="logo" v-if="!collapsed || mobileOpen">Ledger</span>
        <button class="icon-btn hide-mobile" @click="collapsed = !collapsed">☰</button>
        <button class="icon-btn hide-desktop" @click="mobileOpen = false">✕</button>
      </div>

      <nav @click="onNavClick">
        <RouterLink v-for="item in menu" :key="item.to" :to="item.to" class="nav-item">
          <span class="icon">{{ item.icon }}</span>
          <span class="label" v-if="!collapsed || mobileOpen">{{ item.label }}</span>
        </RouterLink>
      </nav>
    </aside>

    <section class="main">
      <header class="top-bar">
        <button class="icon-btn hide-desktop" @click="mobileOpen = true">☰</button>
        <h2 class="title">Accounting</h2>
      </header>
      <div class="content">
        <RouterView />
      </div>
    </section>
  </div>
</template>

<script setup>
import { ref } from 'vue'

const collapsed = ref(false)
const mobileOpen = ref(false)

const menu = [
  { to: '/accounting/journal', icon: '📒', label: 'Journal' },
  { to: '/accounting/journal/new', icon: '➕', label: 'New Entry' },
  { to: '/accounting/ledger', icon: '📊', label: 'Ledger' },
  { to: '/accounting/trial-balance', icon: '⚖️', label: 'Trial Balance' },
  { to: '/accounting/balance-sheet', icon: '🏛️', label: 'Balance Sheet' },
  { to: '/accounting/profit-loss', icon: '📈', label: 'Profit & Loss' },
  { to: '/accounting/income-report', icon: '💰', label: 'Income Report' },
  { to: '/accounting/expense-report', icon: '💸', label: 'Expense Report' },
  { to: '/accounting/create-account', icon: '🗂️', label: 'Create Account' }

]


const onNavClick = () => {
  if (window.innerWidth <= 640) {
    mobileOpen.value = false
  }
}
</script>

<style scoped>
.app-shell {
  display: grid;
  grid-template-columns: auto 1fr;
  height: 100vh;
  width: 100vw;
  background: var(--bg);
  color: var(--text);
  overflow: hidden;
}

.sidebar {
  width: 220px;
  background: var(--panel);
  border-right: 1px solid var(--border);
  display: flex;
  flex-direction: column;
  transition: width 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  z-index: 100;
}
.sidebar.collapsed { width: 64px; }

.sidebar-header {
  height: 60px;
  padding: 0 1.25rem;
  display: flex;
  align-items: center;
  justify-content: space-between;
  border-bottom: 1px solid var(--border);
}

.logo { font-weight: 800; font-size: 1.1rem; color: var(--accent); letter-spacing: -0.03em; }

.nav-item {
  display: flex;
  align-items: center;
  gap: 1rem;
  padding: 0.75rem 1.25rem;
  color: var(--muted);
  text-decoration: none;
  margin: 4px 8px;
  border-radius: 8px;
  transition: all 0.2s ease;
}
.nav-item:hover { background: rgba(255,255,255,0.03); color: var(--text); }
.router-link-active { color: var(--accent); background: rgba(16, 185, 129, 0.08); font-weight: 600; }

.main { display: flex; flex-direction: column; height: 100%; overflow: hidden; }

.top-bar { 
  height: 60px; 
  padding: 0 2rem; 
  display: flex; 
  align-items: center; 
  border-bottom: 1px solid var(--border);
  background: var(--bg);
}

.title { font-size: 1rem; font-weight: 700; color: var(--muted); text-transform: uppercase; letter-spacing: 0.05em; }

.content { 
  flex: 1; 
  overflow-y: auto; 
  padding: 2rem; /* Consistent desktop padding */
}

@media (max-width: 640px) {
  .app-shell { grid-template-columns: 1fr; }
  .sidebar { position: fixed; left: 0; top: 0; bottom: 0; width: 280px; transform: translateX(-100%); }
  .sidebar.mobile-open { transform: translateX(0); box-shadow: 20px 0 50px rgba(0,0,0,0.5); }
  .sidebar.collapsed { width: 280px; }
  .top-bar { padding: 0 1rem; }
  .content { padding: 1rem; } /* Mobile breathing room */
  .hide-mobile { display: none; }
  .hide-desktop { display: block; }
}

.backdrop { position: fixed; inset: 0; background: rgba(0, 0, 0, 0.7); backdrop-filter: blur(4px); z-index: 90; }
.icon-btn { background: none; border: none; color: var(--text); font-size: 1.2rem; cursor: pointer; padding: 8px; display: flex; align-items: center; }
</style>
