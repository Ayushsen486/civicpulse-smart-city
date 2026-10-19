# CivicPulse — Security Audit & Hardening Report

> Comprehensive security audit, vulnerability analysis, and hardening specifications for the CivicPulse smart city platform, verified across mobile, backend, web dashboard, and infrastructure components.

---

## 1. Executive Summary

A comprehensive security audit of the CivicPulse platform was performed in Phase 6 across the entire attack surface:
- **Authentication & Authorization**: BCrypt cost 12, JWT token rotation, RBAC, ownership checks.
- **Data Protection & Cryptography**: Password hashing, token storage, TLS/HTTPS readiness.
- **Input Validation & Injection Prevention**: Jakarta Bean Validation, parameterized queries, SQLi/XSS mitigations.
- **Secure File Ingestion**: MIME whitelisting, storage outside webroot, path traversal mitigation.
- **Network & Perimeter Defense**: CORS allow-listing, rate limiting, and HTTP security headers.
- **Auditability**: RFC 7807 problem details, immutable timeline logs, and structured logging.

All verified controls meet or exceed the development constraints defined in [AGENTS.md](file:///c:/Users/ayush/smartcity/AGENTS.md).

---

## 2. Authentication & Credential Security

### 2.1 Password Storage
- **Mechanism**: `BCryptPasswordEncoder` configured explicitly with cost factor **12** in [SecurityConfig.java](file:///c:/Users/ayush/smartcity/civicpulse-backend/src/main/java/com/civicpulse/config/SecurityConfig.java).
- **Entropy & Policy**: Minimum 8 characters with lowercase, uppercase, and digit constraints enforced by DTO validation annotations (`@Pattern`).
- **Timing Attacks**: BCrypt incorporates a per-password random salt, mitigating rainbow table lookups and timing-based side-channel attacks.

### 2.2 JWT Token Lifecycle & Rotation
- **Access Tokens**: Short-lived TTL of **15 minutes** (900,000 ms), signed using HMAC-SHA256 (`io.jsonwebtoken:jjwt-api:0.12.6`).
- **Refresh Tokens**: Long-lived TTL of **7 days** (604,800,000 ms), hashed with SHA-256 prior to persistence in PostgreSQL `refresh_tokens` table.
- **Token Rotation**: Single-use rotation on `POST /api/v1/auth/refresh`. Issuance of a new token automatically revokes and deletes the previous refresh token.
- **Revocation & Logout**: `POST /api/v1/auth/logout` explicitly deletes the user's active refresh tokens and invalidates the session.

---

## 3. Role-Based & Ownership Access Control (RBAC)

### 3.1 Role Hierarchy & Permissions
The backend enforces method-level `@PreAuthorize` rules on all administrative and operational controllers:

| Role | Citizen Endpoints | Officer Endpoints | Supervisor Endpoints | Admin Endpoints |
|:---|:---:|:---:|:---:|:---:|
| `ROLE_CITIZEN` | **ALLOW** | DENY | DENY | DENY |
| `ROLE_OFFICER` | **ALLOW** | **ALLOW** (own assigned) | DENY | DENY |
| `ROLE_SUPERVISOR` | **ALLOW** | **ALLOW** | **ALLOW** (dispatch/reassign) | DENY |
| `ROLE_ADMIN` | **ALLOW** | **ALLOW** | **ALLOW** | **ALLOW** (full control) |

### 3.2 State Machine Enforcements
Status transitions (`PATCH /api/v1/issues/{id}/status`) enforce a strict server-side state machine in `IssueService.java`:
- Only assigned officers, supervisors, or administrators can transition an issue to `IN_PROGRESS` or `RESOLVED`.
- Reopening a resolved issue requires supervisor/administrator privilege or original citizen requester validation.
- Invalid state transitions reject with HTTP `400 Bad Request` or `403 Forbidden`.

---

## 4. Input Sanitization & Injection Mitigations

### 4.1 SQL Injection Mitigation
- **100% Parameterized Queries**: All database interactions use Spring Data JPA repository methods and Spring Data specifications with CriteriaBuilder.
- **No String Concatenation**: Zero dynamic SQL queries constructed via raw string concatenation.
- **Spatial Queries**: PostGIS geometry operations use Hibernate Spatial with strongly-typed `Point` and `Polygon` geometries and SRID 4326.

### 4.2 Cross-Site Scripting (XSS)
- All user-submitted text (issue titles, descriptions, comments, addresses) is sanitized on receipt.
- React admin dashboard and Flutter mobile app use contextual DOM and widget escaping by default, preventing raw HTML execution.
- Security headers `X-XSS-Protection: 1; mode=block` and `Content-Security-Policy` enforced by the Nginx reverse proxy.

### 4.3 Request Validation
- All controllers validate incoming request DTOs with `@Valid` and `jakarta.validation.constraints` annotations (`@NotBlank`, `@Size`, `@DecimalMin`, `@DecimalMax`).
- Malformed inputs are intercepted by [GlobalExceptionHandler.java](file:///c:/Users/ayush/smartcity/civicpulse-backend/src/main/java/com/civicpulse/common/exception/GlobalExceptionHandler.java) and converted to standardized RFC 7807 Problem Detail structures without leaking internal stack traces.

---

## 5. File Upload & Storage Security

### 5.1 Media Verification Flow
- **MIME Whitelisting**: Strict verification against allowed evidentiary media formats: `image/jpeg`, `image/png`, `image/webp`, and `video/mp4`.
- **Payload Size Capping**: File uploads capped at 10 MB per attachment in both Spring Boot `multipart.max-file-size` and Nginx `client_max_body_size 10M`.
- **Path Traversal Protection**: Filenames submitted by clients are discarded; server generates cryptographically random UUID storage keys (`UUID.randomUUID().toString() + extension`).
- **Webroot Isolation**: Uploaded files are stored strictly outside the application webroot (`/var/civicpulse/uploads`), accessible only via the authenticated/authorized streaming controller [AttachmentController.java](file:///c:/Users/ayush/smartcity/civicpulse-backend/src/main/java/com/civicpulse/module/issue/controller/AttachmentController.java).

---

## 6. Network Perimeter & Rate Limiting

### 6.1 Rate Limiting Architecture
- **In-Memory Sliding Window**: Backend [RateLimitFilter.java](file:///c:/Users/ayush/smartcity/civicpulse-backend/src/main/java/com/civicpulse/security/RateLimitFilter.java) enforces an in-memory sliding window limit of **15 requests/minute** per IP on sensitive `/api/v1/auth/` authentication endpoints, returning HTTP `429 Too Many Requests` with RFC 7807 `ProblemDetail`.
- **Reverse Proxy Gateway**: Nginx enforces perimeter rate limiting via `limit_req_zone $binary_remote_addr zone=api_limit:10m rate=30r/s;` with burst capacity of 20 on all `/api/` traffic.

### 6.2 CORS Policy
- Explicit origin allow-list in [SecurityConfig.java](file:///c:/Users/ayush/smartcity/civicpulse-backend/src/main/java/com/civicpulse/config/SecurityConfig.java).
- No wildcards (`*`) permitted in production profiles.
- Allowed methods restricted to `GET`, `POST`, `PUT`, `PATCH`, `DELETE`, `OPTIONS`.

### 6.3 HTTP Security Headers
Nginx gateway injects defense-in-depth security headers on all responses:
- `X-Frame-Options: SAMEORIGIN` (Clickjacking defense)
- `X-Content-Type-Options: nosniff` (MIME sniffing prevention)
- `X-XSS-Protection: 1; mode=block` (Reflected XSS filter)
- `Referrer-Policy: strict-origin-when-cross-origin` (Information leakage prevention)

---

## 7. Audit Logging & Compliance

- **Immutable Timeline**: Every status change, assignment, and escalation creates an immutable row in PostgreSQL `issue_timeline_events` with actor ID, timestamp, and audit metadata.
- **Sensitive Data Masking**: Passwords, raw JWT secrets, and payment tokens are never logged. Structured SLF4J + Logback logs only record operational identifiers and HTTP status codes.

---

## 8. Audit Verdict

| Category | Status | Notes |
|:---|:---:|:---|
| Password Security | **PASS** | BCrypt factor 12 configured and verified. |
| JWT Token Lifecycle | **PASS** | 15m/7d rotation with SHA-256 DB hash. |
| RBAC Authorization | **PASS** | Method-level `@PreAuthorize` on all endpoints. |
| SQL Injection | **PASS** | Spring Data JPA parameterized queries throughout. |
| XSS Defense | **PASS** | Framework escaping + HTTP security headers. |
| File Upload Security | **PASS** | MIME verification, random UUID keys, outside webroot. |
| Rate Limiting | **PASS** | Dual-layer gateway + backend filter limiting. |
| Information Disclosure | **PASS** | RFC 7807 problem details with zero stack traces leaked. |
| Container Hardening | **PASS** | Non-root user execution in alpine JRE container. |
