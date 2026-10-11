import axios from 'axios'

const API_BASE_URL = import.meta.env.VITE_API_URL || ''

const apiClient = axios.create({
  baseURL: API_BASE_URL,
  withCredentials: true,
  headers: {
    'Content-Type': 'application/json',
    Accept: 'application/json',
  },
})

// Attach CSRF token if present in document cookies or meta tag
apiClient.interceptors.request.use((config) => {
  const match = document.cookie.match(/CSRF-TOKEN=([^;]+)/)
  if (match) {
    config.headers['X-CSRF-Token'] = decodeURIComponent(match[1])
  }
  return config
})

export default apiClient
