import axios from 'axios'

const API_BASE_URL = import.meta.env.VITE_API_URL || ''

let inMemoryCsrfToken = null
let pendingCsrfPromise = null

export const setCsrfToken = (token) => {
  if (!token) return
  inMemoryCsrfToken = token
  try {
    sessionStorage.setItem('acme_csrf_token', token)
  } catch {
    // Ignore storage errors in restricted contexts
  }
}

export const clearCsrfToken = () => {
  inMemoryCsrfToken = null
  try {
    sessionStorage.removeItem('acme_csrf_token')
  } catch {
    // Ignore storage errors
  }
}

export const getStoredCsrfToken = () => {
  if (inMemoryCsrfToken) return inMemoryCsrfToken
  try {
    const sessionToken = sessionStorage.getItem('acme_csrf_token')
    if (sessionToken) {
      inMemoryCsrfToken = sessionToken
      return sessionToken
    }
  } catch {
    // Ignore storage errors
  }
  const match =
    typeof document !== 'undefined' && document.cookie
      ? document.cookie.match(/CSRF-TOKEN=([^;]+)/)
      : null
  if (match) {
    inMemoryCsrfToken = decodeURIComponent(match[1])
    return inMemoryCsrfToken
  }
  return null
}

export const fetchCsrfToken = async (forceRefresh = false) => {
  if (!forceRefresh) {
    const stored = getStoredCsrfToken()
    if (stored) return stored
  }
  if (pendingCsrfPromise) {
    return pendingCsrfPromise
  }
  pendingCsrfPromise = axios
    .get(`${API_BASE_URL}/api/v1/auth/csrf`, {
      withCredentials: true,
      headers: { Accept: 'application/json' },
    })
    .then((res) => {
      const token = res.data?.csrf_token
      if (token) {
        setCsrfToken(token)
      }
      return token
    })
    .catch(() => null)
    .finally(() => {
      pendingCsrfPromise = null
    })
  return pendingCsrfPromise
}

const apiClient = axios.create({
  baseURL: API_BASE_URL,
  withCredentials: true,
  headers: {
    'Content-Type': 'application/json',
    Accept: 'application/json',
  },
})

// Attach CSRF token before sending non-safe mutation requests
apiClient.interceptors.request.use(async (config) => {
  const method = (config.method || 'get').toLowerCase()
  const isSafeMethod = ['get', 'head', 'options'].includes(method)
  const isCsrfEndpoint = config.url?.includes('/api/v1/auth/csrf')

  if (!isSafeMethod && !isCsrfEndpoint && !config.headers['X-CSRF-Token']) {
    let token = getStoredCsrfToken()
    if (!token) {
      token = await fetchCsrfToken()
    }
    if (token) {
      config.headers['X-CSRF-Token'] = token
    }
  }
  return config
})

// Intercept responses to store refreshed tokens and auto-retry on INVALID_CSRF
apiClient.interceptors.response.use(
  (response) => {
    const headerToken = response.headers?.['x-csrf-token']
    if (headerToken) {
      setCsrfToken(headerToken)
    }
    const bodyToken = response.data?.data?.csrf_token
    if (bodyToken) {
      setCsrfToken(bodyToken)
    }
    return response
  },
  async (error) => {
    const originalRequest = error.config
    const errorCode = error.response?.data?.error?.code

    if (
      error.response?.status === 422 &&
      errorCode === 'INVALID_CSRF' &&
      originalRequest &&
      !originalRequest._retry
    ) {
      originalRequest._retry = true
      clearCsrfToken()
      const freshToken = await fetchCsrfToken(true)
      if (freshToken) {
        originalRequest.headers = originalRequest.headers || {}
        originalRequest.headers['X-CSRF-Token'] = freshToken
        return apiClient(originalRequest)
      }
    }

    return Promise.reject(error)
  }
)

export default apiClient
