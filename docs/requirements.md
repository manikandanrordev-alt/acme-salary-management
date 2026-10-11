# Product Requirements Document (PRD)
## ACME Salary Management & Compensation Intelligence System

### 1. Executive Summary & Problem Statement
ACME is an enterprise organization employing 10,000 personnel across multiple countries. The organization requires a secure, high-performance Salary Management and Compensation Intelligence System tailored for HR leadership. The system centralizes compensation records, tracks historical and effective-dated salary revisions, provides transactional audit trails, and delivers real-time compensation analytics without compromising performance or data integrity.

### 2. User Persona
- **Primary Persona**: HR Manager / Compensation Director
  - **Role**: Oversees organizational salary records, processes compensation revisions, tracks employee status, and analyzes remuneration equity across departments and geographies.
  - **Key Needs**:
    - Rapid searching, filtering, and navigation across 10,000 employee records.
    - Transparent timeline of salary changes with effective dates and audit attribution.
    - Protection against accidental data loss, retroactive conflicts, and overlapping salary periods.
    - Departmental and regional compensation intelligence respecting currency boundaries.
    - Dependable data export for downstream reporting.

### 3. Functional Requirements
1. **Authentication & Authorization**:
   - Secure email/password authentication using Devise.
   - HttpOnly, SameSite, Secure cookie-based session management.
   - Role-Based Access Control (RBAC) ensuring only authorized HR managers access sensitive compensation data.
   - CSRF protection and defensive CORS headers.
2. **Employee Directory (10,000 Employees)**:
   - High-performance directory listing with server-side pagination, sorting, and multi-field search (name, employee code, department, country).
   - Filter by employment status (`active`, `on_leave`, `terminated`), department, and country.
3. **Employee Details & Lifecycle Status**:
   - Comprehensive profile view: Employee Code, Full Name, Contact Email, Department, Country, Hire Date, and Status.
   - State management for active, on-leave, and terminated employees.
4. **Salary Management & Effective Dating**:
   - Support for effective-dated salary records (`effective_from` and `effective_to`).
   - Resolution rule: Current salary is uniquely identified by `effective_from <= CURRENT_DATE AND (effective_to IS NULL OR effective_to >= CURRENT_DATE)`.
   - Strict validation preventing overlapping or ambiguous salary periods for an employee.
   - Explicit currency support (ISO 4217, e.g., USD, EUR, INR, GBP) and pay frequency.
5. **Historical Revisions & Audit Logging**:
   - Immutable audit trail (`salary_audit_logs`) tracking all revisions with change reason, actor, previous/new values, timestamps, and client metadata.
   - Atomic database transactions: salary updates fail completely if audit logging fails.
6. **Compensation Analytics & Reporting**:
   - Aggregated metrics: Headcount, Total Payroll (currency-segregated), Average Salary, Median Salary, and Salary Range by Department and Country.
   - Safe multi-currency handling: prevents erroneous arithmetic summation of disparate currencies.
7. **CSV Export & Import**:
   - Filter-respecting CSV export of employee directory and compensation summaries.
   - Validated CSV bulk import with error reporting to avoid silent data corruption.

### 4. Non-Functional Requirements
- **Performance**: Sub-500ms response times on search, filtering, and pagination over 10,000 seeded employee records.
- **Data Integrity**: Database-level foreign keys, unique indexes, and decimal precision (`DECIMAL(12, 2)`) for monetary amounts.
- **Security**: No plaintext credentials; secure sessions; no long-lived JWTs in `localStorage`; sanitized parameterized queries.
- **Usability**: Responsive, accessible Material UI frontend with intuitive empty, loading, error, and confirmation states.

### 5. Out of Scope / Non-Goals (Deferred Features)
The following capabilities are deferred and will not be implemented without separate approval:
- Full automated payroll disbursement and direct bank wire integrations.
- Statutory deductions and country-specific tax engines (e.g., PF, ESI, TDS, Professional Tax, 401(k)).
- Automated statutory bonus computation.
- Automated email delivery of individual payslips.
- Complex hierarchical multi-stage approval workflows (e.g., manager approval -> VP approval -> HR signoff).
- Real-time automated forex exchange rate ingestion (analytics will strictly segregate currencies).

### 6. Acceptance Criteria
- [ ] Database seeds exactly 10,000 synthetic employees deterministically with realistic departments, countries, and salaries.
- [ ] Server-side queries execute efficiently utilizing database indexes.
- [ ] Devise cookie authentication operates securely with CSRF and CORS controls.
- [ ] All salary modifications generate corresponding immutable audit log records.
- [ ] Unit, integration, and request test coverage validates business invariants.
