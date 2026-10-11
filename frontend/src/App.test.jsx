import { render, screen, waitFor } from '@testing-library/react'
import { describe, it, expect, vi, beforeEach } from 'vitest'
import App from './App'
import apiClient from './api/client'

vi.mock('./api/client')

describe('App Component', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('renders title and loading state initially', () => {
    apiClient.get.mockImplementation(() => new Promise(() => {}))
    render(<App />)

    expect(screen.getByText(/ACME ENTERPRISE/i)).toBeInTheDocument()
    expect(screen.getByRole('heading', { name: /Salary Management System/i })).toBeInTheDocument()
    expect(screen.getByText(/Connecting to Rails API.../i)).toBeInTheDocument()
  })

  it('displays connected status when health check succeeds', async () => {
    apiClient.get.mockResolvedValueOnce({
      data: {
        status: 'ok',
        service: 'acme-salary-management-api',
        db: 'connected',
        timestamp: new Date().toISOString(),
      },
    })

    render(<App />)

    await waitFor(() => {
      expect(screen.getByText(/Backend connected successfully:/i)).toBeInTheDocument()
    })
    expect(screen.getByText('acme-salary-management-api')).toBeInTheDocument()
    expect(screen.getByText('Connected')).toBeInTheDocument()
  })

  it('displays error message when health check fails', async () => {
    apiClient.get.mockRejectedValueOnce(new Error('Network Error'))

    render(<App />)

    await waitFor(() => {
      expect(screen.getByText(/Backend Communication Error: Network Error/i)).toBeInTheDocument()
    })
  })
})
