# CivicPulse — Operations & Triage Web Dashboard

The web management portal for municipal administrators, supervisors, and field officers to triage, dispatch, and resolve citizen complaints, powered by the CivicPulse Spring Boot REST API.

---

## 1. Tech Stack & Architecture

- **Framework**: React 19 + TypeScript (strict mode)
- **Build Tool**: Vite 8
- **Styling**: Tailwind CSS v4 with custom municipal design tokens
- **Routing**: React Router v7 with role-based route protection
- **State Management**: Zustand (`authStore`) for authentication and session state
- **HTTP Client**: Axios with centralized request/response interceptors and silent JWT token rotation
- **Forms & Validation**: React Hook Form with Zod schemas
- **Icons**: Lucide React
- **Testing**: Vitest + React Testing Library + jsdom

---

## 2. Directory Layout

```
civicpulse-admin/
├── src/
│   ├── api/
│   │   ├── client.ts             # Centralized Axios instance with 401 refresh interceptor
│   │   └── index.ts              # Typed API modules (auth, issues, categories, wards, officers, intelligence)
│   ├── components/
│   │   ├── layout/               # Navbar, Sidebar, DashboardLayout, ProtectedRoute
│   │   └── ui/                   # Badges, Button, Card, Modal, LocationCard, LoadingSpinner
│   ├── pages/
│   │   ├── Login.tsx             # Staff authentication (rejects citizens)
│   │   ├── Dashboard.tsx         # Operational overview with real-time KPI metrics
│   │   ├── IssuesList.tsx        # Filterable complaint table with dispatch and triage actions
│   │   ├── IssueDetail.tsx       # Full complaint workspace, map, timeline, notes & Phase 3 AI review
│   │   ├── Officers.tsx          # Field personnel directory and dispatch queue
│   │   ├── Categories.tsx        # Administrative taxonomy & resolution SLA editor
│   │   └── Wards.tsx             # Administrative municipal ward & boundary WKT manager
│   ├── store/
│   │   └── authStore.ts          # Zustand store with role-based validation
│   ├── test/
│   │   ├── setup.ts              # Testing setup with jsdom localStorage mock
│   │   ├── authStore.test.ts     # Auth & permission unit tests
│   │   ├── Badge.test.tsx        # UI badge tests
│   │   ├── Login.test.tsx        # Authentication UI test
│   │   ├── IssuesList.test.tsx   # Table and filtering tests
│   │   └── IssueDetail.test.tsx  # Workspace and AI review tests
│   ├── types/                    # Domain TypeScript declarations (auth, issue, category, ward, intelligence)
│   ├── App.tsx                   # Main routing definition
│   └── main.tsx                  # Application entry point
├── package.json
└── vite.config.ts
```

---

## 3. Role-Based Permissions & Access Control

The portal enforces access controls aligned with backend `@PreAuthorize` rules:

| Portal Section | URL | Permitted Roles | Notes |
|:---|:---|:---|:---|
| **Login** | `/login` | Public | Rejects `CITIZEN` accounts with an explicit restriction message. |
| **Overview** | `/dashboard` | `OFFICER`, `SUPERVISOR`, `ADMIN` | Real-time counts, status breakdown, urgent hazard alerts. |
| **Issues List** | `/issues` | `OFFICER`, `SUPERVISOR`, `ADMIN` | Filters by status, priority, category, ward, and keyword. |
| **Issue Detail** | `/issues/:id` | `OFFICER`, `SUPERVISOR`, `ADMIN` | Full complaint details, embedded OpenStreetMap, timeline, comments. |
| **AI Copilot Review** | `/issues/:id` | `OFFICER`, `SUPERVISOR`, `ADMIN` | 1-click Accept, Reject, or Override AI suggestion. |
| **Field Officers** | `/officers` | `SUPERVISOR`, `ADMIN` | Personnel availability directory. |
| **Categories & SLAs** | `/categories` | `ADMIN` | CRUD for taxonomy and SLA hours. |
| **Wards & Boundaries**| `/wards` | `ADMIN` | CRUD for municipal wards and PostGIS polygons. |

---

## 4. Phase 3 AI Intelligence Integration

The dashboard directly communicates with the Phase 3 backend intelligence module:
- **Display**: Presents suggested category, assessed priority score, recommended municipal department, and triage explanation.
- **Human Review Flag**: Displays amber escalation warning when safety hazards are flagged for supervisor attention.
- **Review Actions**:
  - `Accept`: Updates the complaint's category and priority, recalculates SLA deadlines, and records an immutable timeline audit event.
  - `Reject`: Flags the suggestion as rejected with reviewer details.
  - `Override`: Allows staff to select custom category, priority, and department with audit remarks.
- **History Modal**: Audits past suggestions and reviewer actions via `/api/v1/issues/{id}/intelligence/history`.

---

## 5. Security & Refresh Token Handling

- **Authentication**: JWT Bearer tokens injected into all outgoing API requests.
- **Token Rotation**: 401 interceptor automatically calls `POST /api/v1/auth/refresh` using refresh token, retrying failed requests transparently.
- **Browser Security Note**: In this implementation, tokens are stored in `localStorage` for cross-tab persistence. For strict defense-in-depth against XSS in production web browsers, backend support for `Set-Cookie: refreshToken=...; HttpOnly; SameSite=Strict; Secure` is recommended.

---

## 6. Development & Testing Commands

Ensure backend is running at `http://localhost:8080`:

```bash
# Install dependencies
npm install

# Run development server (http://localhost:3000)
npm run dev

# Run Vitest automated test suite
npm test

# Run TypeScript check and production build
npm run build
```
