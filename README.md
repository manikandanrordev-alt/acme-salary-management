# ACME Salary Management & Compensation Intelligence System

A comprehensive, enterprise-grade Salary Management and Compensation Intelligence application designed for ACME, an organization with 10,000 employees distributed across global offices.

Developed as a demonstration of senior full-stack architecture, rigorous engineering judgment, automated testing, transactional data integrity, and incremental milestone delivery for the **Incubyte Engineering Assessment**.

---

## 1. Architectural Stack

- **Backend**: Ruby on Rails 8 API mode (Ruby 4.0+)
- **Database**: MySQL 8.0 with foreign keys, composite indexes, and strict decimal precision (`DECIMAL(12, 2)`)
- **Authentication**: Devise with secure cookie-based session management, CSRF validation, and RBAC
- **Frontend**: React (Vite) with Material UI (MUI) design system and React Router
- **Testing**: RSpec (backend unit, request, and service tests) and React Testing Library (frontend UI tests)
- **CI/CD**: GitHub Actions for automated linting, test suites, and container build checks
- **Versioning**: Git with Conventional Commits and gated milestone progression

---

## 2. Repository Structure

```
acme-salary-management/
├── backend/                  # Ruby on Rails API (Milestone 1+)
├── frontend/                 # React Material UI SPA (Milestone 1+)
├── docs/                     # Specifications & Design Documents
│   ├── requirements.md       # Product Requirements Document (PRD)
│   ├── architecture.md       # System Architecture & Component Design
│   ├── data-model.md         # ERD, Schemas, Effective Dating & Invariants
│   ├── trade-offs.md         # Technical Decisions & Rationale
│   └── implementation-plan.md# 12-Milestone Delivery Plan & Acceptance Criteria
├── .github/
│   └── workflows/            # CI pipeline definitions
├── .gitignore                # Comprehensive exclusions for Rails & React
└── README.md                 # Project entry point & developer guide
```

---

## 3. Product Capabilities Overview

1. **HR Management & Security**: Devise-powered authentication with HttpOnly/SameSite session cookies and role-based access for HR Managers.
2. **High-Performance Directory**: Fast search, filtering, and server-side pagination engineered for 10,000 seeded employee records.
3. **Effective-Dated Salary Management**: Point-in-time salary records with unambiguous resolution (`effective_from <= CURRENT_DATE AND (effective_to IS NULL OR effective_to >= CURRENT_DATE)`) and zero overlapping ranges.
4. **Immutable Audit Trails**: Atomic database transactions logging every compensation modification with user attribution, previous/new figures, and change justifications.
5. **Compensation Intelligence & Analytics**: Real-time departmental and geographic salary metrics (average, median, spread) strictly partitioned by currency code (ISO 4217).
6. **CSV Export & Import**: Filter-aware CSV exports and validated bulk imports preventing silent data corruption.

---

## 4. Milestone Progress Roadmap

| Milestone | Status | Description |
| :--- | :--- | :--- |
| **Milestone 0** | **Completed** | Repository setup, PRD, architecture, data model, trade-offs, and implementation plan. |
| **Milestone 1** | **Completed** | Rails API & React SPA initialization, MySQL config, health check, CI setup. |
| **Milestone 2** | **Completed** | Relational schema, models, constraints, and deterministic 10,000 synthetic employee seed data. |
| **Milestone 3** | **Completed** | Devise cookie-based authentication, CSRF/CORS configuration, and authorization guards. |
| **Milestone 4** | **Completed** | Employee directory endpoints with server-side pagination, sorting, and search. |
| **Milestone 5** | **Completed** | Effective-dated salary revisions and transactional audit logging. |
| **Milestone 6** | **Completed** | Material UI frontend dashboard, directory table, and salary revision modal. |
| **Milestone 7** | **Completed** | Compensation analytics engine and currency-safe summary cards. |
| **Milestone 8** | **Completed** | Authorized CSV export and validated import workflows. |
| **Milestone 9** | **Completed** | Quality audit, full test suites, RuboCop/ESLint checks, and index optimization. |
| **Milestone 10** | **Completed** | Production deployment readiness, Docker configurations, and CI verification. |
| **Milestone 11** | *Queued* | Final artifacts, setup walkthrough, AI usage review, and demonstration recording. |

---

## 5. Documentation Links

- [Product Requirements Document (PRD)](docs/requirements.md)
- [System Architecture Specification](docs/architecture.md)
- [Data Model & Business Rules](docs/data-model.md)
- [Technical Trade-offs Analysis](docs/trade-offs.md)
- [Implementation Plan & Roadmap](docs/implementation-plan.md)

---

## 6. Verified Local Setup & Commands

### Prerequisites
- **Ruby**: 4.0.6+ / 3.3+
- **Rails**: 8.1.3+
- **Node.js**: v20.19.5+
- **npm**: 10.8.2+
- **MySQL**: 8.0+ running on port 3306

### Backend Setup & Tests
```bash
cd backend

# Install dependencies
bundle install

# Setup databases
bin/rails db:create db:migrate

# Run RuboCop linter
bundle exec rubocop app/ spec/ config/routes.rb config/initializers/cors.rb

# Run backend RSpec tests
bundle exec rspec

# Start Rails API server (port 3000)
bin/rails server -p 3000
```

### Frontend Setup & Tests
```bash
cd frontend

# Install dependencies
npm install

# Run oxlint linter
npm run lint

# Run Vitest test suite
npm test

# Build production assets
npm run build

# Start Vite dev server (port 5173 with proxy to port 3000)
npm run dev
```

### Containerized Production Stack (Docker Compose)
```bash
# Build and run the entire multi-container production stack (MySQL 8, Rails 8 API, Nginx SPA)
docker compose up --build -d

# Check service health
docker compose ps

# Seed 10,000 synthetic employees in containerized database
docker compose exec backend bin/rails db:seed

# Access the application
# Frontend SPA: http://localhost:80 (or http://localhost:5173)
# Backend API:  http://localhost:3000/api/v1/health
```

### Verify End-to-End Health Check
```bash
# Direct API check
curl http://localhost:3000/api/v1/health

# Via Vite proxy
curl http://localhost:5173/api/v1/health
```
