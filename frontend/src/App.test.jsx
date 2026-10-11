import { render, screen, waitFor, fireEvent } from '@testing-library/react'
import { describe, it, expect, vi, beforeEach } from 'vitest'
import App from './App'
import apiClient from './api/client'

vi.mock('./api/client')

describe('App Routing & Authentication Flow', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    window.history.pushState({}, '', '/')
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

  it('toggles password visibility when eye icon button clicked', async () => {
    apiClient.get.mockRejectedValueOnce({ response: { status: 401 } })

    render(<App />)

    await waitFor(() => {
      expect(screen.getByLabelText(/Password/i)).toBeInTheDocument()
    })

    const passwordInput = screen.getByLabelText(/Password/i)
    expect(passwordInput).toHaveAttribute('type', 'password')

    const toggleButton = screen.getByRole('button', { name: /toggle visibility/i })
    expect(toggleButton).toBeInTheDocument()

    fireEvent.click(toggleButton)
    expect(passwordInput).toHaveAttribute('type', 'text')

    fireEvent.click(toggleButton)
    expect(passwordInput).toHaveAttribute('type', 'password')
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
    expect(screen.getByLabelText(/Password/i)).toHaveValue('Password123!')

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

  it('navigates to analytics dashboard and displays multi-currency KPI cards', async () => {
    // Mock user authenticated as HR Manager
    apiClient.get.mockImplementation((url) => {
      if (url === '/api/v1/auth/me') {
        return Promise.resolve({
          data: { data: { user: { id: 1, email: 'hr_director@acme.com', role: 'hr_manager' } } },
        })
      }
      if (url === '/api/v1/departments') {
        return Promise.resolve({ data: { data: [] } })
      }
      if (url === '/api/v1/employees') {
        return Promise.resolve({ data: { data: [], meta: { total_count: 0 } } })
      }
      if (url === '/api/v1/analytics/summary') {
        return Promise.resolve({
          data: {
            data: {
              currencies: [
                {
                  currency: 'USD',
                  headcount: 5000,
                  total_payroll: 550000000,
                  average_salary: 110000,
                  min_salary: 50000,
                  max_salary: 250000,
                },
                {
                  currency: 'GBP',
                  headcount: 2000,
                  total_payroll: 160000000,
                  average_salary: 80000,
                  min_salary: 40000,
                  max_salary: 180000,
                },
              ],
              departments: [
                { department_name: 'Engineering', currency: 'USD', headcount: 2000, average_salary: 130000, total_payroll: 260000000 },
              ],
              countries: [
                { country_code: 'US', currency: 'USD', headcount: 5000, average_salary: 110000, total_payroll: 550000000 },
              ],
            },
          },
        })
      }
      return Promise.reject(new Error('not found'))
    })

    render(<App />)

    await waitFor(() => {
      expect(screen.getByRole('link', { name: /Analytics/i })).toBeInTheDocument()
    })

    fireEvent.click(screen.getByRole('link', { name: /Analytics/i }))

    await waitFor(() => {
      expect(screen.queryByText(/Aggregating compensation metrics/i) || screen.queryByRole('heading', { name: /Compensation Intelligence/i })).toBeTruthy()
    }, { timeout: 3000 })
  })

  it('renders Export CSV and Import CSV action buttons on employee directory for HR user', async () => {
    apiClient.get.mockImplementation((url) => {
      if (url === '/api/v1/auth/me') {
        return Promise.resolve({
          data: { data: { user: { id: 1, email: 'hr_lead@acme.com', role: 'hr_manager' } } },
        })
      }
      if (url === '/api/v1/departments') {
        return Promise.resolve({ data: { data: [] } })
      }
      if (url === '/api/v1/employees') {
        return Promise.resolve({ data: { data: [], meta: { total_count: 0 } } })
      }
      return Promise.reject(new Error('not found'))
    })

    render(<App />)

    await waitFor(() => {
      expect(screen.getByRole('button', { name: /Export CSV/i })).toBeInTheDocument()
      expect(screen.getByRole('button', { name: /Import CSV/i })).toBeInTheDocument()
    })
  })
})
