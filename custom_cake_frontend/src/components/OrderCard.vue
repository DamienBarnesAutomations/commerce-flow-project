<template>
  <div class="card-container">
    <div class="order-card" @click="isModalOpen = true">
      <div class="card-header">
        <span class="order-id">#{{ order.order_id }}</span>
        <span 
          v-if="order.order_status_id" 
          :class="['status-badge', order.order_status_id.toLowerCase()]"
        >
          {{ order.order_status_id.replace('_', ' ') }}
        </span>
        <span v-else class="status-badge pending">Pending</span>
      </div>

      <h3 class="client-name">{{ order.selections?.client_name || 'No Name Provided' }}</h3>
      <p class="cake-theme">✨ {{ order.selections?.cake_theme || 'No Theme' }}</p>
      
      <div class="card-footer">
        <div class="footer-details">
          <div>📅 {{ formatDate(order.selections?.event_date) }}</div>
          <div>🎂 {{ order.selections?.tiers }} Tiers</div>
        </div>
        <div class="price-display">
          {{ order.quoted_price > 0 ? `$${order.quoted_price}` : 'Price Pending' }}
        </div>
      </div>
    </div>

    <Teleport to="body">
      <div v-if="isModalOpen" class="modal-overlay" @click.self="isModalOpen = false">
        <div class="modal-content">
          <button class="close-btn" @click="isModalOpen = false">×</button>
          
          <header class="modal-header">
            <h2 class="compact-title">Order #{{ order.order_id }}</h2>
            <div class="header-meta">
              <p class="customer-sub">Customer ID: {{ order.customer_id }}</p>
              
              <a 
                v-if="fullImagePath" 
                :href="fullImagePath" 
                target="_blank" 
                class="image-link"
              >
                🖼️ View Reference Image
              </a>
            </div>
          </header>

          <div class="modal-body">
            <section class="info-grid">
              <div class="info-item"><strong>Date:</strong> {{ formatDate(order.selections?.event_date) }}</div>
              <div class="info-item"><strong>Theme:</strong> {{ order.selections?.cake_theme }}</div>
              <div class="info-item"><strong>AC:</strong> {{ order.selections?.has_ac ? '✅' : '❌' }}</div>
              <div class="info-item"><strong>Delivery:</strong> {{ order.selections?.delivery ? order.selections?.delivery_address : 'Bakery Pickup' }}</div>
            </section>

            <div class="tier-list">
              <div v-for="tier in order.selections?.tier_definitions" :key="tier.tier_index" class="tier-row">
                <strong>T{{ tier.tier_index }}</strong>: {{ tier.size }}" {{ tier.flavor }} ({{ tier.layers }} layers)
              </div>
            </div>

            <div v-if="order.selections?.special_note" class="special-note-box">
              <label class="section-label">Special Instructions</label>
              <p class="note-text">"{{ order.selections.special_note }}"</p>
            </div>
            
            <hr class="divider" />

            <div class="admin-section">
              <div class="notes-grid">
                <div class="field-group">
                  <label>Note to Customer</label>
                  <textarea 
                    v-if="order.order_status_id === 'AWAITING_REVIEW'"
                    v-model="editForm.user_note"
                    placeholder="Pricing/pickup details..."
                  ></textarea>
                  <div v-else class="read-only-display">{{ order.user_note || 'No note to customer.' }}</div>
                </div>

                <div class="field-group">
                  <label>Admin Note</label>
                  <textarea 
                    v-if="order.order_status_id === 'AWAITING_REVIEW'"
                    v-model="editForm.admin_note"
                    placeholder="Staff only..."
                  ></textarea>
                  <div v-else class="read-only-display">{{ order.admin_note || 'No admin notes.' }}</div>
                </div>
              </div>

              <div class="action-grid">
                <div class="field-group">
                  <label>Quoted Price ($)</label>
                  <input 
                    v-if="order.order_status_id === 'AWAITING_REVIEW'"
                    type="number" 
                    v-model.number="editForm.quoted_price"
                    step="0.01"
                  />
                  <div v-else class="read-only-display price-tag-large">
                    {{ order.quoted_price ? `$${order.quoted_price}` : 'No Price' }}
                  </div>
                </div>

                <div v-if="order.order_status_id === 'AWAITING_REVIEW'" class="field-group">
                  <label>Review Status</label>
                  <select v-model="editForm.review_status">
                    <option value="PENDING">Pending</option>
                    <option value="APPROVED">Approved</option>
                    <option value="REJECTED">Rejected</option>
                  </select>
                </div>
              </div>
              
              <p v-if="order.order_status_id === 'AWAITING_REVIEW' && !isFormValid" class="validation-msg">
                ⚠️ Fill both notes, Price > 0, and Status != Pending.
              </p>
            </div>
          </div>

          <footer class="modal-footer">
            <button 
              v-if="order.order_status_id === 'AWAITING_REVIEW'" 
              @click="handleSave" 
              class="action-btn"
              :disabled="!isFormValid"
            >
              Save & Finalize
            </button>
            <button @click="isModalOpen = false" class="secondary-btn">Close</button>
          </footer>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, watch, computed } from 'vue';
