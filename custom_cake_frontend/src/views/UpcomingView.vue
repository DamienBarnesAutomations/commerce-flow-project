<template>
  <div class="view-container">
    <div class="header-actions">
      <div class="search-wrapper">
        <input v-model="search" placeholder="Search by name or theme..." class="search-input" />
      </div>
      <div class="stats">
        <span class="count-badge">{{ filteredOrders.length }} Upcoming Tasks</span>
      </div>
    </div>

    <div v-if="loading" class="status-message">
      <div class="spinner"></div>
      <p>Loading your baking schedule...</p>
    </div>

    <div v-else class="order-grid">
      <OrderCard 
        v-for="order in filteredOrders" 
        :key="order.order_id" 
        :order="order" 
      />
    </div>

    <div v-if="!loading && filteredOrders.length === 0" class="empty-state">
      <div class="empty-icon">📅</div>
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
  try {
    // We filter for 'CONFIRMED' or 'PAID' statuses that aren't 'COMPLETED' yet
    const response = await api.get('/orders?status=CONFIRMED,UPCOMING');
    orders.value = response.data;
  } catch (err) {
    console.error("Error fetching upcoming orders:", err);
  } finally {
    loading.value = false;
  }
};

const filteredOrders = computed(() => {
  return orders.value.filter(o => 
    o.client_name.toLowerCase().includes(search.value.toLowerCase()) ||
    o.cake_theme.toLowerCase().includes(search.value.toLowerCase())
  ).sort((a, b) => new Date(a.event_date).getTime() - new Date(b.event_date).getTime());
});

onMounted(fetchUpcomingOrders);
</script>

<style scoped>
.header-actions {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 2rem;
  gap: 1rem;
}

.search-wrapper {
  flex: 1;
}

.stats {
  white-space: nowrap;
}

.order-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(320px, 1fr));
  gap: 2rem;
}

/* Specific styling for Upcoming View */
:deep(.order-card) {
  border-left: 6px solid #42b883; /* Solid Green for confirmed orders */
}

.empty-icon {
  font-size: 3rem;
  margin-bottom: 1rem;
}

.status-message {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  height: 300px;
  color: #666;
}

/* Simple Spinner */
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
</style>