<template>
  <div class="view-container">
    <div class="header-actions">
      <div class="search-wrapper">
        <span class="search-icon">📅</span>
        <input v-model="search" placeholder="Search by name or theme..." class="search-input" />
      </div>
      <span class="count-badge">{{ filteredOrders.length }} Upcoming</span>
    </div>

    <div v-if="loading" class="status-message">
      <div class="spinner"></div>
      <p>Loading your baking schedule...</p>
    </div>

    <div v-else class="order-grid upcoming-theme">
      <OrderCard 
        v-for="order in filteredOrders" 
        :key="order.order_id" 
        :order="order" 
      />
    </div>

    <div v-if="!loading && filteredOrders.length === 0" class="empty-state">
      <div class="empty-icon">🍰</div>
      <h3>No upcoming orders</h3>
      <p>Enjoy the break! New orders will appear here once they are reviewed.</p>
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

const fetchUpcomingOrders = async () => {
  loading.value = true;
  try {
    const response = await api.get('/upcoming');
    const data = Array.isArray(response.data) ? response.data : [];
    orders.value = data.filter(order => order && order.order_id);
  } catch (err) {
    console.error("Error fetching upcoming orders:", err);
    orders.value = [];
  } finally {
    loading.value = false;
  }
};

const filteredOrders = computed(() => {
  const searchTerm = search.value.toLowerCase();
  
  return orders.value
    .filter(o => {
      const name = o.selections?.client_name?.toLowerCase() || '';
      const theme = o.selections?.cake_theme?.toLowerCase() || '';
      return name.includes(searchTerm) || theme.includes(searchTerm);
    })
    .sort((a, b) => {
      // Primary sort: Date (Soonest first)
      const dateA = new Date(a.selections?.event_date || 0).getTime();
      const dateB = new Date(b.selections?.event_date || 0).getTime();
      return dateA - dateB;
    });
});

onMounted(fetchUpcomingOrders);
</script>

<style scoped>
.view-container {
  padding: 2rem;
  max-width: 1400px;
  margin: 0 auto;
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
  padding: 0.8rem 1rem 0.8rem 2.5rem;
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

/* Grid System */
.order-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
  gap: 1.5rem;
  align-items: start;
}

/* Confirmed Status Indicator */
.upcoming-theme :deep(.order-card) {
  border-left: 6px solid #42b883;
}

/* Status & Loading */
.status-message {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 4rem 1rem;
  color: #666;
}

.spinner {
  width: 40px;
  height: 40px;
  border: 4px solid #f3f3f3;
  border-top: 4px solid #42b883;
  border-radius: 50%;
  animation: spin 1s linear infinite;
  margin-bottom: 1rem;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

.empty-state {
  text-align: center;
  padding: 4rem 1rem;
  color: #888;
  background: white;
  border-radius: 12px;
  border: 2px dashed #eee;
}

.empty-icon {
  font-size: 3rem;
  margin-bottom: 1rem;
}

/* --- Responsive Adjustments --- */
@media (max-width: 600px) {
  .view-container {
    padding: 1rem;
  }

  .header-actions {
    flex-direction: column;
    align-items: stretch;
    gap: 0.8rem;
    margin-bottom: 1.5rem;
  }

  .count-badge {
    text-align: center;
    font-size: 0.85rem;
  }

  .order-grid {
    grid-template-columns: 1fr;
    gap: 1rem;
  }
}

@media (min-width: 1200px) {
  .order-grid {
    grid-template-columns: repeat(4, 1fr);
  }
}
</style>