import api from '../services/api';

const props = defineProps<{ order: any }>();
const isModalOpen = ref(false);

const editForm = reactive({
  user_note: '',
  admin_note: '',
  quoted_price: 0,
  review_status: 'PENDING'
});

const isFormValid = computed(() => {
  return editForm.user_note.trim() && 
         editForm.admin_note.trim() && 
         editForm.review_status !== 'PENDING' && 
         editForm.quoted_price > 0;
});

watch(isModalOpen, (isOpen) => {
  if (isOpen) {
    editForm.user_note = props.order.user_note || '';
    editForm.admin_note = props.order.admin_note || '';
    editForm.quoted_price = props.order.quoted_price || 0;
    editForm.review_status = props.order.review_status || 'PENDING';
  }
});

const formatDate = (d: string | undefined) => {
  if (!d) return 'TBD';
  return new Date(d).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
};

const handleSave = async () => {
  if (!isFormValid.value) return;
  try {
    await api.post('/performReview', {
      order_id: props.order.order_id,
      user_note: editForm.user_note,
      admin_note: editForm.admin_note,
      quoted_price: editForm.quoted_price,
      review_status: editForm.review_status
    });
  } catch (err) {
    console.error(err);
  } finally {
    isModalOpen.value = false;
  }
};

const IMAGE_BASE_URL = import.meta.env.VITE_IMAGE_BASE_URL || '';

// Create a computed property for the full image path
const fullImagePath = computed(() => {
  const path = props.order.selections?.image_reference;
  if (!path) return null;
  
  // If the path is already an absolute URL, return it as is
  if (path.startsWith('http')) return path;
  
  // Combine base URL with the reference, ensuring no double slashes
  return `${IMAGE_BASE_URL.replace(/\/$/, '')}/${path.replace(/^\//, '')}`;
});
</script>

