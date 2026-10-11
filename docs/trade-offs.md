# Architectural & Technical Trade-offs
## ACME Salary Management System

### 1. Monorepo Architecture vs. Microservices / Polyrepo
- **Decision**: Single unified repository (`acme-salary-management/` containing `backend/` and `frontend/`).
- **Rationale**:
  - The business domain (HR salary records and analytics) is cohesive and managed by a unified engineering stream.
  - Eliminates network serialization latency, distributed transactions, and two-phase commit overhead between separate microservices.
  - Enables synchronized contract changes, end-to-end integration testing in CI, and simple local development setups.
- **Trade-off / Mitigation**: Backend and frontend codebases have separate dependency manifests (`Gemfile` vs `package.json`) and isolated directory structures, preventing accidental leakage of concerns.

---

### 2. Devise Cookie-Based Sessions vs. JWT in LocalStorage
- **Decision**: HttpOnly, SameSite, Secure cookie-based session management using Devise and Rails session store.
- **Rationale**:
  - Sensitive compensation data mandates maximum protection against token exfiltration. Storing JWTs in `localStorage` or `sessionStorage` exposes credentials to Cross-Site Scripting (XSS) vectors.
  - Cookies configured with `HttpOnly` cannot be read by JavaScript.
  - Cookie sessions allow instantaneous server-side revocation on logout or credential reset.
- **Trade-off / Mitigation**: Requires explicit CSRF token verification and CORS origin whitelisting. Rails provides built-in request forgery protection, and Axios seamlessly passes credentials and CSRF headers.

---

### 3. Effective-Dated Records vs. Event Sourcing vs. Snapshot Snapshots
- **Decision**: Explicit effective-dated intervals (`effective_from`, `effective_to`) combined with an immutable audit log table (`salary_audit_logs`).
- **Rationale**:
  - Temporal queries ("What was John Doe's salary on October 1st, 2024?") can be evaluated directly via standard SQL indexed range queries (`effective_from <= date AND (effective_to IS NULL OR effective_to >= date)`).
  - Event sourcing introduces substantial query complexity, eventual consistency challenges, and projection replay overhead when filtering across 10,000 employees.
- **Trade-off / Mitigation**: Effective dating introduces the risk of overlapping intervals. We mitigate this through application-level service validations and transaction boundaries that guarantee interval integrity before persisting.

---

### 4. Database-Side Pagination & Aggregation vs. Client-Side In-Memory Processing
- **Decision**: Server-side pagination, searching, sorting, and database aggregations for all 10,000 employees.
- **Rationale**:
  - Transferring 10,000 full employee records with compensation histories consumes 5–10 MB of JSON bandwidth per page load and degrades mobile/low-memory browser rendering.
  - MySQL indexes allow multi-column sorting and filtering across 10,000 records in under 20 milliseconds.
- **Trade-off / Mitigation**: Requires careful query object implementation and index tuning on MySQL. Debounced search inputs and skeleton loaders are provided in the UI for optimal user experience.

---

### 5. Segregated Multi-Currency Reporting vs. Synthetic Dynamic FX Conversion
- **Decision**: Strict currency segregation (ISO 4217) across all aggregations, analytics, and summaries. Disparate currencies are never summed together.
- **Rationale**:
  - Applying arbitrary or dynamic foreign exchange (FX) rates introduces fluctuating payroll figures that corrupt audit trails and violate compensation accounting principles.
  - Real-world multinational HR reviews compensation relative to local currency bands and regional cost-of-living tiers.
- **Trade-off / Mitigation**: The analytics dashboard presents metrics filtered by currency or grouped by currency partitions rather than displaying a single unified global sum. A future extension can introduce corporate fixed budget FX rates if explicitly approved.

---

### 6. Material UI (MUI) Design System
- **Decision**: React with Material UI (MUI).
- **Rationale**:
  - Provides battle-tested, accessible enterprise components: data tables with pagination controls, responsive dialogs for salary revisions, form validation feedback, and dark/light themes.
  - Drastically accelerates development while delivering a polished, high-fidelity experience tailored for enterprise HR workflows.
- **Trade-off / Mitigation**: MUI bundles can be large if unoptimized; mitigated by using named imports and Vite tree-shaking.
