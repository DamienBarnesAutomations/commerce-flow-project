<script setup lang="ts">
import { RouterLink, RouterView } from 'vue-router'
</script>

<template>
  <div class="admin-container">
    <aside class="sidebar">
      <div class="sidebar-header">
        <h2>🎂 Cake Admin</h2>
      </div>
      
      <nav class="sidebar-nav">
        <RouterLink to="/upcoming" class="nav-item">
          <span class="icon">📅</span> Upcoming Orders
        </RouterLink>
        <RouterLink to="/review" class="nav-item">
          <span class="icon">🔍</span> Review Orders
        </RouterLink>
        <RouterLink to="/history" class="nav-item">
          <span class="icon">📜</span> Historic Orders
        </RouterLink>
      </nav>
    </aside>

    <main class="main-content">
      <header class="top-bar">
        <h1>{{ $route.name }}</h1>
      </header>
      
      <div class="content-wrapper">
        <RouterView />
      </div>
    </main>
  </div>
</template>

<style>
/* Global resets for the admin layout */

/* 1. Complete Reset */
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

body, html, #app {
  margin: 0;
  padding: 0;
  width: 100%;
  height: 100%;
  overflow: hidden; /* Prevents double scrollbars */
}

/* 2. Your Admin Layout */
.admin-container {
  display: flex;
  height: 100vh;
  width: 100vw;
  background-color: #f4f7f6;
}

body, html {
  margin: 0;
  padding: 0;
  height: 100%;
  font-family: 'Inter', system-ui, sans-serif;
}

.admin-container {
  display: flex;
  height: 100vh;
  width: 100vw;
  background-color: #f4f7f6;
}

/* Sidebar Styling */
.sidebar {
  width: 260px;
  background-color: #1a1a1a;
  color: white;
  display: flex;
  flex-direction: column;
}

.sidebar-header {
  padding: 2rem;
  text-align: center;
  border-bottom: 1px solid #333;
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
  background-color: #42b883; /* Vue Green */
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
}

.top-bar {
  background: white;
  padding: 1rem 2rem;
  box-shadow: 0 2px 4px rgba(0,0,0,0.05);
}

.content-wrapper {
  padding: 2rem;
}
</style>