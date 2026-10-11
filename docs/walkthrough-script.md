# Video Demonstration Walkthrough Script
## ACME Salary Management & Compensation Intelligence System
**Target Duration: 3 to 5 Minutes**

---

### Segment 1: Introduction & Architecture Overview (0:00 - 0:35)
1. **Welcome & Context**:
   - "Hello and welcome to the ACME Salary Management System demonstration for Incubyte."
   - "This system is built from scratch as an enterprise-grade solution designed to manage compensation across a multinational organization of 10,000 employees in 5 countries."
2. **Tech Stack**:
   - "The stack consists of a Rails 8 API backend, a React SPA powered by Vite and Material UI, a MySQL 8 relational database, and multi-stage containerization with Docker Compose."
3. **Infrastructure Check**:
   - Open `/health` or run `curl http://localhost:3000/api/v1/health`.
   - Point out real-time connection pool status (`db: "connected"`).

---

### Segment 2: Authentication & Role-Based Access Control (0:35 - 1:10)
1. **Login Page (`/login`)**:
   - Showcase the enterprise login page with dark theme aesthetics.
   - Demonstrate the one-click demo credentials for:
     - **HR Manager** (`hr_director@acme.com`)
     - **Auditor** (`compliance@acme.com`)
     - **System Admin** (`admin@acme.com`)
2. **Sign In as HR Manager**:
   - Click "HR Manager" button & submit.
   - Note the Navbar badge showing role "HR Manager" and secure HttpOnly cookie session with CSRF protection.

---

### Segment 3: High-Performance Employee Directory (1:10 - 1:55)
1. **Dataset Scale & Speed**:
   - Point out the active dataset: **10,000 employees**.
   - Note sub-40ms server-side pagination across 10, 25, 50, and 100 rows per page.
2. **Debounced Search**:
   - Search for employee code `ACME-00101` or name `Alice`.
   - Show instant sub-string matching across code, first name, last name, and email.
3. **Multi-Column Filtering**:
   - Filter by **Department**: `Engineering`.
   - Filter by **Country**: `United States (US)`.
   - Filter by **Status**: `Active`.
   - Note that results update instantly and respect composite database indexes.

---

### Segment 4: Employee Detail & Effective-Dated Salary Revisions (1:55 - 2:45)
1. **Navigate to Employee Detail**:
   - Click on an employee row (e.g. `ACME-00001`).
   - Showcase the Employee Profile card, Active Base Salary card, and historical revision timeline table.
2. **Execute Salary Revision**:
   - Click **"Revise Salary"** button (enabled for HR Managers).
   - Modal opens:
     - New Salary: `$135,000`
     - Currency: `USD`
     - Effective From: `2024-01-01`
     - Reason: `Annual Merit Increase`
   - Click "Save Salary Revision".
3. **Verify Revision Integrity**:
   - Active compensation immediately updates to `$135,000 USD`.
   - The preceding salary record is automatically capped on `2023-12-31`.
   - The timeline reflects the new record at the top with "Current Active" status.
   - A transactional `SalaryAuditLog` entry is generated capturing previous amount, new amount, change reason, and client IP address.

---

### Segment 5: Compensation Intelligence & Multi-Currency Analytics (2:45 - 3:30)
1. **Navigate to Analytics (`/analytics`)**:
   - Showcase the **Compensation Intelligence Dashboard**.
2. **Multi-Currency Safety**:
   - Point out that **currencies are never lumped together**:
     - `USD` card: Total Payroll, Headcount, Average Salary, Min & Max.
     - `GBP` card: Native British Pound metrics.
     - `EUR`, `INR`, and `SGD` cards.
3. **Department & Regional Breakdown**:
   - Switch currency tab to `USD ONLY` or `ALL CURRENCIES`.
   - Review department table and regional headcount distribution.

---

### Segment 6: CSV Export & Bulk Import Workflows (3:30 - 4:15)
1. **Streaming CSV Export**:
   - Return to Directory (`/employees`).
   - Filter by `Engineering` & `United States`.
   - Click **"Export CSV"**.
   - Demonstrate memory-safe batch download of the filtered subset.
2. **Validated CSV Import**:
   - Click **"Import CSV"**.
   - Upload sample CSV or select file.
   - Demonstrate atomic creation of employee records, active salary entries, and audit logs.
   - Showcase row-by-row error reporting if a duplicate code or invalid country code is submitted.

---

### Segment 7: Role Restriction, Quality Audits & Conclusion (4:15 - 5:00)
1. **Auditor Role Verification**:
   - Click "Logout" and sign in as **Auditor** (`compliance@acme.com`).
   - Notice that "Revise Salary" and "Import CSV" buttons are disabled/hidden.
   - Any manual POST request returns HTTP `403 Forbidden`.
2. **Automated Testing & Security Checks**:
   - Run `bundle exec rspec` (94 examples passing, 0 failures).
   - Run `bundle exec brakeman` (0 security warnings).
   - Run `npm test` (5 Vitest examples passing).
3. **Closing**:
   - "Thank you for reviewing the ACME Salary Management System. The codebase is fully committed, documented, and ready for production deployment."
