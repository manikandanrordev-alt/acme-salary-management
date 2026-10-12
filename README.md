# ACME Enterprise Salary Management & Compensation Intelligence System

A comprehensive, enterprise-grade **Salary Management, Indian Statutory Payroll & Senior HR Executive Suite** designed for ACME Corporation, an organization managing 10,000 employees.

Engineered with senior full-stack architecture, rigorous transactional data integrity, statutory compliance under Indian labor and tax laws, automated email payslip dispatch, AI retention intelligence, and an ultra-premium Obsidian Executive tier interface.

---

## 1. Architectural Stack

- **Backend**: Ruby on Rails 8 API mode (Ruby 4.0.6+)
- **Database**: MySQL 8.0 with foreign keys, composite indexes, and strict financial decimal precision (`DECIMAL(12, 2)`)
- **Authentication**: Devise with secure cookie-based session management, CSRF validation, and RBAC (HR Director, System Admin, Auditor)
- **Frontend**: React (Vite) with Material UI (MUI), Bootstrap 5.3 utilities, and modern glassmorphism design system
- **Email Delivery**: Action Mailer with responsive corporate HTML payslip templates
- **Security & Quality**: Brakeman (Zero warnings), RuboCop (Zero offenses), RSpec (135 examples, 100% pass), Vitest (9 tests, 100% pass)
- **CI/CD & Deployment**: GitHub Actions, Docker Compose multi-container stack, Render / Vercel configurations

---

