<script setup>
import { onMounted } from 'vue'
import { usePosStore } from './stores/posStore'

const store = usePosStore()
onMounted(() => store.fetchProducts())
</script>

<template>
  <div class="flex h-screen bg-zinc-950 text-zinc-100 overflow-hidden font-sans">
    
    <main class="flex-1 flex flex-col p-4 overflow-hidden">
      <header class="flex justify-between items-center mb-6">
        <div class="flex items-center gap-3">
          <img 
            :src="store.logo" 
            alt="Precious Place Logo" 
            class="w-40 h-40 object-contain invert" 
          />
          <h1 class="text-2xl font-bold tracking-tight">Precious Place POS</h1>
        </div>
        <button 
          @click="store.fetchDailySales()" 
          class="p-2 hover:bg-zinc-800 rounded-full transition-colors group"
        >
          <svg class="w-6 h-6 text-zinc-500 group-hover:text-emerald-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"></path>
          </svg>
        </button>
      </header>
      

      <div class="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5 gap-3 overflow-y-auto pr-2 custom-scrollbar">
        <div 
          v-for="product in store.products" :key="product.id"
          @click="store.addToCart(product)"
          class="bg-zinc-900 border border-zinc-800 p-3 rounded-xl cursor-pointer hover:border-emerald-500/50 transition-all active:scale-95 group"
        >
          <div class="aspect-square bg-zinc-800 rounded-lg mb-3 overflow-hidden">
            <img :src="store.imageBaseUrl + product.img_url" class="w-full h-full object-cover group-hover:scale-110 transition-transform duration-500" />
          </div>
          <h3 class="font-bold text-sm truncate">{{ product.name }}</h3>
          <p class="text-emerald-400 font-mono text-sm">{{store.currency}}{{ product.price }}</p>
        </div>
      </div>
    </main>

    <aside class="w-96 bg-zinc-900 border-l border-zinc-800 flex flex-col shadow-2xl">
      <div class="p-6 border-b border-zinc-800 flex justify-between items-center">
        <h2 class="text-xl font-bold">Current Order</h2>
        <button @click="store.clearCart" class="text-xs text-zinc-500 hover:text-red-400 underline">Clear All</button>
      </div>

      <div class="flex-1 overflow-y-auto p-4 space-y-3">
        <div v-if="store.cart.length === 0" class="h-full flex flex-col items-center justify-center text-zinc-600">
          <p>Cart is empty</p>
        </div>
        
        <div v-for="(item, index) in store.cart" :key="index" class="flex items-center gap-3 bg-zinc-950 p-3 rounded-lg border border-zinc-800">
          <div class="flex-1">
            <h4 class="text-sm font-bold">{{ item.name }}</h4>
            <p class="text-xs text-zinc-500">{{store.currency}}{{ item.price }} x {{ item.quantity }}</p>
          </div>
          <div class="flex items-center gap-2">
            <span class="font-mono text-emerald-400">{{store.currency}}{{ (item.price * item.quantity).toFixed(2) }}</span>
            <button @click="store.removeFromCart(index)" class="w-6 h-6 flex items-center justify-center text-zinc-600 hover:text-red-500">×</button>
          </div>
        </div>
      </div>

      <div class="p-6 bg-zinc-950 border-t border-zinc-800 space-y-4">
        <div class="flex justify-between text-zinc-400">
          <span>Items ({{ store.cartCount }})</span>
          <span>{{store.currency}}{{ store.cartTotal.toFixed(2) }}</span>
        </div>
        <div class="flex justify-between text-2xl font-bold text-white">
          <span>Total</span>
          <span class="text-emerald-400">{{store.currency}}{{ store.cartTotal.toFixed(2) }}</span>
        </div>
        <button 
          @click="store.checkout"
          :disabled="store.loading || store.cart.length === 0"
          class="w-full py-4 rounded-xl font-bold text-lg transition-all shadow-lg active:translate-y-0.5 disabled:opacity-50 disabled:cursor-not-allowed disabled:active:translate-y-0"
          :class="store.loading ? 'bg-zinc-700 text-zinc-400' : 'bg-emerald-600 hover:bg-emerald-500 text-white shadow-emerald-900/20'"
        >
          <span v-if="store.loading" class="flex items-center justify-center gap-2">
            <svg class="animate-spin h-5 w-5 text-zinc-400" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
              <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
              <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
            </svg>
            PROCESSING...
          </span>
          <span v-else>
            CHECKOUT 
          </span>
        </button>
        
      </div>
    </aside>
    <Transition name="slide-fade">
      <div v-if="store.showSuccessToast" class="fixed top-6 right-6 z-50 bg-emerald-500 text-white px-6 py-4 rounded-2xl shadow-2xl flex items-center gap-3 border border-emerald-400">
        <div class="bg-white/20 rounded-full p-1">
          <svg class="w-5 h-5 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="3" d="M5 13l4 4L19 7"></path></svg>
        </div>
        <div>
          <p class="font-bold leading-none">Sale Recorded!</p>
          <p class="text-xs opacity-90 mt-1 font-medium">Cart cleared successfully.</p>
        </div>
      </div>
    </Transition>
    <div v-if="store.showSalesModal" class="fixed inset-0 z-[60] flex items-center justify-center p-4 bg-black/90 backdrop-blur-md">
      <div class="bg-zinc-900 border border-zinc-800 w-full max-w-2xl rounded-3xl flex flex-col max-h-[85vh] shadow-2xl">
        
        <div class="p-6 border-b border-zinc-800 flex justify-between items-center">
          <div>
            <h2 class="text-xl font-bold text-white leading-none">Daily Sales Activity</h2>
            <p class="text-zinc-500 text-sm mt-1">Today's transactions and breakdowns</p>
          </div>
          <button @click="store.showSalesModal = false" class="p-2 hover:bg-zinc-800 rounded-xl text-zinc-400 transition-colors">
            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path></svg>
          </button>
        </div>

        <div class="flex-1 overflow-y-auto p-6 space-y-3">
          <div v-for="group in store.groupedSales" :key="group.id" 
              class="border border-zinc-800 rounded-2xl bg-zinc-950/40 transition-all overflow-hidden">
            
            <div @click="store.toggleTransaction(group.id)" 
                class="p-4 flex justify-between items-center cursor-pointer hover:bg-zinc-800/50 select-none">
              <div class="flex items-center gap-4">
                <div class="text-zinc-500 font-mono text-xs bg-zinc-900 px-2 py-1 rounded">
                  {{ new Date(group.time).toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'}) }}
                </div>
                <span class="font-semibold text-zinc-200 uppercase tracking-wide text-sm">Order #{{ group.id }}</span>
              </div>
              <div class="flex items-center gap-4">
                <span class="font-bold text-emerald-400 font-mono text-lg"> {{ store.currency }} {{ group.total.toFixed(2) }}</span>
                <svg :class="{'rotate-180': store.expandedTransactions?.includes(group.id)}" 
                    class="w-5 h-5 text-zinc-600 transition-transform duration-300" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path d="M19 9l-7 7-7-7" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/>
                </svg>
              </div>
            </div>

            <div v-if="store.expandedTransactions?.includes(group.id)" 
                class="bg-black/30 border-t border-zinc-800 p-4 space-y-2">
              <div v-for="item in group.items" :key="item.id" class="flex justify-between text-sm animate-in fade-in slide-in-from-top-1">
                <div class="flex gap-3 text-zinc-300">
                  <span class="text-zinc-600 font-bold w-4">{{ item.quantity }}x</span>
                  <span>{{ item.name }}</span>
                </div>
                <span class="text-zinc-500 font-mono"> {{ store.currency }} {{ Number(item.total_price).toFixed(2) }}</span>
              </div>
            </div>
          </div>
        </div>

        <div class="p-6 border-t border-zinc-800 bg-zinc-950/80 rounded-b-3xl">
          <div class="flex justify-between items-end">
            <div>
              <p class="text-zinc-500 text-xs font-bold uppercase tracking-widest">Grand Total</p>
              <p class="text-3xl font-black text-emerald-500 font-mono mt-1">{{ store.currency }} {{ store.dayTotal.toFixed(2) }}</p>
            </div>
            <button @click="store.showSalesModal = false" class="px-6 py-2 bg-zinc-800 hover:bg-zinc-700 text-white rounded-xl font-bold text-sm transition-colors">
              CLOSE
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
  
</template>

<style>
.custom-scrollbar::-webkit-scrollbar { width: 4px; }
.custom-scrollbar::-webkit-scrollbar-thumb { background: #3f3f46; border-radius: 10px; }
</style>