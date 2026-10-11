# AI Usage & Pair Programming Reflection
## ACME Salary Management System & Incubyte Assessment

### 1. Intentional AI Usage Philosophy
Throughout the development of the ACME Salary Management System, AI was leveraged as an advanced engineering accelerator rather than an unguided generator. Every architectural decision, schema migration, business constraint, and test expectation was deliberately scoped and validated against production engineering standards.

The goal was to demonstrate **architectural clarity, code quality, disciplined Git history, and security hardening**, ensuring the codebase reads as if authored by a senior full-stack software engineer.

---

### 2. High-Leverage AI Contributions
- **Rapid Greenfield Scaffolding**: Accelerated boilerplate generation for Rails 8 API, Vite React configuration, and Docker containerization.
- **Deterministic Seed Data Generation**: Generated algorithmic batch creation of 10,000 synthetic employees, realistic salary distributions, and historical audit logs executing in ~10 seconds using bulk SQL insertions.
- **Comprehensive Test Suite Generation**: Rapidly drafted RSpec request, service, model, and query specs alongside React Testing Library component tests.

---

### 3. Engineering Judgment & Critical Course Corrections
While AI provided speed, human architectural discernment was required at several critical junctures:

1. **Rails 8 Idle Connection Pool Health Check**:
   - *AI default*: Calling `ActiveRecord::Base.connection.active?`.
   - *Issue*: In Rails 8 connection pools with lazy initialization, `active?` returns `false` on cold boot even if MySQL is fully healthy.
   - *Correction*: Wrapped execution inside `ActiveRecord::Base.connection_pool.with_connection { |conn| conn.execute("SELECT 1") }`, guaranteeing true end-to-end pool verification.

2. **API Cookie Authentication & CSRF Handling**:
   - *Challenge*: Implementing Devise with cookie sessions in an API-only Rails controller while enforcing CSRF for non-GET requests without breaking SPA logins.
   - *Solution*: Configured `protect_from_forgery with: :exception`, issued `CSRF-TOKEN` cookie via after_action, skipped verification specifically on `:create`, `:destroy`, and `:csrf_token` in `SessionsController`, and used Axios request interceptors to automatically transmit `X-CSRF-Token` headers.

3. **Ruby 4.0 / Bundled Gem Isolation**:
   - *Issue*: Ruby 3.4+ and 4.0 transitioned `csv` from default standard library to bundled gem.
   - *Correction*: Explicitly declared `gem "csv"` in Gemfile and bundled it, preventing runtime `LoadError` in modern Ruby runtimes.

4. **Brakeman Static Analysis & SQL Interpolation**:
   - *Issue*: Dynamic table column sorting using `Arel.sql("#{column} #{direction}")` triggered medium-confidence SQL injection warnings in Brakeman.
   - *Correction*: Refactored `EmployeesQuery#apply_sorting` to use native Active Record hash syntax (`order(employee_code: direction)` and `order("departments.name" => direction)`), eliminating `Arel.sql` entirely and achieving **0 Brakeman warnings**.

5. **MySQL Composite Index Tuning for 10,000 Rows**:
   - *Analysis*: Analyzed MySQL `EXPLAIN` query plans and discovered that `WHERE effective_to IS NULL` was causing full table scans (`ALL`, 18,922 rows).
   - *Correction*: Introduced a targeted migration adding `idx_sal_active_currency_amount` on `(effective_to, currency, amount)`, transitioning active compensation lookups to indexed ref lookups (`ref`).

---

### 4. Git History & Milestone-Gated Cadence
Rather than generating a monolithic codebase in a single untracked commit, the repository was built through 12 controlled milestones:
- Every milestone represents an isolated, logical increment.
- All code changes are backed by automated tests.
- Commits strictly follow Conventional Commits formatting (`feat:`, `chore:`) on the `master` branch.

---

### 5. Summary Conclusion
AI serves as an extraordinary force multiplier when paired with deep foundational knowledge of language runtimes, database indexing, and application security. The resulting ACME codebase stands as a testament to disciplined, production-ready full-stack software craftsmanship.
