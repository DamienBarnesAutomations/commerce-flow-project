<script setup>
import { ref } from 'vue'

const reports = ref([
  { id: 'pl', name: 'Profit & Loss' },
  { id: 'bs', name: 'Balance Sheet' }
])

function runReport(reportId) {
  alert(`Run report: ${reportId}`)
}
</script>

<template>
  <section>
    <h2>Reports</h2>

    <div class="panel">
      <button
        v-for="r in reports"
        :key="r.id"
        class="btn-secondary"
        @click="runReport(r.id)"
      >
        {{ r.name }}
      </button>
    </div>

    <p class="muted">
      Reports are derived from journal entries. No shortcuts.
    </p>
  </section>
</template>