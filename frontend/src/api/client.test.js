import { describe, it, expect, vi, beforeEach } from 'vitest'
import axios from 'axios'
import apiClient, {
  setCsrfToken,
  clearCsrfToken,
  getStoredCsrfToken,
  fetchCsrfToken,
} from './client'

vi.mock('axios', async () => {
  const actual = await vi.importActual('axios')
  const mockAxiosInstance = {
    interceptors: {
      request: { use: vi.fn((fn) => { mockAxiosInstance.requestInterceptor = fn }) },
      response: { use: vi.fn((success, err) => {
        mockAxiosInstance.responseSuccessInterceptor = success
        mockAxiosInstance.responseErrorInterceptor = err
      }) },
    },
    defaults: { headers: {} },
    get: vi.fn(),
    post: vi.fn(),
  }
  return {
    default: {
      ...actual.default,
      create: vi.fn(() => mockAxiosInstance),
      get: vi.fn(),
    },
  }
})

describe('apiClient CSRF token management', () => {
  beforeEach(() => {
    clearCsrfToken()
    vi.clearAllMocks()
  })

  it('stores and retrieves CSRF token in memory and sessionStorage', () => {
    expect(getStoredCsrfToken()).toBeNull()
    setCsrfToken('test-csrf-token-123')
    expect(getStoredCsrfToken()).toBe('test-csrf-token-123')
    expect(sessionStorage.getItem('acme_csrf_token')).toBe('test-csrf-token-123')

    clearCsrfToken()
    expect(getStoredCsrfToken()).toBeNull()
    expect(sessionStorage.getItem('acme_csrf_token')).toBeNull()
  })

  it('fetches CSRF token from /api/v1/auth/csrf when not cached', async () => {
    axios.get.mockResolvedValueOnce({
      data: { csrf_token: 'fetched-remote-token-abc' },
    })

    const token = await fetchCsrfToken()
    expect(token).toBe('fetched-remote-token-abc')
    expect(axios.get).toHaveBeenCalledWith(
      expect.stringContaining('/api/v1/auth/csrf'),
      expect.objectContaining({ withCredentials: true })
    )
  })

  it('deduplicates concurrent fetchCsrfToken calls', async () => {
    axios.get.mockImplementation(
      () =>
        new Promise((resolve) =>
          setTimeout(
            () => resolve({ data: { csrf_token: 'concurrent-token' } }),
            10
          )
        )
    )

    const [t1, t2] = await Promise.all([fetchCsrfToken(), fetchCsrfToken()])
    expect(t1).toBe('concurrent-token')
    expect(t2).toBe('concurrent-token')
    expect(axios.get).toHaveBeenCalledTimes(1)
  })
})
