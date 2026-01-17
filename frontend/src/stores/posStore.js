import { defineStore } from 'pinia'
import axios from 'axios'

const getProductsWebhook = import.meta.env.VITE_GET_PRODUCTS_WEBHOOK;
const imageBase = import.meta.env.VITE_IMAGE_BASE_URL;
const logo = import.meta.env.VITE_LOGO;
const recordSalesWebhook = import.meta.env.VITE_RECORD_SALES_WEBHOOK;
const dailySalesWebhook = import.meta.env.VITE_DAILY_SALES_WEBHOOK;
const currency = import.meta.env.VITE_CURRENCY;
const appTitle = import.meta.env.VITE_APP_TITLE;

export const usePosStore = defineStore('pos', {
  state: () => ({
    products: [],
    cart: [],
    loading: false,
    imageBaseUrl: imageBase,
    showSuccessToast: false,
    logo: imageBase + "precious_place_logo-removebg.png",
    currency: currency,
    expandedTransactions: [],
    todaySales: [],
    appTitle: appTitle,
  }),
  
  getters: {
    cartTotal: (state) => state.cart.reduce((total, item) => total + (item.price * item.quantity), 0),
    cartCount: (state) => state.cart.reduce((count, item) => count + item.quantity, 0), 
    dayTotal: (state) => { 
        if (!state.todaySales || !Array.isArray(state.todaySales)) {
            return 0;
        }
        return state.todaySales.reduce((sum, sale) => sum + Number(sale.total_price), 0);},
    groupedSales: (state) => {
        // Safety Guard: If todaySales is null or undefined, return an empty array
    if (!state.todaySales || !Array.isArray(state.todaySales)) {
      return [];
    }
    const groups = {};
    state.todaySales.forEach(item => {
      if (!groups[item.transaction_id]) {
        groups[item.transaction_id] = {
          id: item.transaction_id,
          time: item.created_at,
          items: [],
          total: 0
        };
      }
      groups[item.transaction_id].items.push(item);
      groups[item.transaction_id].total += Number(item.total_price);
    });
    // Return as array sorted by most recent
    return Object.values(groups).sort((a, b) => new Date(b.time) - new Date(a.time));
  }
  },

  actions: {
    async fetchProducts() {
      this.loading = true
      try {
        // Points to your n8n Webhook
        const response = await axios.get(getProductsWebhook)
        this.products = response.data.map(p => ({
            ...p,
            price: Number(p.price) // Convert here once, use everywhere safely
        }));
        this.products = response.data
      } catch (error) {
        console.error("Failed to fetch products:", error)
      } finally {
        this.loading = false
      }
    },

    addToCart(product) {
      const existing = this.cart.find(item => item.id === product.id)
      if (existing) {
        existing.quantity++
      } else {
        this.cart.push({ ...product, quantity: 1 })
      }
    },

    removeFromCart(index) {
      this.cart.splice(index, 1)
    },

    clearCart() {
      this.cart = []
    },

    async checkout() {
        if (this.cart.length === 0) return;
            this.loading = true;

        try {
            // Send the raw cart items; n8n will handle the rest
            const payload = this.cart.map(item => ({
            product_id: item.id,
            quantity: item.quantity,
            price_at_sale: item.price
        }));

        await axios.post(recordSalesWebhook, payload);
            
        this.clearCart();

        // --- TOAST TRIGGER START ---
        this.showSuccessToast = true;
        // Automatically hide it after 3 seconds
        setTimeout(() => {
          this.showSuccessToast = false;
        }, 3000);
        // --- TOAST TRIGGER END ---
        console.log("Sale Recorded!"); 
    
        } catch (error) {
            console.error("Checkout failed:", error);
        } finally {
        this.loading = false;
        }
    },
    async fetchDailySales() {
        this.expandedTransactions = [];
        try {
            const response = await axios.get(dailySalesWebhook);
            this.todaySales = response.data;
            this.showSalesModal = true;
        } catch (error) {
            console.error("Could not load daily sales", error);
        }
    },
    toggleTransaction(id) {
        if (this.expandedTransactions.includes(id)) {
            this.expandedTransactions = this.expandedTransactions.filter(itemId => itemId !== id);
        } else {
        // If it's not there, add it (expand)
            this.expandedTransactions.push(id);
        }
    },
  },
  persist: true // This magical line saves your cart to LocalStorage automatically!
})