<style scoped>
/* (Existing styles preserved) */
.order-card { background: white; border-radius: 12px; padding: 1.2rem; cursor: pointer; transition: transform 0.2s, box-shadow 0.2s; box-shadow: 0 4px 6px rgba(0,0,0,0.05); border: 1px solid #eee; height: 100%; display: flex; flex-direction: column; }
.order-card:hover { transform: translateY(-4px); box-shadow: 0 10px 15px rgba(0,0,0,0.1); }
.card-header { display: flex; justify-content: space-between; margin-bottom: 0.3rem; }
.order-id { font-weight: bold; color: #888; font-size: 0.75rem; }
.status-badge { font-size: 0.65rem; padding: 2px 8px; border-radius: 20px; text-transform: uppercase; font-weight: bold; }
.status-badge.awaiting_review { background: #fff3cd; color: #856404; }
.status-badge.upcoming { background: #d4edda; color: #155724; }

.client-name { margin: 0.2rem 0; font-size: 1.1rem; color: #2c3e50; }
.cake-theme { color: #666; font-size: 0.9rem; margin-bottom: 1rem; flex-grow: 1; }

.card-footer { display: flex; justify-content: space-between; align-items: flex-end; border-top: 1px solid #f8f8f8; padding-top: 0.8rem; }
.footer-details { font-size: 0.75rem; color: #999; line-height: 1.4; }
.price-display { color: #42b883; font-weight: 800; font-size: 1.1rem; }

.modal-overlay { position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: rgba(0,0,0,0.6); display: flex; align-items: center; justify-content: center; z-index: 1000; }
.modal-content { background: white; padding: 1.5rem; border-radius: 16px; width: 95%; max-width: 650px; position: relative; max-height: 90vh; overflow-y: auto; }
.close-btn { position: absolute; top: 0.5rem; right: 1rem; font-size: 1.5rem; border: none; background: none; cursor: pointer; }

/* NEW HEADER META STYLES */
.header-meta { display: flex; justify-content: space-between; align-items: center; margin-top: 4px; }
.image-link { font-size: 0.75rem; color: #3498db; text-decoration: none; font-weight: bold; }
.image-link:hover { text-decoration: underline; }

.compact-title { margin: 0; font-size: 1.25rem; }
.customer-sub { margin: 0; font-size: 0.8rem; color: #666; }

.info-grid { display: grid; grid-template-columns: repeat(2, 1fr); gap: 0.5rem; margin: 0.8rem 0; border-top: 1px solid #eee; padding-top: 0.8rem; font-size: 0.85rem; }
.tier-row { background: #f9f9f9; padding: 0.4rem 0.6rem; border-radius: 6px; margin-bottom: 0.3rem; font-size: 0.8rem; }

/* NEW SPECIAL NOTE STYLES */
.special-note-box { background: #fff9db; padding: 0.8rem; border-radius: 8px; border-left: 4px solid #fcc419; margin: 1rem 0; }
.section-label { font-size: 0.65rem; font-weight: 800; color: #856404; text-transform: uppercase; display: block; margin-bottom: 4px; }
.note-text { margin: 0; font-size: 0.9rem; font-style: italic; color: #444; }

.divider { border: 0; border-top: 1px solid #eee; margin: 0.8rem 0; }
.admin-section { display: flex; flex-direction: column; gap: 0.8rem; }
.notes-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 0.8rem; }
.field-group { display: flex; flex-direction: column; gap: 0.2rem; }
.field-group label { font-size: 0.7rem; font-weight: bold; color: #999; text-transform: uppercase; }
.read-only-display { background: #fcfcfc; padding: 0.5rem; border-radius: 4px; border: 1px solid #f0f0f0; font-size: 0.85rem; min-height: 1.5rem; }

textarea { width: 100%; min-height: 60px; padding: 0.5rem; border: 1px solid #ddd; border-radius: 4px; font-family: inherit; font-size: 0.85rem; }
input, select { padding: 0.5rem; border: 1px solid #ddd; border-radius: 4px; background: white; font-size: 0.85rem; }

.action-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 0.8rem; }
.price-tag-large { font-weight: bold; color: #42b883; font-size: 1rem; }
.validation-msg { font-size: 0.75rem; color: #e74c3c; margin: 0; text-align: center; }

.modal-footer { margin-top: 1.2rem; display: flex; gap: 0.8rem; }
.action-btn { background: #42b883; color: white; border: none; padding: 0.6rem; border-radius: 6px; cursor: pointer; font-weight: bold; flex: 2; }
.action-btn:disabled { background: #bdc3c7; opacity: 0.7; }
.secondary-btn { background: #eee; color: #666; border: none; padding: 0.6rem; border-radius: 6px; cursor: pointer; flex: 1; }
</style>