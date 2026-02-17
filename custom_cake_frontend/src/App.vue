<script setup lang="ts">
import { ref } from 'vue'
import { RouterLink, RouterView, useRoute } from 'vue-router'

const route = useRoute()
const isMobileMenuOpen = ref(false)

const toggleMenu = () => {
  isMobileMenuOpen.value = !isMobileMenuOpen.value
}

const closeMenu = () => {
  isMobileMenuOpen.value = false
}
</script>

<template>
  <div class="admin-container">
    <div 
      v-if="isMobileMenuOpen" 
      class="sidebar-overlay" 
      @click="closeMenu"
    ></div>

    <aside :class="['sidebar', { 'is-open': isMobileMenuOpen }]">
      <div class="sidebar-header">
        <h2>🎂 Cake Admin</h2>
        <button class="mobile-close-btn" @click="toggleMenu">×</button>
      </div>
      
      <nav class="sidebar-nav">
        <RouterLink to="/upcoming" class="nav-item" @click="closeMenu">
          <span class="icon">📅</span> Upcoming Orders
        </RouterLink>
        <RouterLink to="/review" class="nav-item" @click="closeMenu">
          <span class="icon">🔍</span> Review Orders
        </RouterLink>
        <RouterLink to="/history" class="nav-item" @click="closeMenu">
          <span class="icon">📜</span> Historic Orders
        </RouterLink>
        <RouterLink to="/chat-logs" class="nav-item" @click="closeMenu">
          <span class="icon">💬</span> Chat Logs
        </RouterLink>
      </nav>
    </aside>

    <main class="main-content">
      <header class="top-bar">
        <button class="hamburger-btn" @click="toggleMenu">
          ☰
        </button>
        <h1>{{ route.name }}</h1>
      </header>
      
      <div class="content-wrapper">
        <RouterView />
      </div>
    </main>
  </div>
</template>

<style>
/* 1. Complete Reset */
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

body, html, #app {
  width: 100%;
  height: 100%;
  overflow: hidden;
  font-family: 'Inter', system-ui, sans-serif;
}

/* 2. Layout Structure */
.admin-container {
  display: flex;
  height: 100vh;
  width: 100vw;
  background-color: #f4f7f6;
  position: relative;
}

/* Sidebar Styling */
.sidebar {
  width: 260px;
  background-color: #1a1a1a;
  color: white;
  display: flex;
  flex-direction: column;
  z-index: 1001;
  transition: transform 0.3s ease;
}

.sidebar-header {
  padding: 2rem;
  text-align: center;
  border-bottom: 1px solid #333;
  display: flex;
  justify-content: center;
  align-items: center;
  position: relative;
}

.mobile-close-btn {
  display: none;
  position: absolute;
  right: 1rem;
  background: none;
  border: none;
  color: white;
  font-size: 2rem;
  cursor: pointer;
}

.sidebar-nav {
  flex: 1;
  padding: 1rem 0;
}

.nav-item {
  display: flex;
  align-items: center;
  padding: 1rem 1.5rem;
  color: #ccc;
  text-decoration: none;
  transition: all 0.3s;
}

.nav-item:hover {
  background-color: #333;
  color: white;
}

.nav-item.router-link-active {
  background-color: #42b883;
  color: white;
  border-left: 4px solid #fff;
}

.icon {
  margin-right: 12px;
  font-size: 1.2rem;
}

/* Main Content Styling */
.main-content {
  flex: 1;
  display: flex;
  flex-direction: column;
  overflow-y: auto;
  min-width: 0; /* Prevents flex items from overflowing */
}

.top-bar {
  background: white;
  padding: 1rem 2rem;
  box-shadow: 0 2px 4px rgba(0,0,0,0.05);
  display: flex;
  align-items: center;
  gap: 1rem;
  position: sticky;
  top: 0;
  z-index: 100;
}

.hamburger-btn {
  display: none;
  background: none;
  border: none;
  font-size: 1.5rem;
  cursor: pointer;
  padding: 0.5rem;
}

.content-wrapper {
  padding: 2rem;
}

/* 3. Mobile Responsiveness */
@media (max-width: 768px) {
  .sidebar {
    position: fixed;
    top: 0;
    left: 0;
    bottom: 0;
    transform: translateX(-100%); /* Hide sidebar */
  }

  .sidebar.is-open {
    transform: translateX(0); /* Show sidebar */
  }

  .sidebar-overlay {
    position: fixed;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background: rgba(0,0,0,0.5);
    z-index: 1000;
  }

  .hamburger-btn, .mobile-close-btn {
    display: block;
  }

  .top-bar {
    padding: 0.8rem 1rem;
  }

  .top-bar h1 {
    font-size: 1.25rem;
  }

  .content-wrapper {
    padding: 1rem;
  }
}
</style>