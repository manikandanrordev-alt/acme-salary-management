# ACME Salary Management Backend (Rails 8 API)

The backend service for ACME Salary Management, built on Ruby on Rails 8 API mode and MySQL 8.0.

---

## 1. Core Modules & Architecture

### Payroll & Statutory Engines (`app/services/payroll/`)
1. **`Payroll::GratuityCalculator`**:
   - Implements the Payment of Gratuity Act, 1972: `(15 * Last Drawn Basic * Completed Years) / 26`.
   - Vests at 5 years of continuous service; capped at statutory ₹20,00,000.
   - Calculates monthly employer liability accrual provision (4.81% of basic).
   - Computes leave encashment under CBDT notification: `(Basic / 30) * Leave Days`.
   - Full & Final (F&F) settlement reconciliation.
2. **`Payroll::TaxRegimeComparator`**:
   - Compares New Tax Regime (Section 115BAC - standard deduction ₹75,000, 87A rebate, multi-year slabs: FY 2023-24 through FY 2026-27) vs Old Tax Regime (Section 80C, 80D, HRA, 24b, 80CCD).
   - Computes monthly TDS difference and breakeven deduction thresholds.
3. **`Payroll::CtcBreakdownService`**:
   - Decomposes annual CTC into Component A (Monthly Gross), Component B (Employer Retirals: 12% PF, EPS, Gratuity Accrual, Insurance), and Component C (Diwali / Performance Bonus).
   - Produces exact net monthly in-hand take-home pay.
4. **`Payroll::IndiaTaxCalculator`**:
   - Multi-year TDS tax calculator under Indian New Tax Regime (FY 2023-24 through FY 2026-27) with official Income Tax Dept AY 2026-27 / AY 2027-28 slabs (₹4L - ₹24L) and Section 87A rebate/marginal relief.
5. **`Payroll::DiwaliBonusService`**:
   - Payment of Bonus Act, 1965 festive bonus calculator (8.33% to 20%).
6. **`Payroll::PayslipGenerator`**:
   - Generates deterministic payslips with INR verbal formatting and loss-of-pay deductions.

### RESTful & Executive API Endpoints (`app/controllers/api/v1/`)
- `GET /api/v1/hr_suite/overview`: Enterprise headcount, wage bill, gratuity reserves, and compliance filings.
- `POST /api/v1/hr_suite/compare_tax`: New vs Old regime comparison with Chapter VI-A deductions.
- `POST /api/v1/hr_suite/calculate_fnf`: Full and Final settlement with statutory gratuity.
- `POST /api/v1/hr_suite/calculate_ctc`: Component A, B, C and in-hand breakdown.
- `GET /api/v1/hr_suite/appraisal_distribution`: 5-tier bell-curve distribution and merit pool budget.
- `POST /api/v1/payslips/generate_batch`: Generates batch monthly payslips.
- `POST /api/v1/payslips/send_batch_emails`: Dispatches branded HTML payslip emails.
- `GET /api/v1/employees`: Searchable, paginated employee directory (10,000 records).
- `POST /api/v1/employees/:id/salary_revisions`: Effective-dated salary revision with immutable audit trail.
- `GET /api/v1/ai/summary`, `GET /api/v1/ai/attrition_risk`, `GET /api/v1/ai/anomalies`: AI intelligence.

---

## 2. Quality & Security Verification

All quality gates pass with zero failures:

```bash
# 1. RSpec Test Suite (135 examples, 0 failures)
bundle exec rspec

# 2. RuboCop Static Analysis (0 offenses)
bundle exec rubocop

# 3. Brakeman Security Scanner (0 warnings, 0 errors)
bundle exec brakeman --no-pager
```

---

## 3. Local Development Setup

```bash
# Install Ruby gems
bundle install

# Setup database and seed 10,000 synthetic employees
bin/rails db:create db:migrate db:seed

# Start Puma API server on port 3000
bin/rails server -b 0.0.0.0 -p 3000
```
