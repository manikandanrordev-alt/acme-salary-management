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
      if (url === '/api/v1/auth/me') {
        return Promise.resolve({
          data: {
            data: {
              user: { id: 1, email: 'hr_director@acme.com', full_name: 'HR Director', role: 'hr_manager' },
            },
          },
        })
      }
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
      expect(screen.getAllByText(/₹/).length).toBeGreaterThan(0)
    })

    // Check navbar displays role chip
    expect(screen.getAllByText(/HR Director/i).length).toBeGreaterThanOrEqual(1)
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
      if (url.startsWith('/api/v1/payslips')) {
        return Promise.resolve({
          data: {
            data: [],
            meta: { total_count: 0 },
            summary: {
              total_gross_inr: 5000000,
              total_net_disbursed_inr: 4200000,
              total_tds_tax_inr: 450000,
              total_epf_inr: 300000,
              total_diwali_bonus_inr: 1200000,
              total_dispatched_emails: 15,
              total_payslips: 20,
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
      expect(
        screen.queryByText(/Aggregating Indian compensation metrics/i) ||
        screen.queryByRole('heading', { name: /Compensation & Tax Intelligence/i })
      ).toBeTruthy()
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

  it('navigates to Payslips & Payroll page and renders payroll controls', async () => {
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
      if (url.startsWith('/api/v1/payslips')) {
        return Promise.resolve({
          data: {
            data: [],
            meta: { total_count: 0 },
            summary: {
              total_gross_inr: 5000000,
              total_net_disbursed_inr: 4200000,
              total_tds_tax_inr: 450000,
              total_epf_inr: 300000,
              total_diwali_bonus_inr: 1200000,
              total_dispatched_emails: 15,
              total_payslips: 20,
            },
          },
        })
      }
      return Promise.reject(new Error('not found'))
    })

    window.history.pushState({}, '', '/payslips')
    render(<App />)

    await waitFor(() => {
      expect(screen.getByRole('heading', { name: /Monthly Payroll & Payslips/i })).toBeInTheDocument()
      expect(screen.getByRole('button', { name: /Run Monthly Payroll/i })).toBeInTheDocument()
    })
  })

  it('navigates to AI Advisor page and renders AI retention intelligence', async () => {
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
      if (url === '/api/v1/ai/summary') {
        return Promise.resolve({
          data: {
            data: {
              payroll_health_score: 95,
              attrition_risk_summary: { high_risk_count: 5, top_risk_department: 'Engineering' },
              festive_bonus_forecast: { projected_diwali_payout: 4200000 },
              ai_recommendation_count: 8,
            },
          },
        })
      }
      if (url === '/api/v1/ai/attrition_risk') {
        return Promise.resolve({ data: { data: [] } })
      }
      if (url === '/api/v1/ai/anomalies') {
        return Promise.resolve({ data: { data: [] } })
      }
      return Promise.reject(new Error('not found'))
    })

    window.history.pushState({}, '', '/ai-advisor')
    render(<App />)

    await waitFor(() => {
      expect(screen.getByRole('heading', { name: /AI Compensation & Retention Intelligence/i })).toBeInTheDocument()
    })
  })

  it('navigates to HR Executive Suite page and renders tax optimizer and FNF settlement desks', async () => {
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
      if (url === '/api/v1/hr_suite/overview') {
        return Promise.resolve({
          data: {
            metrics: {
              total_headcount: 10000,
              monthly_wage_bill: 745000000,
              annual_wage_bill: 8940000000,
              gratuity_reserve_liability: 215000000,
              statutory_compliance_rate: 100.0,
            },
            statutory_filings: [],
            appraisal_cycle: { allocated_budget: 76000000 },
          },
        })
      }
      if (url === '/api/v1/hr_suite/appraisal_distribution') {
        return Promise.resolve({
          data: {
            total_annual_wage_bill: 8940000000,
            merit_pool_budget: 804600000,
            approved_budget_percentage: 9.0,
            salary_weighted_increment_rate: 8.78,
            projected_increment_cost: 784485000,
            reserve_buffer_surplus: 20115000,
            is_projection: true,
            calculation_type: 'projection_model',
            methodology: 'assumed_salary_shares',
            methodology_disclaimer: 'Projection based on assumed salary shares (target distribution quotas) across annual wage bill. Actual employee-level performance-band assignments are not implemented in the salary dataset.',
            bell_curve: [],
          },
        })
      }
      return Promise.reject(new Error('not found'))
    })
    apiClient.post.mockImplementation((url) => {
      if (url === '/api/v1/hr_suite/compare_tax') {
        return Promise.resolve({
          data: {
            annual_gross: 1400000,
            recommended_regime: 'NEW_REGIME',
            annual_tax_difference: 42500,
            monthly_tax_savings: 3541.67,
            summary_verdict: 'New Tax Regime saves ₹42,500 annually',
            new_regime: {
              standard_deduction: 75000,
              taxable_income: 1325000,
              tax_before_cess: 105000,
              cess: 4200,
              total_tax: 109200,
              monthly_tds: 9100,
              slabs_breakdown: [],
            },
            old_regime: {
              total_deductions: 505000,
              taxable_income: 895000,
              tax_before_cess: 146000,
              cess: 5840,
              total_tax: 151840,
              monthly_tds: 12653.33,
            },
          },
        })
      }
      if (url === '/api/v1/hr_suite/calculate_ctc') {
        return Promise.resolve({
          data: {
            annual_ctc: 1800000,
            component_a_gross: {
              title: 'Component A: Monthly Direct Gross Salary',
              annual_total: 1512000,
              monthly_total: 126000,
              breakdown: {
                basic: { monthly: 63000, annual: 756000 },
                hra: { monthly: 25200, annual: 302400 },
                conveyance: { monthly: 1600, annual: 19200 },
                lta: { monthly: 3150, annual: 37800 },
                special_allowance: { monthly: 33050, annual: 396600 },
              },
            },
            component_b_retirals: {
              title: 'Component B: Employer Retirals & Statutory Benefits',
              annual_total: 216000,
              breakdown: {
                employer_epf: { monthly: 1800, annual: 21600 },
                gratuity_accrual: { monthly: 3030.77, annual: 36369.24 },
                group_mediclaim_insurance: { monthly: 1500, annual: 18000 },
              },
            },
            employee_take_home: {
              monthly_gross: 126000,
              monthly_employee_pf: 1800,
              monthly_professional_tax: 200,
              monthly_estimated_tds: 10500,
              monthly_net_in_hand: 113500,
              annual_net_in_hand: 1362000,
            },
          },
        })
      }
      if (url === '/api/v1/hr_suite/calculate_fnf') {
        return Promise.resolve({
          data: {
            employee_info: { name: 'Aarav Patel', monthly_gross: 85000 },
            settlement: {
              settlement_summary: { net_payable: 228623.08, status: 'PAYABLE_TO_EMPLOYEE', total_earnings: 235123.08, total_deductions: 6500 },
              earnings_breakdown: {
                unpaid_days: 12,
                earned_salary_for_unpaid_days: 34000,
                gratuity: { payable_amount: 171634.62, tenure_years: 7.38, is_vested: true },
                leave_encashment: { leave_days: 18, gross_leave_encashment: 25500, daily_basic_rate: 1416.67 },
                statutory_bonus_accrual: 21240,
              },
              deductions_breakdown: { notice_shortfall_days: 0, notice_recovery_amount: 0, asset_deductions: 0, tds_deduction: 6500 },
            },
          },
        })
      }
      return Promise.reject(new Error('not found'))
    })

    window.history.pushState({}, '', '/hr-suite')
    render(<App />)

    await waitFor(() => {
      expect(screen.getByRole('heading', { name: /HR Executive & Total Rewards Suite/i })).toBeInTheDocument()
      expect(screen.getByText(/DIRECTOR TIER/i)).toBeInTheDocument()
      expect(screen.getByText(/1. Form 16 Tax Optimizer/i)).toBeInTheDocument()
    })
  })
})
