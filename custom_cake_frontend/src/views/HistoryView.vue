<template>
  <div class="view-container">
    <div class="header-actions">
      <div class="search-wrapper">
        <span class="search-icon">📜</span>
        <input v-model="search" placeholder="Search order history by name or ID..." class="search-input" />
      </div>
    </div>

    <div v-if="loading" class="status-message">
      <div class="spinner"></div> Loading archives...
    </div>

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
    
    const rawData = Array.isArray(response.data) ? response.data : [];

    // Filter, sanitize, and sort by date descending
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
  const term = search.value.toLowerCase();
  return orders.value.filter(o => {
    // Check selections.client_name and order_id
    const name = o.selections?.client_name?.toLowerCase() || '';
    const id = o.order_id?.toString() || '';
    return name.includes(term) || id.includes(term);
  });
});

onMounted(fetchOrders);
</script>

<style scoped>
.view-container {
  padding: 2rem;
  max-width: 1400px;
  margin: 0 auto;
}

/* History-specific styling to differentiate from active orders */
.grayscale-cards :deep(.order-card) {
  border-left: 4px solid #bdc3c7;
  filter: grayscale(0.4);
  opacity: 0.9;
  transition: all 0.3s ease;
}

.grayscale-cards :deep(.order-card:hover) {
  filter: grayscale(0);
  opacity: 1;
  border-left-color: #7f8c8d;
}

.order-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
  gap: 1.5rem;
  align-items: start;
}

/* Header & Search Styles */
.header-actions {
  display: flex;
  align-items: center;
  margin-bottom: 2rem;
}

.search-wrapper {
  position: relative;
  flex: 1;
}

.search-icon {
  position: absolute;
  left: 12px;
  top: 50%;
  transform: translateY(-50%);
  color: #999;
  pointer-events: none;
}

.search-input {
  width: 100%;
  padding: 0.8rem 1rem 0.8rem 2.5rem;
  border: 1px solid #ddd;
  border-radius: 8px;
  font-size: 1rem;
  outline: none;
}

.search-input:focus {
  border-color: #999;
}

.status-message {
  text-align: center;
  padding: 3rem;
  color: #666;
}

.empty-state {
  text-align: center;
  padding: 4rem 1rem;
  color: #999;
  background: #fdfdfd;
  border-radius: 12px;
  border: 2px dashed #ddd;
}

/* --- Responsive Adjustments --- */

@media (max-width: 600px) {
  .view-container {
    padding: 1rem;
  }

  .order-grid {
    grid-template-columns: 1fr;
    gap: 1rem;
  }

  .header-actions {
    margin-bottom: 1.5rem;
  }
}

@media (min-width: 1200px) {
  .order-grid {
    grid-template-columns: repeat(4, 1fr);
  }
}
</style>