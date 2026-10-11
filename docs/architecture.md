# Architecture Specification
## ACME Salary Management & Compensation Intelligence System

### 1. Architectural Principles & System Boundary
The ACME Salary Management System is designed as a unified monorepo containing a high-performance **Ruby on Rails API** backend and a responsive **React (Material UI)** single-page application frontend, backed by a **MySQL 8** relational database.

```
acme-salary-management/
├── backend/                  # Ruby on Rails 8 API Application
│   ├── app/
│   │   ├── controllers/      # API endpoints (HR Suite, Payslips, AI Advisor)
│   │   ├── models/           # Domain models & ActiveRecord validations
│   │   ├── services/         # Gratuity, Tax comparator, CTC, Payslips, Diwali bonus
│   │   └── mailers/          # Action Mailer with HTML/Text payslip delivery
│   ├── config/               # Routes, CORS, session, and database config
│   ├── db/                   # Migrations & 10k deterministic seeds
│   └── spec/                 # RSpec request, model, and service specs (118 specs)
├── frontend/                 # React 18+ Single Page Application
│   ├── src/
│   │   ├── api/              # Axios client with CSRF & session handling
│   │   ├── components/       # Navbar, PayslipModal, ProtectedRoute
│   │   ├── context/          # Auth and notification context providers
│   │   ├── pages/            # HrSuitePage, PayslipsPage, AiAdvisorPage, AnalyticsPage
│   │   └── utils/            # currency.js (INR format, Lakhs/Crores, Words)
│   └── dist/                 # Optimized production bundle
├── docs/                     # Architectural, data model, and PRD specifications
├── .github/
│   └── workflows/            # GitHub Actions CI for backend & frontend
├── .gitignore
└── README.md
```

---

### 2. Backend Architecture (Rails 8 API)
- **API-First Design**: Rails is configured in API mode with session middleware re-enabled (`ActionDispatch::Cookies` and `ActionDispatch::Session::CookieStore`) to support secure Devise sessions.
- **Layered Responsibilities**:
  - **Controllers**: Handle HTTP authentication, parameter sanitization, and delegating to Query/Service objects.
  - **Service Objects**:
    - `Payroll::GratuityCalculator`: Payment of Gratuity Act 1972 calculation, 5-year vesting, ₹20 Lakhs statutory cap, leave encashment, and Full & Final (F&F) settlement.
    - `Payroll::TaxRegimeComparator`: Side-by-side New vs Old Tax Regime calculation and Chapter VI-A investment deduction analysis.
    - `Payroll::CtcBreakdownService`: Component A (Gross), Component B (Employer Retirals), and Component C (Diwali bonus) architecture with net take-home pay.
    - `Payroll::IndiaTaxCalculator`: Slabs and 87A rebate tax calculation under Indian Finance Act.
    - `Payroll::DiwaliBonusService`: Payment of Bonus Act, 1965 festive bonus pool.
    - `Payroll::PayslipGenerator`: Monthly payslip generator with verbal INR amounts.
  - **Action Mailer**: `PayslipMailer` dispatches formatted corporate HTML salary slips with delivery audit tracking.

---

### 3. Senior HR Executive Suite Architecture (`/hr-suite`)
- **Desk 1: Form 16 & Dual Tax Regime Optimizer**: Compares New Regime (Sec 115BAC) vs Old Regime with Chapter VI-A deductions (80C, 80D, HRA, 24b, NPS) to provide exact take-home recommendations.
- **Desk 2: Gratuity & Full and Final (F&F) Settlement Desk**: Calculates statutory gratuity (`(15 * Basic * Tenure) / 26`), leave encashment (`(Basic / 30) * Leaves`), and notice period recovery.
- **Desk 3: Executive CTC Structure & Retiral Liabilities**: Decomposes CTC into Direct Gross, Employer PF/Gratuity/Insurance liabilities, and in-hand net salary.
- **Desk 4: Annual Merit Appraisal & Bell-Curve Manager**: 5-Tier Normal Distribution calibration across 10,000 employees.
- **Desk 5: Statutory Compliance & Legal Audit Radar**: Verification of EPFO ECR, ESIC, Professional Tax, TDS 24Q, and Gratuity Group Trust returns.

---

### 4. Database Architecture (MySQL 8)
- **Relational Integrity**:
  - Strict foreign-key constraints with `ON DELETE RESTRICT` on historical records to prevent orphaned compensation data.
  - Explicit decimal precision (`DECIMAL(12, 2)`) for all financial amounts.
- **Indexing Strategy for 10,000 Records**:
  - Compound B-tree indexes for common directory query paths: `(department_id, employment_status)`.
  - Prefix search on employee names and codes.
  - Unique composite index on `payslips (employee_id, payroll_month)` to ensure idempotency.

---

### 5. Security & Quality Architecture
1. **Authentication & RBAC**: Devise with BCrypt hashing, HttpOnly cookies, CSRF protection, and role guards (`hr_manager`, `admin`, `auditor`).
2. **Quality Gates**:
   - RSpec: 118 examples, 0 failures.
   - RuboCop: 83 files inspected, 0 offenses.
   - Brakeman: 0 warnings, 0 errors.
   - Vitest: 9 tests, 0 failures.

---

### 6. Health & Observability
- `/api/v1/health`: Lightweight endpoint verifying database connectivity (`ActiveRecord::Base.connection.active?`) and system timestamp, returning HTTP 200 `{"status": "ok", "db": "connected"}`.
