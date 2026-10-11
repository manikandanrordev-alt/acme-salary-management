import { render, screen, waitFor, fireEvent } from '@testing-library/react'
import { describe, it, expect, vi, beforeEach } from 'vitest'
import App from './App'
import apiClient from './api/client'

vi.mock('./api/client')

describe('App Routing & Authentication Flow', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('redirects unauthenticated user to /login and displays login form', async () => {
    // /api/v1/auth/me returns 401 unauthenticated
    apiClient.get.mockRejectedValueOnce({ response: { status: 401 } })

    render(<App />)

    await waitFor(() => {
      expect(screen.getByRole('heading', { name: /Salary & Compensation Intelligence/i })).toBeInTheDocument()
    })
    expect(screen.getByLabelText(/Email Address/i)).toBeInTheDocument()
    expect(screen.getByLabelText(/Password/i)).toBeInTheDocument()
    expect(screen.getByRole('button', { name: /Sign In/i })).toBeInTheDocument()
  })

  it('fills demo credentials when demo button clicked and authenticates', async () => {
    apiClient.get.mockRejectedValueOnce({ response: { status: 401 } })

    render(<App />)

    await waitFor(() => {
      expect(screen.getByText('hr_director@acme.com')).toBeInTheDocument()
    })

    // Click demo HR manager button
    fireEvent.click(screen.getByText('hr_director@acme.com'))

    expect(screen.getByLabelText(/Email Address/i)).toHaveValue('hr_director@acme.com')
    expect(screen.getByLabelText(/Password/i)).toHaveValue('SecurePassword123!')

    // Mock successful login and subsequent employee list
    apiClient.post.mockResolvedValueOnce({
      data: {
        data: {
          user: { id: 1, email: 'hr_director@acme.com', full_name: 'HR Director', role: 'hr_manager' },
        },
      },
    })
    apiClient.get.mockImplementation((url) => {
      if (url === '/api/v1/departments') {
        return Promise.resolve({ data: { data: [{ id: 1, name: 'Engineering', code: 'ENG' }] } })
      }
      if (url === '/api/v1/employees') {
        return Promise.resolve({
          data: {
            data: [
              {
                id: 101,
                employee_code: 'ACME-00101',
                full_name: 'Alice Smith',
                job_title: 'Staff Engineer',
                department: { name: 'Engineering', code: 'ENG' },
                country_code: 'US',
                employment_status: 'active',
                hire_date: '2022-01-15',
                current_salary: {
                  amount: '120000.0',
                  currency: 'USD',
                  pay_frequency: 'annual',
                  effective_from: '2022-01-15',
                },
              },
            ],
            meta: { total_count: 1, page: 1, per_page: 25, total_pages: 1 },
          },
        })
      }
      return Promise.reject(new Error('not found'))
    })

    fireEvent.click(screen.getByRole('button', { name: /Sign In/i }))

    await waitFor(() => {
      expect(screen.getByText('ACME-00101')).toBeInTheDocument()
      expect(screen.getByText('Alice Smith')).toBeInTheDocument()
      expect(screen.getByText('Staff Engineer')).toBeInTheDocument()
      expect(screen.getByText('$120,000')).toBeInTheDocument()
    })

    // Check navbar displays role chip
    expect(screen.getByText('HR Manager')).toBeInTheDocument()
  })

  it('displays error alert when login credentials are invalid', async () => {
    apiClient.get.mockRejectedValueOnce({ response: { status: 401 } })

    render(<App />)

    await waitFor(() => {
      expect(screen.getByRole('button', { name: /Sign In/i })).toBeInTheDocument()
    })

    fireEvent.change(screen.getByLabelText(/Email Address/i), { target: { value: 'wrong@acme.com' } })
    fireEvent.change(screen.getByLabelText(/Password/i), { target: { value: 'Wrong123' } })

    apiClient.post.mockRejectedValueOnce({
      response: {
        data: {
          error: {
            message: 'Invalid email or password',
          },
        },
      },
    })

    fireEvent.click(screen.getByRole('button', { name: /Sign In/i }))

    await waitFor(() => {
      expect(screen.getByText('Invalid email or password')).toBeInTheDocument()
    })
  })
})