## 2. Senior HR Executive & Statutory Capabilities

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                        SENIOR HR EXECUTIVE & TOTAL REWARDS SUITE                       │
├──────────────────────┬──────────────────────┬───────────────────┬──────────────────────┤
│ 1. Form 16 Tax       │ 2. Gratuity & F&F    │ 3. Executive CTC  │ 4. Bell-Curve Merit  │
│    Regime Optimizer  │    Settlement Desk   │    Architecture   │    Cycle Manager     │
│ (New vs Old Slabs)   │ (Payment of Gratuity)│ (Comp A + B + C)  │ (Normal Dist. Bands) │
└──────────────────────┴──────────────────────┴───────────────────┴──────────────────────┘
```

1. **Form 16 & Dual Tax Regime Optimizer (`/hr-suite`)**:
   - Compares **New Tax Regime (Section 115BAC)** vs **Old Tax Regime** in real-time.
   - Interactive sliders for Section 80C (up to ₹1.5L), Section 80D Mediclaim (up to ₹75k), HRA Exemption (Sec 10(13A)), Home Loan Interest (Sec 24b up to ₹2L), and NPS (Sec 80CCD(1B)).
   - Live recommendation highlighting exact annual and monthly take-home savings in ₹ INR.
2. **Statutory Gratuity Provision Engine (Payment of Gratuity Act, 1972)**:
   - Statutory formula: `(15 * Last Drawn Basic * Completed Years) / 26`.
   - Automated 5-year vesting qualification check and ₹20 Lakhs tax-free cap.
   - Monthly employer liability reserve accrual provision (4.81% of basic).
3. **Earned Leave Encashment & Full and Final (F&F) Settlement Suite**:
   - Leave cashout formula: `(Monthly Basic / 30) * Earned Leave Days`, tax-exempt up to ₹25 Lakhs per CBDT notification.
   - Notice period shortfall recovery and asset deductions reconciliation.
   - Certified F&F Settlement Statement with one-click print and export.
4. **Executive CTC Breakdown Structure (Component A + B + C)**:
   - **Component A**: Monthly Gross (Basic 50%, HRA 40%, LTA, Conveyance, Special Allowance).
   - **Component B**: Employer Retirals (12% EPF, EPS, Gratuity Accrual 4.81%, Insurance).
   - **Component C**: Payment of Bonus Act, 1965 annual festive/Diwali bonus (8.33% to 20%).
   - **Net Take-Home Pay**: Exact in-hand pay deposited after employee PF (12%), Professional Tax (₹200), and TDS.
5. **Annual Merit Cycle & Bell-Curve Appraisal Engine**:
   - 5-Tier Normal Distribution (Band 5 Outstanding 10%, Band 4 Exceeds 25%, Band 3 Meets 50%, Band 2 Needs Improvement 12%, Band 1 PIP 3%).
   - Merit pool budget tracking against total enterprise wage bill.
6. **Statutory Compliance & Regulatory Audit Radar**:
   - Automated audit registry verifying EPFO ECR, ESIC Monthly, Professional Tax Form III, TDS Form 24Q, and Gratuity Group Trust filings.
7. **Automated Monthly Payslips & Email Dispatch (`/payslips`)**:
   - 1-Click batch payroll run for 10,000 employees.
   - 1-Click batch email dispatch with delivery status tracking.
   - Authentic Indian corporate payslip modal with CIN, GSTIN, PAN, TAN, UAN, and verbal verbal numbers (*"... Rupees Only"*).
8. **AI Compensation & Retention Intelligence (`/ai-advisor`)**:
   - Real-time payroll health score, flight-risk radar based on Indian market percentiles, and performance merit raise simulator.

---

## 3. Repository Structure

```
acme-salary-management/
├── backend/
│   ├── app/
│   │   ├── controllers/api/v1/   # HR Suite, Payslips, AI Advisor, Employees, Analytics
│   │   ├── models/               # Employee, SalaryRecord, SalaryAuditLog, Payslip, User
│   │   ├── services/payroll/     # GratuityCalculator, TaxRegimeComparator, CtcBreakdown,
│   │   │                         # IndiaTaxCalculator, DiwaliBonusService, PayslipGenerator
│   │   └── mailers/              # PayslipMailer (HTML & Text corporate templates)
│   ├── spec/                     # Comprehensive RSpec test suite (135 specs)
│   └── config/routes.rb          # RESTful and executive API endpoints
├── frontend/
│   ├── src/
│   │   ├── components/           # Navbar, PayslipModal, ProtectedRoute
│   │   ├── pages/                # HrSuitePage, PayslipsPage, AiAdvisorPage, AnalyticsPage,
│   │   │                         # EmployeeDirectoryPage, EmployeeDetailPage, LoginPage
│   │   ├── utils/currency.js     # Indian Rupee (₹), Lakhs/Crores, Number-to-Words
│   │   └── App.test.jsx          # Vitest suite (9 end-to-end routing/auth tests)
│   └── dist/                     # Optimized production bundle
├── docs/                         # Specifications & Architecture Guides
└── README.md                     # Project entry point & developer guide
```

---

## 4. Verification & Quality Gates

All security, style, and test suites are 100% passing:

### Backend RSpec Test Suite (135 Specs, 0 Failures)
```bash
cd backend
bundle exec rspec
# Finished in 16.62 seconds
# 135 examples, 0 failures
```

### RuboCop Code Style (0 Offenses)
```bash
cd backend
bundle exec rubocop
# 83 files inspected, no offenses detected
```

### Brakeman Security Vulnerability Audit (0 Warnings)
```bash
cd backend
bundle exec brakeman --no-pager
# 0 Security Warnings, 0 Errors
```

### Frontend Vitest Suite (9 Tests, 0 Failures)
```bash
cd frontend
npm test -- --run
# Test Files  1 passed (1)
# Tests       9 passed (9)
```

### Frontend Production Build
```bash
cd frontend
npm run build
# Built cleanly with Vite
```

---

## 5. Verified Local Setup & Commands

### Prerequisites
- **Ruby**: 4.0.6+ / 3.3+
- **Rails**: 8.1.4+
- **Node.js**: v20+
- **npm**: 10+
- **MySQL**: 8.0+ running on port 3306

### Starting Rails API (Port 3000)
```bash
cd backend
bundle install
bin/rails db:create db:migrate db:seed
bin/rails server -b 0.0.0.0 -p 3000
```

### Starting React Frontend (Port 5173)
```bash
cd frontend
npm install
npm run dev -- --host 0.0.0.0 --port 5173
```

### Demo Login Credentials
- **HR Director**: `hr_director@acme.com` / `Password123!`
- **System Admin**: `admin@acme.com` / `Password123!`
- **Auditor**: `auditor@acme.com` / `Password123!`
