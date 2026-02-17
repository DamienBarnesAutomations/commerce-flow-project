import { createRouter, createWebHistory } from 'vue-router'

const router = createRouter({
  // Ensure this matches your Vite 'base' and Traefik PathPrefix
  history: createWebHistory('/custom-cake-manager/'),
  routes: [
    {
      path: '/upcoming',
      name: 'Upcoming Orders',
      component: () => import('../views/UpcomingView.vue')
    },
    {
      path: '/review',
      name: 'Review Orders',
      component: () => import('../views/ReviewView.vue')
    },
    {
      path: '/history',
      name: 'Historic Orders',
      component: () => import('../views/HistoryView.vue')
    },
    {
      path: '/chat-logs',
      name: 'Chat Logs',
      component: () => import('../views/ChatView.vue')
    },
    // Redirect / to /review by default
    { path: '/', redirect: '/upcoming' }
  ]
})

export default router