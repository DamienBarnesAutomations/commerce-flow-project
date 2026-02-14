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
  try {
    // Matches orders identified by your n8n SQL query
    const response = await api.get('/orders?status=AWAITING_REVIEW');
    orders.value = response.data;
  } catch (err) {
    console.error("API Error:", err);
  } finally {
    loading.value = false;
  }
};

const filteredOrders = computed(() => {
  return orders.value.filter(o => 
    o.client_name.toLowerCase().includes(search.value.toLowerCase()) ||
    o.cake_theme.toLowerCase().includes(search.value.toLowerCase())
  );
});

onMounted(fetchOrders);
</script>