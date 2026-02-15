import axios from 'axios';

// VITE_API_BASE_URL is passed from your Docker Compose environment
const api = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL + '/cakeOrder',
  headers: {
    'Content-Type': 'application/json',
  },
});

export default api;