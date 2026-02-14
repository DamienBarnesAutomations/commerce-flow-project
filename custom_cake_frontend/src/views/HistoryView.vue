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
  try {
    const response = await api.get('/orders?status=COMPLETED,CANCELLED');
    orders.value = response.data;
  } catch (err) {
    console.error(err);
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
</style>