import { createRouter, createWebHistory } from 'vue-router'

import JournalEntries from './views/JournalEntries.vue'
import NewEntry from './views/NewEntry.vue'
import GeneralLedger from './views/GeneralLedger.vue'
import TrialBalance from './views/TrialBalance.vue'
import Reports from './views/Reports.vue'
import CreateAccount from './views/CreateAccount.vue'

export default createRouter({
  history: createWebHistory(),
  routes: [
    { path: '/accounting/', redirect: '/accounting/journal' },
    { path: '/accounting/journal', component: JournalEntries },
    { path: '/accounting/journal/new', component: NewEntry },
    { path: '/accounting/ledger', component: GeneralLedger },
    { path: '/accounting/trial-balance', component: TrialBalance },
    { path: '/accounting/reports', component: Reports },
    { path: '/accounting/create-account', component: CreateAccount }
  ]
})