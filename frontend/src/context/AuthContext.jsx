import { createContext, useContext, useState, useEffect, useCallback } from 'react'
import apiClient from '../api/client'

const AuthContext = createContext(null)

export function AuthProvider({ children }) {
  const [user, setUser] = useState(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)

  const checkAuth = useCallback(async () => {
    try {
      setLoading(true)
      const res = await apiClient.get('/api/v1/auth/me')
      setUser(res.data.data.user)
      setError(null)
    } catch {
      setUser(null)
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    checkAuth()
  }, [checkAuth])

  const login = async (email, password) => {
    setError(null)
    try {
      const res = await apiClient.post('/api/v1/auth/login', { email, password })
      setUser(res.data.data.user)
      return { success: true, user: res.data.data.user }
    } catch (err) {
      const msg = err.response?.data?.error?.message || 'Invalid email or password'
      setError(msg)
      return { success: false, error: msg }
    }
  }

  const logout = async () => {
    try {
      await apiClient.delete('/api/v1/auth/logout')
    } catch {
      // Ignore logout errors
    } finally {
      setUser(null)
      setError(null)
    }
  }

  const value = {
    user,
    loading,
    error,
    isAuthenticated: Boolean(user),
    isHrManager: user?.role === 'hr_manager' || user?.role === 'admin',
    isAdmin: user?.role === 'admin',
    login,
    logout,
    checkAuth,
  }

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}

export function useAuth() {
  const context = useContext(AuthContext)
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider')
  }
  return context
}
