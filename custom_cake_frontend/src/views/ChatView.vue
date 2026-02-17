<script setup lang="ts">
import { ref, onMounted, onUnmounted, nextTick, watch } from 'vue';
import api from '../services/api';

const userList = ref<any[]>([]);
const messages = ref<any[]>([]);
const selectedUser = ref<any>(null);
const newMessage = ref('');
const loadingUsers = ref(true);
const isSidebarVisible = ref(true);
const messageBox = ref<HTMLElement | null>(null);

// Timer reference for polling
let pollTimer: number | null = null;

const fetchUsers = async () => {
  try {
    const response = await api.get('/chatSessions');
    userList.value = response.data;
  } catch (err) { 
    console.error('Error fetching users:', err); 
  } finally { 
    loadingUsers.value = false; 
  }
};

const fetchMessages = async (isAutoPoll = false) => {
  if (!selectedUser.value) return;
  
  try {
    const response = await api.get('/chatLogs', { 
      params: { customer_id: selectedUser.value.customer_id } 
    });
    
    // Only update and scroll if the message count actually changed
    if (response.data.length !== messages.value.length) {
      messages.value = response.data;
      
      await nextTick();
      if (messageBox.value) {
        // Smart Scroll: only scroll to bottom if user is close to it
        const threshold = 150; 
        const isNearBottom = messageBox.value.scrollHeight - messageBox.value.scrollTop - messageBox.value.clientHeight < threshold;
        
        if (isNearBottom || !isAutoPoll) {
          messageBox.value.scrollTop = messageBox.value.scrollHeight;
        }
      }
    }
  } catch (err) {
    console.error('Error fetching messages:', err);
  }
};

const startPolling = () => {
  stopPolling(); // Clear existing
  pollTimer = window.setInterval(() => {
    fetchMessages(true);
  }, 3000); // Poll every 3 seconds
};

const stopPolling = () => {
  if (pollTimer) {
    clearInterval(pollTimer);
    pollTimer = null;
  }
};

const handleSelectUser = async (user: any) => {
  selectedUser.value = user;
  isSidebarVisible.value = false;
  messages.value = []; // Clear current view while loading
  await fetchMessages();
  startPolling(); // Start polling for the new user
};

const handleSendMessage = async () => {
  if (!newMessage.value.trim() || !selectedUser.value) return;
  try {
    await api.post('/sendChatMessage', {
      customer_id: selectedUser.value.customer_id,
      message: newMessage.value,
      source: selectedUser.value.source
    });
    newMessage.value = '';
    await fetchMessages(); // Immediate refresh after sending
  } catch (err) {
    console.error('Error sending message:', err);
  }
};

const formatTime = (dateStr: string) => new Date(dateStr).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });

onMounted(() => {
  fetchUsers();
  // Optional: Poll the user list too if you want to see new incoming chats
  setInterval(fetchUsers, 10000); 
});

onUnmounted(() => {
  stopPolling();
});
</script>

<template>
  <div class="chat-view-container">
    <aside :class="['chat-sidebar', { 'hidden-mobile': !isSidebarVisible }]">
      <div class="sidebar-header">
        <h3>Conversations</h3>
      </div>

      <div class="user-list">
        <div 
          v-for="user in userList" 
          :key="user.customer_id" 
          :class="['user-item', { active: selectedUser?.customer_id === user.customer_id }]"
          @click="handleSelectUser(user)"
        >
          <div class="user-avatar">
            {{ user.customer_id.slice(-2) }}
            <span v-if="user.current_state === 'TALK_TO_HUMAN'" class="status-dot orange"></span>
          </div>
          <div class="user-info">
            <div class="user-top-row">
              <div class="user-id">{{ user.customer_id }}</div>
              <div class="time-ago">{{ formatTime(user.last_interaction) }}</div>
            </div>
            <span class="source-tag">{{ user.source }}</span>
          </div>
        </div>
      </div>
    </aside>

    <main :class="['chat-window', { 'hidden-mobile': isSidebarVisible }]">
      <div v-if="selectedUser" class="chat-content">
        <header class="chat-header">
          <button class="mobile-back-btn" @click="isSidebarVisible = true">← Back</button>
          <div class="header-details">
            <h3>Customer ID: {{ selectedUser.customer_id }}</h3>
            <span :class="['state-badge', { urgent: selectedUser.current_state === 'TALK_TO_HUMAN' }]">
              {{ selectedUser.current_state === 'TALK_TO_HUMAN' ? 'Needs Human' : 'Bot Active' }}
            </span>
          </div>
        </header>
        
        <div class="message-list" ref="messageBox">
          <template v-for="log in messages" :key="log.id">
            <div v-if="log.customer_message && log.customer_message.trim() !== ''" class="message received">
              <div class="message-bubble">
                <span class="sender-label">Customer</span>
                <div class="text">{{ log.customer_message }}</div>
                <span class="timestamp">{{ formatTime(log.created_at) }}</span>
              </div>
            </div>

            <div v-if="log.response && log.response.trim() !== ''" class="message sent">
              <div class="message-bubble">
                <span class="sender-label">System</span>
                <div class="formatted-text">{{ log.response }}</div>
                <span class="timestamp">{{ formatTime(log.created_at) }}</span>
              </div>
            </div>
          </template>
        </div>

        <div class="chat-input-area">
          <input 
            v-model="newMessage" 
            @keyup.enter="handleSendMessage" 
            placeholder="Type a message..." 
          />
          <button 
            @click="handleSendMessage" 
            :disabled="!newMessage.trim()" 
            class="send-btn"
          >
            Send
          </button>
        </div>
      </div>
      
      <div v-else class="no-selection">
        <p>Select a conversation to start</p>
      </div>
    </main>
  </div>
