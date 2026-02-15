<template>
  <div class="view-container">
    <div class="header-actions">
      <input v-model="search" placeholder="Search order history..." class="search-input" />
    </div>

    <div v-if="loading" class="status-message">Loading archives...</div>

    <div v-else class="order-grid grayscale-cards">
      <OrderCard 
        v-for="order in filteredOrders" 
        :key="order.order_id" 
        :order="order" 
      />
    </div>

    <div v-if="!loading && filteredOrders.length === 0" class="empty-state">
      <p>No historic orders found.</p>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import api from '../services/api';
import OrderCard from '../components/OrderCard.vue';

const orders = ref([]);
const loading = ref(true);
const search = ref('');

const fetchOrders = async () => {
  loading.value = true;
  try {
    const response = await api.get('/historic');
    
    // 1. Ensure we have an array
    const rawData = Array.isArray(response.data) ? response.data : [];

    // 2. Filter out empty objects [ {} ] and ensure it's a valid order
    // 3. Sort by date (descending: newest first)
    orders.value = rawData
      .filter(order => order && order.order_id)
      .sort((a, b) => {
        const dateA = new Date(a.selections?.event_date || 0).getTime();
        const dateB = new Date(b.selections?.event_date || 0).getTime();
        return dateB - dateA; 
      });
      
  } catch (err) {
    console.error("Historic API Error:", err);
    orders.value = [];
  } finally {
    loading.value = false;
  }
};

const filteredOrders = computed(() => {
  return orders.value.filter(o => 
    o.client_name.toLowerCase().includes(search.value.toLowerCase()) ||
    o.order_id.toString().includes(search.value)
  );
});

onMounted(fetchOrders);
</script>

<style scoped>
/* Optional: Make history cards look slightly "archived" */
.grayscale-cards :deep(.order-card) {
  border-left: 4px solid #999;
  opacity: 0.85;
}

.view-container {
  padding: 2rem;
  max-width: 1400px; /* Limits the stretch on ultra-wide monitors */
  margin: 0 auto;
}

.order-grid {
  display: grid;
  /* This tells the grid: 
     1. Try to fit as many columns as possible.
     2. Each column must be at least 280px.
     3. If there is extra space, share it equally (1fr).
  */
  grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
  gap: 1.5rem; /* Space between cards */
  align-items: start;
}

/* Responsive adjustment: 
   If you specifically want 4 columns on large screens regardless of width */
@media (min-width: 1200px) {
  .order-grid {
    grid-template-columns: repeat(4, 1fr);
  }
}

/* Header & Search Styles */
.header-actions {
  display: flex;
  align-items: center;
  gap: 1rem;
  margin-bottom: 2rem;
}

.search-input {
  flex: 1;
  padding: 0.8rem 1rem;
  border: 1px solid #ddd;
  border-radius: 8px;
  font-size: 1rem;
}

.count-badge {
  background: #eee;
  padding: 0.5rem 1rem;
  border-radius: 20px;
  font-weight: bold;
  color: #666;
  white-space: nowrap;
}
</style>