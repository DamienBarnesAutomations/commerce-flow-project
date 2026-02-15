<template>
  <div class="view-container">
    <div class="header-actions">
      <input v-model="search" placeholder="Search pending reviews..." class="search-input" />
      <span class="count-badge">{{ filteredOrders.length }} Pending</span>
    </div>

    <div v-if="loading" class="status-message">
      <div class="spinner"></div> Loading reviews...
    </div>

    <div v-else class="order-grid">
      <OrderCard 
        v-for="order in filteredOrders" 
        :key="order.order_id" 
        :order="order" 
      />
    </div>

    <div v-if="!loading && filteredOrders.length === 0" class="empty-state">
      <p>All caught up! No orders currently need review. 🍰</p>
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
  loading.value = true; // Ensure loading starts
  try {
    const response = await api.get('/review');
    
    // 1. Ensure we have an array
    const rawData = Array.isArray(response.data) ? response.data : [];

    // 2. Filter out empty objects [ {} ] or invalid entries
    // This checks if the object actually has an order_id
    orders.value = rawData.filter(order => order && Object.keys(order).length > 0 && order.order_id);
    
  } catch (err) {
    console.error("API Error:", err);
    orders.value = []; // Reset to empty array on error
  } finally {
    loading.value = false;
  }
};

const filteredOrders = computed(() => {
  const searchTerm = search.value.toLowerCase();
  return orders.value.filter(o => {
    // Safety check: Ensure selections exists before calling toLowerCase
    const name = o.selections?.client_name?.toLowerCase() || '';
    const theme = o.selections?.cake_theme?.toLowerCase() || '';
    
    return name.includes(searchTerm) || theme.includes(searchTerm);
  });
});

onMounted(fetchOrders);
</script>
<style scoped>
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