import { createRouter, createWebHistory } from 'vue-router'

import JournalEntries from './views/JournalEntries.vue'
import NewEntry from './views/NewEntry.vue'
import GeneralLedger from './views/GeneralLedger.vue'
import TrialBalance from './views/TrialBalance.vue'
import Reports from './views/Reports.vue'
import CreateAccount from './views/CreateAccount.vue'
import BalanceSheet from './views/BalanceSheet.vue'
import ProfitAndLoss from './views/ProfitAndLoss.vue'
import IncomeReport from './views/IncomeReport.vue'
import ExpenseReport from './views/ExpenseReport.vue'

export default createRouter({
  history: createWebHistory(),
  routes: [
    { path: '/accounting/', redirect: '/accounting/journal' },
    { path: '/accounting/journal', component: JournalEntries },
    { path: '/accounting/journal/new', component: NewEntry },
    { path: '/accounting/ledger', component: GeneralLedger },
    { path: '/accounting/trial-balance', component: TrialBalance },
    { path: '/accounting/reports', component: Reports },
    { path: '/accounting/balance-sheet', component: BalanceSheet },
    { path: '/accounting/profit-loss', component: ProfitAndLoss },
    { path: '/accounting/income-report', component: IncomeReport },
    { path: '/accounting/expense-report', component: ExpenseReport },
    { path: '/accounting/create-account', component: CreateAccount }
  ]
})