# ACME Salary Management Frontend (React + Vite)

The frontend Single Page Application (SPA) for ACME Salary Management, built on React 18, Vite, Material UI (MUI), Bootstrap 5.3 utilities, and an Obsidian Executive Tier glassmorphism design system.

---

## 1. Application Pages & Components

### 1. Senior HR Executive Suite (`src/pages/HrSuitePage.jsx`)
- **Desk 1: Form 16 & Dual Tax Regime Optimizer**: Interactive sliders for gross salary, 80C, 80D, HRA, 24(b), and NPS with live New vs Old regime winner card and slab-by-slab tax breakdown.
- **Desk 2: Gratuity & Full and Final (F&F) Settlement Desk**: Calculates 5-year vested statutory gratuity under Payment of Gratuity Act 1972, earned leave cash-out, and notice recoveries with printable certified statement.
- **Desk 3: Executive CTC Structure & Retiral Liabilities**: Decomposes CTC into Component A (Gross), Component B (Employer Retirals), Component C (Diwali Bonus), and net in-hand monthly take-home.
- **Desk 4: Annual Merit Appraisal & Bell-Curve Manager**: Normal distribution matrix (Bands 1 to 5) with merit pool budget tracking.
- **Desk 5: Statutory Compliance & Legal Audit Radar**: Automated compliance registry for EPFO ECR, ESIC, PT, TDS 24Q, and Gratuity Trust.

### 2. Payslips & Monthly Payroll (`src/pages/PayslipsPage.jsx`)
- 1-Click batch payroll generation for 10,000 employees.
- 1-Click batch email dispatch with delivery status tracking.
- Indian corporate salary slip modal (`PayslipModal.jsx`) with PAN, TAN, CIN, UAN, and verbal Rupee amounts.

### 3. AI Compensation & Retention Intelligence (`src/pages/AiAdvisorPage.jsx`)
- Flight-risk radar identifying at-risk talent against Indian market 75th percentiles.
- Interactive merit raise simulator with take-home pay impact.

### 4. Compensation Analytics (`src/pages/AnalyticsPage.jsx`)
- Departmental and regional compensation charts strictly formatted in Indian Rupees (`₹ INR`) with Lakhs and Crores notations.

### 5. Employee Directory & Revisions (`src/pages/EmployeeDirectoryPage.jsx`)
- Search, filter, and pagination for 10,000 records.
- Effective-dated salary revision dialog with audit justification.

---

## 2. Design System & Aesthetics (`src/index.css`)

- **Obsidian Space Canvas**: `#04070d` with ambient radial gradients (`#38bdf8`, `#10b981`, `#c084fc`).
- **Tabular Figures**: `font-variant-numeric: tabular-nums` for precise alignment of financial data.
- **Executive Badges**: Micro-animated live status beacons, glowing emerald/cyan cards, and gold director tier badges.

---

## 3. Local Development & Testing

```bash
# Install dependencies
npm install

# Run automated tests (9 tests, 100% pass)
npm test -- --run

# Build production bundle
npm run build

# Start Vite dev server on port 5173
npm run dev -- --host 0.0.0.0 --port 5173
```
