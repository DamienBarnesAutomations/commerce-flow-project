<script setup>
import { onMounted, ref } from 'vue'
import { usePosStore } from './stores/posStore'

const store = usePosStore()
const isMobileCartOpen = ref(false) 

onMounted(() => {
  if (store.fetchProducts) store.fetchProducts()
})
</script>

<template>
  <div class="flex flex-col lg:flex-row min-h-screen h-screen bg-zinc-950 text-zinc-100 overflow-hidden font-sans">
    
    <main class="flex-1 flex flex-col p-4 overflow-hidden">
      <header class="flex justify-between items-center mb-6">
        <div class="flex items-center gap-3">
          <img 
            :src="store.logo" 
            alt="Logo" 
            class="w-10 h-10 lg:w-20 lg:h-20 object-contain brightness-0 invert" 
          />
          <h1 class="text-lg lg:text-2xl font-bold tracking-tight">{{store.appTitle}}</h1>
        </div>

        <div class="flex items-center gap-2">
          <button @click="isMobileCartOpen = true" class="lg:hidden relative p-2 bg-zinc-900 rounded-xl border border-zinc-800">
            <svg class="w-6 h-6 text-emerald-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 3h2l.4 2M7 13h10l4-8H5.4M7 13L5.4 5M7 13l-2.293 2.293c-.63.63-.184 1.707.707 1.707H17m0 0a2 2 0 100 4 2 2 0 000-4zm-8 2a2 2 0 11-4 0 2 2 0 014 0z"></path>
            </svg>
            <span v-if="store.cartCount > 0" class="absolute -top-2 -right-2 bg-emerald-500 text-[10px] font-bold px-1.5 py-0.5 rounded-full shadow-lg">
              {{ store.cartCount }}
            </span>
          </button>

          <button @click="store.fetchDailySales()" class="p-2 hover:bg-zinc-800 rounded-full transition-colors group">
            <svg class="w-6 h-6 text-zinc-500 group-hover:text-emerald-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"></path>
            </svg>
          </button>
        </div>
      </header>
      
      <div class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 xl:grid-cols-5 gap-3 overflow-y-auto pr-2 custom-scrollbar">
        <div 
          v-for="product in store.products" :key="product.id"
          @click="store.addToCart(product)"
          class="bg-zinc-900 border border-zinc-800 p-2 sm:p-3 rounded-xl cursor-pointer hover:border-emerald-500/50 transition-all active:scale-95 group"
        >
          <div class="aspect-square bg-zinc-800 rounded-lg mb-2 overflow-hidden">
            <img :src="store.imageBaseUrl + product.img_url" class="w-full h-full object-cover group-hover:scale-110 transition-transform duration-500" />
          </div>
          <h3 class="font-bold text-xs sm:text-sm truncate">{{ product.name }}</h3>
          <p class="text-emerald-400 font-mono text-xs sm:text-sm">{{store.currency}}{{ product.price }}</p>
        </div>
      </div>
    </main>

    <aside 
      :class="[
        'fixed inset-y-0 right-0 z-50 w-full sm:w-96 bg-zinc-900 border-l border-zinc-800 flex flex-col shadow-2xl transition-transform duration-300 lg:relative lg:translate-x-0',
        isMobileCartOpen ? 'translate-x-0' : 'translate-x-full'
      ]"
    >
      <div class="p-6 border-b border-zinc-800 flex justify-between items-center">
        <div class="flex items-center gap-2">
          <button @click="isMobileCartOpen = false" class="lg:hidden text-zinc-400 pr-2">
            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path d="M15 19l-7-7 7-7" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/></svg>
          </button>
          <h2 class="text-xl font-bold">Order</h2>
        </div>
        <button @click="store.clearCart" class="text-xs text-zinc-500 hover:text-red-400 underline uppercase tracking-tighter">Clear All</button>
      </div>

      <div class="flex-1 overflow-y-auto p-4 space-y-3 custom-scrollbar">
        <div v-if="store.cart.length === 0" class="h-full flex flex-col items-center justify-center text-zinc-600 italic">
          <p>Cart is empty</p>
        </div>
        
        <div v-for="(item, index) in store.cart" :key="index" class="flex items-center gap-3 bg-zinc-950 p-3 rounded-lg border border-zinc-800">
          <div class="flex-1">
            <h4 class="text-sm font-bold leading-tight">{{ item.name }}</h4>
            <p class="text-xs text-zinc-500">{{store.currency}}{{ item.price }} x {{ item.quantity }}</p>
          </div>
          <div class="flex items-center gap-2">
            <span class="font-mono text-emerald-400">{{store.currency}}{{ (item.price * item.quantity).toFixed(2) }}</span>
            <button @click="store.removeFromCart(index)" class="w-8 h-8 flex items-center justify-center bg-zinc-900 rounded-lg text-zinc-600 hover:text-red-500 border border-zinc-800 transition-colors">×</button>
          </div>
        </div>
      </div>

      <div class="p-6 bg-zinc-950 border-t border-zinc-800 space-y-4">
        <div class="flex justify-between text-2xl font-bold text-white">
          <span>Total</span>
          <span class="text-emerald-400">{{store.currency}}{{ store.cartTotal.toFixed(2) }}</span>
        </div>
        <button 
          @click="store.checkout(); isMobileCartOpen = false"
          :disabled="store.loading || store.cart.length === 0"
          class="w-full py-4 rounded-xl font-bold text-lg transition-all active:translate-y-0.5 disabled:opacity-50"
          :class="store.loading ? 'bg-zinc-700' : 'bg-emerald-600 hover:bg-emerald-500 text-white'"
        >
          {{ store.loading ? 'PROCESSING...' : 'CHECKOUT' }}
        </button>
      </div>
    </aside>

    <div v-if="isMobileCartOpen" @click="isMobileCartOpen = false" class="fixed inset-0 bg-black/60 backdrop-blur-sm z-40 lg:hidden"></div>

    <Transition name="slide-fade">
      <div v-if="store.showSuccessToast" class="fixed top-6 right-6 z-[100] bg-emerald-500 text-white px-6 py-4 rounded-2xl shadow-2xl flex items-center gap-3 border border-emerald-400">
        <div class="bg-white/20 rounded-full p-1"><svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="3" d="M5 13l4 4L19 7"></path></svg></div>
        <p class="font-bold">Sale Recorded!</p>
      </div>
    </Transition>

    <div v-if="store.showSalesModal" class="fixed inset-0 z-[60] flex items-center justify-center p-4 bg-black/90 backdrop-blur-md">
      <div class="bg-zinc-900 border border-zinc-800 w-full max-w-2xl rounded-3xl flex flex-col max-h-[85vh] shadow-2xl">
        <div class="p-6 border-b border-zinc-800 flex justify-between items-center">
          <h2 class="text-xl font-bold">Daily Sales Activity</h2>
          <button @click="store.showSalesModal = false" class="p-2 hover:bg-zinc-800 rounded-xl text-zinc-400">✕</button>
        </div>
        
        <div class="flex-1 overflow-y-auto p-4 sm:p-6 space-y-3 custom-scrollbar">
          <div v-if="store.groupedSales.length === 0" class="flex flex-col items-center justify-center h-40 text-zinc-600 border-2 border-dashed border-zinc-800 rounded-2xl">
            <p>No transactions found for today.</p>
          </div>

          <div v-for="group in store.groupedSales" :key="group.id" class="border border-zinc-800 rounded-2xl bg-zinc-950/40 overflow-hidden">
            <div @click="store.toggleTransaction(group.id)" class="p-4 flex justify-between items-center cursor-pointer hover:bg-zinc-800/50 transition-colors">
              <div class="flex items-center gap-3">
                <span class="text-[10px] bg-zinc-900 px-2 py-1 rounded font-mono text-zinc-500">
                  {{ new Date(group.time).toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'}) }}
                </span>
                <span class="font-bold text-sm text-zinc-200">Order #{{ group.id }}</span>
              </div>
              <div class="flex items-center gap-4">
                <span class="font-bold text-emerald-400 font-mono text-lg">{{ store.currency }}{{ group.total.toFixed(2) }}</span>
                <svg :class="{'rotate-180': store.expandedTransactions?.includes(group.id)}" class="w-5 h-5 text-zinc-600 transition-transform duration-300" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path d="M19 9l-7 7-7-7" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
                </svg>
              </div>
            </div>

            <div v-if="store.expandedTransactions?.includes(group.id)" class="bg-black/30 border-t border-zinc-800 p-4 space-y-2">
              <div v-for="item in group.items" :key="item.id" class="flex justify-between text-xs sm:text-sm">
                <div class="flex gap-2 text-zinc-300">
                  <span class="text-emerald-500 font-bold opacity-70">{{ item.quantity }}x</span>
                  <span>{{ item.name }}</span>
                </div>
                <span class="text-zinc-500 font-mono">{{ store.currency }}{{ Number(item.total_price).toFixed(2) }}</span>
              </div>
            </div>
          </div>
        </div>

        <div class="p-6 border-t border-zinc-800 bg-zinc-950/80 rounded-b-3xl flex justify-between items-center">
          <div>
            <p class="text-zinc-500 text-[10px] font-bold uppercase tracking-widest leading-none">Day Total</p>
            <p class="text-3xl font-black text-emerald-500 font-mono mt-1">{{ store.currency }}{{ store.dayTotal.toFixed(2) }}</p>
          </div>
          <button @click="store.showSalesModal = false" class="px-8 py-3 bg-zinc-800 hover:bg-zinc-700 text-white rounded-xl font-bold text-sm transition-colors">CLOSE</button>
        </div>
      </div>
    </div>
  </div>
</template>

<style>
.custom-scrollbar::-webkit-scrollbar { width: 4px; }
.custom-scrollbar::-webkit-scrollbar-thumb { background: #3f3f46; border-radius: 10px; }

.slide-fade-enter-active { transition: all 0.3s ease-out; }
.slide-fade-leave-active { transition: all 0.2s cubic-bezier(1, 0.5, 0.8, 1); }
.slide-fade-enter-from, .slide-fade-leave-to { transform: translateX(20px); opacity: 0; }
</style>