<template>
  <div class="view-container">
    <div class="header-actions">
      <div class="search-wrapper">
        <span class="search-icon">🔍</span>
        <input v-model="search" placeholder="Search pending reviews..." class="search-input" />
      </div>
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
  loading.value = true;
  try {
    const response = await api.get('/review');
    const rawData = Array.isArray(response.data) ? response.data : [];
    orders.value = rawData.filter(order => order && Object.keys(order).length > 0 && order.order_id);
  } catch (err) {
    console.error("API Error:", err);
    orders.value = [];
  } finally {
    loading.value = false;
  }
};

const filteredOrders = computed(() => {
  const searchTerm = search.value.toLowerCase();
  return orders.value.filter(o => {
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
  max-width: 1400px;
  margin: 0 auto;
}

.order-grid {
  display: grid;
  /* Default: stack on mobile, grid on tablets/desktop */
  grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
  gap: 1.5rem;
  align-items: start;
}

/* Header & Search Styles */
.header-actions {
  display: flex;
  align-items: center;
  gap: 1rem;
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
  padding: 0.8rem 1rem 0.8rem 2.5rem; /* Space for icon */
  border: 1px solid #ddd;
  border-radius: 8px;
  font-size: 1rem;
  outline: none;
  transition: border-color 0.2s;
}

.search-input:focus {
  border-color: #42b883;
}

.count-badge {
  background: #eee;
  padding: 0.5rem 1rem;
  border-radius: 20px;
  font-weight: bold;
  color: #666;
  white-space: nowrap;
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
  background: white;
  border-radius: 12px;
  border: 2px dashed #eee;
}

/* --- Responsive Adjustments --- */

@media (max-width: 600px) {
  .view-container {
    padding: 1rem; /* Smaller padding on phones */
  }

  .header-actions {
    flex-direction: column; /* Stack search and badge */
    align-items: stretch;
    gap: 0.8rem;
  }

  .count-badge {
    text-align: center;
    font-size: 0.85rem;
  }

  .order-grid {
    grid-template-columns: 1fr; /* Single column on small phones */
    gap: 1rem;
  }
}

@media (min-width: 1200px) {
  .order-grid {
    grid-template-columns: repeat(4, 1fr);
  }
}
</style>