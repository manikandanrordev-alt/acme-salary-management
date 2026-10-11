# Incubyte Engineering Assessment: ACME Salary Management System
## Technical Evaluation & Architectural Assessment Report

### Executive Summary
The **ACME Salary Management and Compensation Intelligence System** is a production-ready, full-stack enterprise platform built to manage compensation data for an international enterprise of **10,000 employees** across 5 countries (**United States**, **United Kingdom**, **Germany**, **India**, and **Singapore**).

The solution is architected with a **Ruby on Rails 8 API** backend, a **React (Material UI)** single-page application frontend, a **MySQL 8** relational database, **Devise cookie-based authentication with CSRF protection**, **effective-dated salary history**, and **transactional immutable audit logging**.

---

## 1. Architectural Highlights & Engineering Decisions

### 1.1 Backend: Ruby on Rails 8 API
- **Strict Separation of Concerns**: Controllers only handle HTTP protocol negotiation, serialization, and status codes. Business logic is strictly encapsulated in Services ([`SalaryRevisionService`](file:///home/manikandan-ned/Documents/SCM_mani/My/acme-salary-management/backend/app/services/salary_revision_service.rb), [`EmployeeCsvImportService`](file:///home/manikandan-ned/Documents/SCM_mani/My/acme-salary-management/backend/app/services/employee_csv_import_service.rb), [`EmployeeCsvExportService`](file:///home/manikandan-ned/Documents/SCM_mani/My/acme-salary-management/backend/app/services/employee_csv_export_service.rb)) and Query Objects ([`EmployeesQuery`](file:///home/manikandan-ned/Documents/SCM_mani/My/acme-salary-management/backend/app/queries/employees_query.rb), [`CompensationAnalyticsQuery`](file:///home/manikandan-ned/Documents/SCM_mani/My/acme-salary-management/backend/app/queries/compensation_analytics_query.rb)).
- **Memory-Safe Streaming**: CSV export leverages `find_each(batch_size: 1000)` to ensure exporting 10,000 records consumes constant \(O(1)\) memory footprint.
- **Connection Pool Resilience**: Custom health check dynamically executes `SELECT 1` through `ActiveRecord::Base.connection_pool.with_connection` to guarantee real-time pool liveness.

### 1.2 Frontend: React with Material UI & Vite
- **Modern Theme & Ergonomics**: Built with Material UI dark theme (`#0b0f19` canvas, `#111827` cards, `#38bdf8` primary accents, `#34d399` currency greens).
- **Responsive Navigation**: Tabbed views for Employee Directory, Detail, Multi-Currency Analytics, and Infrastructure Health.
- **Enterprise UX**: Server-side sorted and paginated Data Table, debounced instant search, live filter dropdowns, and validated modals.

### 1.3 Database: MySQL 8 Relational Schema & Indexing
- **Composite Index Tuning**:
  - `idx_emp_country_status` on `(country_code, employment_status)`
  - `idx_emp_dept_status` on `(department_id, employment_status)`
  - `idx_sal_active_currency_amount` on `(effective_to, currency, amount)`
  - `idx_salary_emp_dates` on `(employee_id, effective_from, effective_to)`
  - `idx_emp_name_search` on `(last_name, first_name)`
- **Query Optimization**: Active salary queries execute via indexed ref lookups (`ref: idx_sal_active_currency_amount`), eliminating full table scans across 18,797+ salary history rows. Directory pagination queries execute in sub-40ms on 10,000 rows.

---

## 2. Core Business Rules & Data Integrity

### 2.1 Effective-Dated Salary Revisions
- Salaries are open-ended (`effective_to IS NULL`) when active.
- When an authorized revision is recorded:
  1. The new effective date must be strictly after the current active record's start date (`effective_from`).
  2. The preceding salary record is closed at `new_effective_from - 1.day`.
  3. The new salary record is created with `effective_to: nil`.
  4. An immutable [`SalaryAuditLog`](file:///home/manikandan-ned/Documents/SCM_mani/My/acme-salary-management/backend/app/models/salary_audit_log.rb) record is created recording previous amount/currency, new amount/currency, change reason, user ID, IP address, and timestamp.
  5. The entire operation is wrapped inside a single database transaction.

### 2.2 Multi-Currency Safety
- Cross-currency figures are **never** summed or averaged together.
- In both the database queries and the frontend dashboard, compensation aggregations (headcount, payroll, average, min, max) are partitioned strictly by ISO-4217 currency (`USD`, `GBP`, `EUR`, `INR`, `SGD`).

### 2.3 Deterministic 10,000 Employee Dataset
- Populated via [`backend/db/seeds.rb`](file:///home/manikandan-ned/Documents/SCM_mani/My/acme-salary-management/backend/db/seeds.rb) using `insert_all` batching (1,000 rows per batch).
- Generates exactly 10,000 employees, 18,797 salary records, and 18,797 audit log records in **under 11 seconds**.

---

## 3. Security Posture

- **Authentication**: Devise session authentication utilizing HttpOnly cookies.
- **CSRF Protection**: Rails `protect_from_forgery with: :exception` with automatic `CSRF-TOKEN` cookie generation and client-side header injection (`X-CSRF-Token`).
- **Authorization (RBAC)**:
  - `hr_manager` / `admin`: Full view, revise salary, CSV import/export.
  - `auditor`: View directory, view detail, view analytics, CSV export; cannot revise salaries or import records (`403 Forbidden`).
- **Static Security Analysis**:
  - **Brakeman**: **0 security warnings** across all 79 automated security vulnerability checks.
  - **Bundler-Audit**: **0 vulnerabilities**.

---

## 4. Test Coverage & Quality Verification

| Component | Framework | Count | Status |
| :--- | :--- | :--- | :--- |
| Backend Models | RSpec | 18 | Passing |
| Backend Queries | RSpec | 15 | Passing |
| Backend Services | RSpec | 14 | Passing |
| Backend Requests (Auth, Employees, Revisions, Analytics, CSV) | RSpec | 47 | Passing |
| **Total Backend Tests** | **RSpec 7.1** | **94** | **100% Passing (0 failures)** |
| Frontend Auth & Routing | Vitest & React Testing Library | 3 | Passing |
| Frontend Analytics & CSV Actions | Vitest & React Testing Library | 2 | Passing |
| **Total Frontend Tests** | **Vitest 4.1** | **5** | **100% Passing (0 failures)** |
| Backend Linting | RuboCop Rails Omakase | 60 files | **0 offenses detected** |
| Frontend Linting | Oxlint | 14 files | **0 errors** |
| Production Bundle Build | Vite | - | **Compiled in 821ms** |
