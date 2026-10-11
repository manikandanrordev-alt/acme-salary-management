# Implementation Plan & Milestone Roadmap
## ACME Salary Management System

### 1. Overview & Execution Strategy
The ACME Salary Management System is developed using a strict milestone-gated process. Each milestone is self-contained, rigorously verified with automated tests and quality checks, reviewed against explicit acceptance criteria, committed with Conventional Commits, and halted for approval prior to progressing.

---

### 2. Milestone Breakdown

| Milestone | Title | Focus & Core Deliverables | Acceptance Verification | Commit Convention |
| :--- | :--- | :--- | :--- | :--- |
| **Milestone 0** | Project Foundation & Planning | Directory structure, PRD, architecture, data model, trade-offs, and roadmap. | Documentation complete, workspace preserved, git initialized, clean review. | `docs: add product requirements and architecture` |
| **Milestone 1** | Application Initialization | Rails 8 API in `backend/`, React in `frontend/`, MySQL config, `/health` endpoints, linters, and CI skeleton. | Rails and React start cleanly, MySQL connects, health check passes, CI passes. | `chore: initialize Rails API and React application` |
| **Milestone 2** | Database & 10k Seed Data | Migrations, models, foreign keys, indexes, and deterministic 10,000 synthetic employee seed script. | Exactly 10k employees seeded, schema constraints enforced, model unit tests pass. | `feat: implement data model and seed 10000 employees` |
| **Milestone 3** | Devise Authentication | Devise setup, cookie session store, login/logout endpoints, CSRF & CORS policies, HR role authorization. | Valid credentials authenticate, invalid rejected, cookies secure, request specs pass. | `feat: implement Devise authentication and authorization` |
| **Milestone 4** | Employee Directory API | Server-side pagination, multi-column search, status/department/country filters, sorting, query objects. | Query latency < 100ms on 10k records, standard JSON pagination envelopes, tests pass. | `feat: implement employee directory API with pagination and search` |
| **Milestone 5** | Salary Management & History | Effective-dated salary revisions, non-overlapping validation, atomic transactional audit logging. | Transactions roll back on failure, historical records preserved, audit log captured. | `feat: implement effective-dated salary revisions and audit logs` |
| **Milestone 6** | React Employee Management UI | Directory data table, search/filter bars, detail drawer/page, revision modal dialog, error/loading states. | End-to-end flows operate in browser, form validations show helpful messages, RTL tests pass. | `feat: build React employee directory and salary management UI` |
| **Milestone 7** | Compensation Analytics | Department & country summaries, median/percentile metrics, strict multi-currency segregation. | Analytics math independently verified, currency segregation enforced, tests pass. | `feat: implement compensation analytics and reporting` |
| **Milestone 8** | CSV Export & Import | Filtered CSV export of employees and compensation, validated bulk CSV import with error reporting. | Export reflects active filters, import validates headers/data types, specs pass. | `feat: implement authorized CSV export and validated import` |
| **Milestone 9** | Quality, Security & Performance | Full test suite execution, RuboCop & ESLint checks, query index review (EXPLAIN), accessibility audit. | Zero critical lint or security issues, sub-second query performance verified. | `chore: enforce linting, security audits, and performance tuning` |
| **Milestone 10** | Deployment & CI/CD | Dockerfiles / production builds, GitHub Actions pipeline, production environment configurations. | Full CI matrix green, production containers build cleanly, health check verified. | `ci: finalize GitHub Actions workflows and deployment configs` |
| **Milestone 11** | Final Artifacts & Demonstration | Final documentation, verified setup guide, AI usage review, video demonstration walkthrough. | All acceptance criteria satisfied, clean git log, ready for Incubyte assessment review. | `docs: complete setup guides, demonstration, and assessment submission` |

---

### 3. Assumptions, Risks, and Unresolved Decisions

#### Assumptions
1. **Host Environment**: The system uses existing system packages: Ruby 4.0.6, Rails 8.1.3, Node.js v20.19.5, npm 10.8.2, and MySQL 8.0.
2. **Access Patterns**: HR Managers are the primary authenticated actors. Read and modification operations require authenticated sessions.
3. **Data Scope**: The 10,000 synthetic employee dataset provides sufficient scale to validate query indexing and server-side pagination performance.
4. **Currency Policy**: ACME operates with local currency remuneration; multinational reporting strictly maintains currency segregation rather than arbitrary real-time FX conversion.

#### Risks & Mitigations
| Identified Risk | Impact | Architectural Mitigation |
| :--- | :--- | :--- |
| **Query degradation across 10k rows** | High latency on search/sort | Composite B-tree indexes, server-side pagination (limit/offset or keyset), avoid N+1 queries using `includes`/`eager_load`. |
| **Overlapping salary dates** | Corrupts compensation history | Database constraints + model-level interval overlap validation + atomic transactional updates. |
| **Session cookie leakage across origins** | Security breach | Strict `SameSite` policy, `HttpOnly`, `Secure` cookies, and origin-locked CORS whitelist. |
| **Accidental cross-currency summation** | Misleading analytics | Analytics queries group strictly by `currency`; UI components partition cards/charts by currency code. |

#### Unresolved Decisions / Discussion Points
1. **Deferred Features Approval**: Full automated payroll disbursements, statutory tax engines (PF/ESI/TDS), and automated payslip emails remain out of scope pending future review.
2. **Import Strategy**: For CSV import, whether partial success with error-row skips is preferred over complete transactional abort on first error (we recommend atomic abort with detailed error row reporting).
