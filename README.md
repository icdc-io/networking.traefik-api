# ⚙️ Traefik Manager API (`traefik-api`)

`traefik-api` is an **API-only Rails** service that exposes a management API for an **Application Load Balancer (ALB)** built on **Traefik**.

---

## 🚀 Overview

- Rails API for operating a Traefik-based ALB: manage gateways, routes, and certificates, and generate Traefik configuration.
- Supports **HTTP** and **TCP** routes.
- Secure routes support TLS termination (**edge** / **re-encrypt** for HTTP, **passthrough** for TCP) and an insecure HTTP policy (**allow** / **redirect**).

OpenAPI: `doc/openapi.yml`.

---

## 🧱 Tech Stack

| Category | Technology |
|---|---|
| Language | Ruby `3.2.9` |
| Framework | Rails `~> 8.0.2` (API-only) |
| Database | PostgreSQL |
| Queue/Jobs | Sidekiq (`sidekiq-cron`) |
| AuthN/AuthZ | Authorization via headers, RBAC (`rbac-ruby`) |
| Testing | RSpec |
| Static analysis | RuboCop |

---

## 🔐 Auth & Headers

Requests must include the following headers:

- **`X-Auth-User`**: username
- **`X-Auth-Account`**: account name
- **`X-Auth-Role`**: role name

Authorization is enforced via RBAC rules configured by `ROUTES_MAP_FILE` (defaults to `./config/rbac/rbac_routes.yml`).

---

## ⏱️ Scheduled jobs (Sidekiq Cron)

Cron jobs are configured in `config/schedule.yml` (e.g. `LoadServicesJob`).

Sidekiq UI is mounted at **`/sidekiq`** (see `config/routes.rb`).

---

## 🧑‍💻 Local Development

### 1) Install dependencies

```bash
bundle install
```

### 2) Configure environment variables

You can keep local environment variables in a `.env` file (database, Redis, external services credentials if needed).

### 3) Create and migrate the database

```bash
bin/rails db:create
bin/rails db:migrate
```

### 4) Run API

```bash
bin/rails server
```

### 5) Run Sidekiq (optional)

```bash
bundle exec sidekiq
```

---

## ✅ Tests & Quality

### RSpec

```bash
bundle exec rspec
```

### RuboCop / Reek / Brakeman

```bash
bin/rubocop
bundle exec reek .
bundle exec brakeman
```

---

## 🔍 CI pipeline (GitLab)

Configured in `.gitlab-ci.yml`:

- **gitleaks** (stage `code_audit`): secret detection, artifact `report.json`
- **build**: build & push container image (Podman)
- **rubocop / reek / brakeman / rspec**: quality checks and tests
