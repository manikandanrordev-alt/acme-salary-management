# Architecture Specification
## ACME Salary Management & Compensation Intelligence System

### 1. Architectural Principles & System Boundary
The ACME Salary Management System is designed as a unified monorepo containing a high-performance **Ruby on Rails API** backend and a responsive **React (Material UI)** single-page application frontend, backed by a **MySQL 8** relational database.

```
acme-salary-management/
├── backend/                  # Ruby on Rails 8 API Application
│   ├── app/
│   │   ├── controllers/      # API endpoints & Devise auth
│   │   ├── models/           # Domain models & ActiveRecord validations
│   │   ├── services/         # Salary revision & audit business transactions
│   │   ├── queries/          # Search, filter, and pagination query objects
│   │   └── serializers/      # Structured JSON formatting
│   ├── config/               # Routes, CORS, session, and database config
│   ├── db/                   # Migrations & 10k deterministic seeds
│   └── spec/                 # RSpec request, model, and service specs
├── frontend/                 # React 18+ Single Page Application
│   ├── src/
│   │   ├── api/              # Axios client with CSRF & session handling
│   │   ├── components/       # Reusable UI widgets & MUI layout
│   │   ├── context/          # Auth and notification context providers
│   │   ├── pages/            # Directory, Employee Detail, Analytics, Login
│   │   └── routes/           # Protected routes and navigation
│   └── tests/                # React Testing Library test suites
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
  - **Controllers**: Handle HTTP authentication, parameter sanitization (`ActionController::Parameters`), and delegating to Query/Service objects.
  - **Query Objects**: `EmployeesQuery` encapsulates complex sorting, multi-column search, and server-side pagination to maintain lean controllers and optimal SQL execution plans.
  - **Service Objects**: `SalaryRevisionService` guarantees atomic execution for updating/inserting salary intervals and writing audit logs within an explicit database transaction (`ActiveRecord::Base.transaction`).
  - **Analytics Engine**: `CompensationAnalyticsQuery` executes database-side `GROUP BY` and aggregate functions (`AVG`, `MIN`, `MAX`, `STDDEV`, window functions for median/percentiles) segregated by currency.
- **Consistent API Envelopes**:
  - Success responses return a `{ "data": ... }` payload accompanied by a `{ "meta": { "page": 1, "per_page": 25, "total_count": 10000, "total_pages": 400 } }` envelope for collections.
  - Error responses adhere to standard RFC 7807-style JSON errors:
    ```json
    {
      "error": {
        "code": "VALIDATION_FAILED",
        "message": "The salary effective dates overlap with an existing period.",
        "details": [
          { "field": "effective_from", "issue": "Overlaps with record dated 2025-01-01 to 2025-12-31" }
        ]
      }
    }
    ```

---

### 3. Frontend Architecture (React + Material UI)
- **Component Hierarchy**:
  - `App`: Theme provider (Material UI design system), Router, and AuthContextProvider.
  - `AuthenticatedLayout`: Persistent navigation bar, user session indicator, responsive drawer, and breadcrumbs.
  - `EmployeeDirectoryPage`: Controlled data table integrating debounced search, faceted filter chips, sort headers, and server-side pagination controls.
  - `EmployeeDetailPage`: Profile summary card, current compensation card, interactive salary timeline, revision dialog modal, and audit history log.
  - `CompensationAnalyticsPage`: Departmental and regional summary cards, salary distribution charts, and currency-filtered aggregate metrics.
- **Network & State Management**:
  - **Axios HTTP Client**: Configured with `withCredentials: true` to pass session cookies automatically. Interceptors automatically catch 401 Unauthorized responses to transition the UI to the login route.
  - **CSRF Synchronization**: Reads the `X-CSRF-Token` header provided by Rails endpoints and includes it in all state-modifying requests (`POST`, `PUT`, `PATCH`, `DELETE`).

---

### 4. Database Architecture (MySQL 8)
- **Relational Integrity**:
  - Strict foreign-key constraints with `ON DELETE RESTRICT` on historical records to prevent orphaned compensation data.
  - Explicit decimal precision (`DECIMAL(12, 2)`) for all financial amounts.
- **Indexing Strategy for 10,000 Records**:
  - Compound B-tree indexes for common directory query paths: `(department_id, employment_status)` and `(country_code, employment_status)`.
  - Prefix or full-text index on employee names and codes for sub-100ms multi-field search.
  - Temporal indexing on `(employee_id, effective_from, effective_to)` for immediate retrieval of active and historical compensation intervals.

---

### 5. Security Architecture
1. **Authentication**:
   - Devise handles password hashing using BCrypt with an enterprise-standard cost factor.
   - Session identifiers are stored in `HttpOnly`, `SameSite=Lax` (or `Strict`), `Secure` cookies, mitigating cross-site scripting (XSS) extraction risks.
   - Long-lived bearer tokens are explicitly prohibited from client-side `localStorage`.
2. **Authorization**:
   - Controller-level authorization checks verify user role (e.g., `hr_manager`) prior to executing read or mutation actions.
3. **Transport & Network**:
   - Strict CORS policy restricting allowed origins to the authorized frontend domain.
   - Parameterized SQL execution throughout ActiveRecord ensures immunity to SQL injection vulnerabilities.

---

### 6. Health & Observability
- `/api/v1/health`: Lightweight endpoint verifying database connectivity (`ActiveRecord::Base.connection.active?`) and system timestamp, returning HTTP 200 `{"status": "ok", "db": "connected"}`.
