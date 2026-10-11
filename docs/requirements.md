# Product Requirements Document (PRD)
## ACME Salary Management & Compensation Intelligence System

### 1. Executive Summary & Problem Statement
ACME is an enterprise organization employing 10,000 personnel. The organization requires a secure, high-performance Salary Management, Indian Statutory Payroll, and Senior HR Executive Intelligence System. The system centralizes compensation records, tracks historical and effective-dated revisions, automates monthly payslip generation with email dispatch, calculates statutory tax regimes, provisions gratuity reserves, and delivers real-time compensation intelligence.

### 2. User Persona
- **Primary Persona**: Senior HR Director / VP of Total Rewards
  - **Role**: Oversees organizational salary structures, Indian statutory compliance, retiral liability provisions (Payment of Gratuity Act), annual merit cycles, and executive compensation architecture.
  - **Key Needs**:
    - Dual tax regime comparison (New vs Old) to optimize employee take-home pay.
    - Statutory gratuity calculations with 5-year vesting and CBDT-compliant leave encashment.
    - Full & Final (F&F) settlement reconciliation upon employee separation.
    - Automated monthly payslip generation and email dispatch.
    - Flight-risk detection and merit pool budget governance.

### 3. Functional Requirements
1. **Authentication & Authorization**:
   - Secure email/password authentication using Devise.
   - HttpOnly, SameSite, Secure cookie-based session management.
   - RBAC for HR Director, System Admin, and Auditor roles.
2. **Employee Directory (10,000 Employees)**:
   - High-performance directory with server-side pagination, sorting, and multi-field search.
3. **Effective-Dated Salary Management**:
   - Point-in-time salary records (`effective_from <= CURRENT_DATE AND (effective_to IS NULL OR effective_to >= CURRENT_DATE)`).
   - Immutable transactional audit logging (`salary_audit_logs`).
4. **Senior HR Executive Suite (`/hr-suite`)**:
   - **Form 16 Tax Regime Optimizer**: Compares New Regime (Sec 115BAC) vs Old Regime with Chapter VI-A investment deductions.
   - **Gratuity & F&F Desk**: Payment of Gratuity Act 1972 (`15*Basic*Tenure/26`), leave encashment (`Basic/30*Leaves`), and notice recovery.
   - **Executive CTC Architecture**: Component A (Gross), Component B (Retirals), Component C (Diwali bonus), and net take-home pay.
   - **Merit Cycle Manager**: 5-Tier Normal Distribution (Bell Curve) and merit pool governance.
   - **Statutory Audit Radar**: EPFO ECR, ESIC, Professional Tax, TDS 24Q, and Gratuity Trust tracking.
5. **Monthly Payroll & Payslips (`/payslips`)**:
   - Batch monthly payslip generation for active employees.
   - Automated batch email dispatch with delivery status tracking.
   - Detailed Indian corporate payslip modal with CIN, GSTIN, PAN, TAN, and UAN.
6. **AI Retention & Compensation Intelligence (`/ai-advisor`)**:
   - AI payroll health score, predictive flight-risk radar, and salary raise simulator.

### 4. Non-Functional & Security Requirements
- **Performance**: Sub-500ms response times over 10,000 seeded employee records.
- **Data Integrity**: Foreign keys, composite indexes, and `DECIMAL(12, 2)` monetary precision.
- **Security**: Zero plaintext credentials, parameterized queries, and CSRF token enforcement.
- **Quality Gates**:
  - RSpec: 134 examples, 0 failures.
  - RuboCop: 83 files, 0 offenses.
  - Brakeman: 0 warnings, 0 errors.
  - Vitest: 9 tests, 0 failures.