</template>

<style scoped>
/* Keeping your exact styles from the previous turn */
.chat-view-container {
  display: flex;
  position: fixed; 
  top: 64px;       
  left: 260px;     
  right: 0;
  bottom: 0;
  background: white;
  overflow: hidden;
  z-index: 10;
}

.chat-sidebar {
  width: 220px;
  border-right: 1px solid #eee;
  display: flex;
  flex-direction: column;
  flex-shrink: 0;
  background: #fcfcfc;
}
.user-list { flex: 1; overflow-y: auto; }

.chat-window {
  flex: 1;
  display: flex;
  flex-direction: column;
  min-width: 0;
}
.chat-content { height: 100%; display: flex; flex-direction: column; overflow: hidden; }

.message-list {
  flex: 1;
  overflow-y: auto;
  padding: 1rem;
  background: #f9fbfb;
  display: flex;
  flex-direction: column;
  gap: 0.5rem; 
}

.message { display: flex; width: 100%; }
.message.received { justify-content: flex-start; }
.message.sent { justify-content: flex-end; }

.message-bubble { 
  max-width: 70%; 
  padding: 0.5rem 0.5rem; 
  border-radius: 12px; 
  font-size: 0.95rem; 
  position: relative;
  box-shadow: 0 1px 2px rgba(0,0,0,0.05);
}

.received .message-bubble { 
  background: white; 
  border: 1px solid #eee; 
  color: #333;
  border-bottom-left-radius: 1px;
}

.sent .message-bubble { 
  background: #42b883; 
  color: white; 
  border-bottom-right-radius: 1px;
}

.sender-label { 
  font-size: 0.7rem; 
  font-weight: bold; 
  margin-bottom: 4px; 
  display: block; 
  opacity: 0.8;
  text-transform: uppercase;
}

.formatted-text { white-space: pre-wrap; }
.timestamp { font-size: 0.65rem; display: block; margin-top: 4px; opacity: 0.7; text-align: right; }

.time-ago { font-size: 0.65rem; color: #888; }
.source-tag {
  font-size: 0.75rem;
  background: #e0e0e0;
  color: #555;
  padding: 2px 8px;
  border-radius: 12px;
  margin-top: 4px;
  display: inline-block;
}

.chat-header {
  padding: 1.2rem 1.5rem;
  border-bottom: 1px solid #eee;
  display: flex;
  align-items: center;
  gap: 12px;
}
.header-details h3 { margin: 1; font-size: 1.2rem; padding-bottom: 2px;}
.state-badge { font-size: 0.75rem; padding: 4px 10px; border-radius: 6px; font-weight: bold; background: #f0f0f0; }
.state-badge.urgent { background: #fee2e2; color: #dc2626; }

.user-avatar { width: 40px; height: 40px; background: #e2e8f0; border-radius: 50%; display: flex; align-items: center; justify-content: center; margin-right: 12px; position: relative; flex-shrink: 0; font-weight: bold; }
.status-dot { position: absolute; bottom: 0; right: 0; width: 10px; height: 10px; border-radius: 50%; border: 2px solid #fff; background: orange; }
.user-item { display: flex; align-items: center; padding: 1rem; border-bottom: 1px solid #f9f9f9; cursor: pointer; }
.user-item.active { background: #f0fdf4; border-left: 4px solid #42b883; }

.chat-input-area { padding: 1rem; border-top: 1px solid #eee; display: flex; gap: 10px; background: white; }
.chat-input-area input { flex: 1; padding: 12px 18px; border: 1px solid #ddd; border-radius: 25px; outline: none; }
.send-btn { background: #42b883; color: white; border: none; padding: 0 20px; border-radius: 25px; font-weight: bold; cursor: pointer; }

.no-selection { flex: 1; display: flex; align-items: center; justify-content: center; color: #888; font-size: 1.2rem; }

@media (max-width: 768px) {
  .chat-view-container { left: 0; top: 56px; }
  .chat-sidebar.hidden-mobile, .chat-window.hidden-mobile { display: none; }
  .chat-sidebar { width: 100%; }
  .mobile-back-btn { display: block; background: none; border: none; color: #42b883; font-weight: bold; margin-right: 10px; }
}
.mobile-back-btn { display: none; }
</style>