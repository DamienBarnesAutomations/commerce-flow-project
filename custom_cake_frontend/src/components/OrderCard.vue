<template>
  <div class="card-container">
    <div class="order-card" @click="isModalOpen = true">
      <div class="card-header">
        <span class="order-id">#{{ order.order_id }}</span>
        <span :class="['status-badge', order.status.toLowerCase()]">{{ order.status }}</span>
      </div>
      <h3 class="client-name">{{ order.client_name }}</h3>
      <p class="cake-theme">✨ {{ order.cake_theme }}</p>
      <div class="card-footer">
        <span>📅 {{ formatDate(order.event_date) }}</span>
        <span>🎂 {{ order.tiers }} Tiers</span>
      </div>
    </div>

    <Teleport to="body">
      <div v-if="isModalOpen" class="modal-overlay" @click.self="isModalOpen = false">
        <div class="modal-content">
          <button class="close-btn" @click="isModalOpen = false">×</button>
          
          <header class="modal-header">
            <h2>Order Details #{{ order.order_id }}</h2>
            <p>{{ order.client_name }}'s Cake</p>
          </header>

          <div class="modal-body">
            <section class="info-grid">
              <div class="info-item"><strong>Date:</strong> {{ formatDate(order.event_date) }}</div>
              <div class="info-item"><strong>Theme:</strong> {{ order.cake_theme }}</div>
              <div class="info-item"><strong>AC Required:</strong> {{ order.has_ac ? '✅ Yes' : '❌ No' }}</div>
              <div class="info-item"><strong>Delivery:</strong> {{ order.delivery ? order.delivery_address : 'Bakery Pickup' }}</div>
            </section>

            <div class="tier-list">
              <div v-for="tier in order.tier_definitions" :key="tier.tier_index" class="tier-row">
                <strong>Tier {{ tier.tier_index }}</strong>: {{ tier.size }}" {{ tier.flavor }} ({{ tier.layers }} layers)
              </div>
            </div>
            
            <div v-if="order.order_description" class="description">
              <strong>Notes:</strong> {{ order.order_description }}
            </div>
          </div>

          <footer class="modal-footer">
            <button v-if="order.status === 'AWAITING_REVIEW'" @click="goToReview" class="action-btn">
              Open Pricing Review
            </button>
            <button @click="isModalOpen = false" class="secondary-btn">Close</button>
          </footer>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue';
import { useRouter } from 'vue-router';

const props = defineProps<{ order: any }>();
const isModalOpen = ref(false);
const router = useRouter();

const formatDate = (d: string) => new Date(d).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });

const goToReview = () => {
  router.push(`/review/${props.order.order_id}`);
};
</script>

<style scoped>
.order-card {
  background: white;
  border-radius: 12px;
  padding: 1.5rem;
  cursor: pointer;
  transition: transform 0.2s, box-shadow 0.2s;
  box-shadow: 0 4px 6px rgba(0,0,0,0.05);
  border: 1px solid #eee;
}
.order-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 10px 15px rgba(0,0,0,0.1);
}
.card-header { display: flex; justify-content: space-between; margin-bottom: 0.5rem; }
.order-id { font-weight: bold; color: #888; font-size: 0.8rem; }
.status-badge { font-size: 0.7rem; padding: 2px 8px; border-radius: 20px; text-transform: uppercase; font-weight: bold; }
.status-badge.awaiting_review { background: #fff3cd; color: #856404; }
.status-badge.upcoming { background: #d4edda; color: #155724; }

/* Modal Styles */
.modal-overlay {
  position: fixed; top: 0; left: 0; width: 100%; height: 100%;
  background: rgba(0,0,0,0.6); display: flex; align-items: center; justify-content: center; z-index: 1000;
}
.modal-content {
  background: white; padding: 2.5rem; border-radius: 16px; width: 90%; max-width: 600px;
  position: relative; max-height: 80vh; overflow-y: auto;
}
.close-btn { position: absolute; top: 1rem; right: 1.5rem; font-size: 2rem; border: none; background: none; cursor: pointer; }
.info-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 1rem; margin: 1.5rem 0; border-top: 1px solid #eee; padding-top: 1rem; }
.tier-row { background: #f9f9f9; padding: 0.75rem; border-radius: 8px; margin-bottom: 0.5rem; }
.action-btn { background: #42b883; color: white; border: none; padding: 0.8rem 1.5rem; border-radius: 8px; cursor: pointer; width: 100%; font-weight: bold; }
</style>