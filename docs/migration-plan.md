# Artemis Dashboard Migration Plan

Porting the original `master` branch demo pages to the new `main` branch Phoenix 1.8 + LiveView app.

**Goal**: A clickable demo app that shows all the same pages as the original. We use real Ecto schemas, migrations, and contexts backed by SQLite. Data tables use the `slab` library. Detail pages use the existing `key_value_list` component. Once the first resource (Customers) is solid, we create a `mix igniter` generator to scaffold new resources quickly.

---

## What Already Exists in `main`

| Item | Status |
|------|--------|
| App layout (header, nav, mega-dropdowns, footer) | Done |
| `Layouts.page_header`, `page_nav`, `section`, `section_title` | Done |
| `key_value_list` component in `core_components.ex` | Done |
| Theme switcher (light/dark/system) | Done |
| Dashboard page (`/`) with summary counts + recent activity | Done |
| Components showcase (`/components`) | Done |
| `slab` dependency in `mix.exs` | Done |
| User auth (`phx.gen.auth` — Accounts context, User schema, login) | Done |
| Demo user auto-login (`Artemis.DemoUser`) | Done |

---

## Architecture Approach

### Real Backend, Stub Seeds

Unlike the original `master` which connected to external services (PagerDuty, Cloudant, etc.), we build real Ecto schemas + contexts but populate them with seed data. This gives us:

- Working CRUD when we add forms
- Realistic pagination and filtering via `slab`
- A codebase that's immediately extendable for real use cases

### The Igniter Generator

After the first resource (Customers) is refined, we build a `mix igniter` generator that creates:

- Ecto schema + migration
- Context module with list/get/create/update/delete
- LiveView index (with `slab` table) + show (with `key_value_list`)
- Router entries
- Seed data helper
- Tests

This makes adding subsequent resources (Clouds, Machines, etc.) fast and consistent.

---

## Pages to Port

Each page follows the same pattern from `master`:
- **Index**: page header with title + action button, optional tabs (Overview / Event Logs), breadcrumbs, `slab` data table with search + sort + pagination
- **Show**: page header with record name + Edit/Delete buttons, tabs (Overview / Event Logs / Comments), breadcrumbs, key-value details section, associated resource tables

### Priority 1 — Core Resource Pages (Build First, Refine, Then Generate)

| # | Page | Route | Columns / Fields | Notes |
|---|------|-------|-----------------|-------|
| 1 | Customers Index | `/customers` | name, clouds, data_centers, machine_count, actions | **Build first** — template pattern |
| 2 | Customer Show | `/customers/:id` | Name; associated clouds table | |
| 3 | Clouds Index | `/clouds` | name, customer, data_centers, machines, cpu, ram, actions | |
| 4 | Cloud Show | `/clouds/:id` | Name, Slug, Customer; associated machines table | |
| 5 | Data Centers Index | `/data-centers` | name, slug, customer_count, cloud_count, machine_count, cpu, ram, actions | |
| 6 | Data Center Show | `/data-centers/:id` | Name, Slug, Country, Latitude, Longitude; associated machines | |
| 7 | Machines Index | `/machines` | name, hostname, customer, cloud, data_center, actions | |
| 8 | Machine Show | `/machines/:id` | Name, Slug, Hostname, CPU, RAM, Customer, Cloud, Data Center | |
| 9 | Jobs Index | `/jobs` | id, name, status, type, started_at, completed_at, actions | Has status filter buttons |
| 10 | Job Show | `/jobs/:id` | Detail key-values | |

### Priority 2 — On Call / Incidents

| # | Page | Route | Columns / Fields | Notes |
|---|------|-------|-----------------|-------|
| 11 | On Call Overview | `/on-call` | Status cards / summary (stub PagerDuty-like data) | Unique layout — not a standard data table |
| 12 | Incidents Index | `/incidents` | source_uid, triggered_at, title, status, team, service, severity, tags, actions | Has date + status + team + service filters |
| 13 | Incident Show | `/incidents/:id` | Team, Tags, Status, Title, Service, Severity, Description, Source, Source UID; raw JSON section | |

### Priority 3 — Admin Pages

| # | Page | Route | Columns / Fields | Notes |
|---|------|-------|-----------------|-------|
| 14 | Users Index | `/users` | name, email, roles, last_log_in_at, actions | |
| 15 | User Show | `/users/:id` | Name, Email, Username, First Name, Last Name; teams table, roles table, permissions table | |
| 16 | Roles Index | `/roles` | name, description, user_count, actions | |
| 17 | Role Show | `/roles/:id` | Name, Slug, Description; users table, permissions table | |
| 18 | Permissions Index | `/permissions` | name, slug, actions | |
| 19 | Permission Show | `/permissions/:id` | Name, Slug, Description | |
| 20 | Features Index | `/features` | name, slug, active, actions | |
| 21 | Feature Show | `/features/:id` | Name, Slug, Active | |
| 22 | Event Logs Index | `/event-logs` | action, user, resource, timestamp, actions | |
| 23 | Event Log Show | `/event-logs/:id` | Action, User, Resource Type, Resource ID, timestamp; raw data | |
| 24 | Sessions Index | `/sessions` | session_id, user_name, inserted_at, actions | |
| 25 | Session Show | `/sessions/:id` | User, Entry Count, Duration, First Entry, Last Entry; timeline | |
| 26 | Tags Index | `/tags` | name, slug, type, actions | |
| 27 | Tag Show | `/tags/:id` | Type, Name, Slug | |
| 28 | Teams Index | `/teams` | name, description, user_count, actions | |
| 29 | Team Show | `/teams/:id` | Name, Description; team members table | |

### Priority 4 — Secondary Pages

| # | Page | Route | Notes |
|---|------|-------|-------|
| 30 | Search | `/search` | Full-page search with results grouped by resource type |
| 31 | Documentation (Wiki) Index | `/docs` | Grouped by section, tag-filtered |
| 32 | Documentation Show | `/docs/:id` | Rendered markdown content |

---

## What We Are NOT Porting

| Item | Reason |
|------|--------|
| PagerDuty client/driver | Seed fake on-call data |
| IBM Cloudant integration | Not needed |
| OAuth providers | Using magic link + password auth from `phx.gen.auth` |
| Event log real-time pub/sub system | Can add later if needed |
| Comments system | Future phase |
| Bulk actions (multi-select + batch ops) | Future phase |
| CSV/data export | Future phase |
| HTTP Request Logs page | Low value for demo |
| Application Config page | Internal tooling |
| System Tasks page | Internal tooling |
| Key Values (admin CRUD) page | Internal tooling |
| Wiki revision history | Future phase |
| Real-time presence indicators | Future phase |

---

## Implementation Plan

### Phase 1: Customer Resource (Template Pattern)

1. Generate migration + schema for `customers` table (name, notes, inserted_at, updated_at)
2. Create `Artemis.Customers` context (list, get, create, update, delete)
3. Build `ArtemisWeb.CustomersLive.Index` with `slab` table
4. Build `ArtemisWeb.CustomersLive.Show` with `key_value_list` + associated clouds stub
5. Add routes, update nav links
6. Add seed data (5-10 realistic customers)
7. Refine until the pattern feels right

### Phase 2: Build the Igniter Generator

Based on the patterns from Phase 1, create a `mix artemis.gen.resource` generator that scaffolds everything for a new resource.

### Phase 3: Generate Remaining Resources

Use the generator to quickly create all remaining pages. Hand-customize where needed (e.g., On Call overview has a unique layout, Incidents has custom filters).

### Phase 4: Cross-Links & Polish

- Wire up navigation between related resources (customer → clouds, cloud → machines, etc.)
- Ensure all mega-dropdown links work
- Add realistic seed data with proper relationships
- Polish empty states, loading states, responsive behavior

---

## Suggested Build Order (Detailed)

```
Phase 1 — Customers
  ├── mix ecto.gen.migration creates
  ├── lib/artemis/customers/customer.ex (schema)
  ├── lib/artemis/customers.ex (context)
  ├── lib/artemis_web/live/customers_live/index.ex
  ├── lib/artemis_web/live/customers_live/show.ex
  ├── priv/repo/seeds.exs (add customers)
  └── router.ex (add routes)

Phase 2 — Generator
  └── lib/mix/tasks/artemis.gen.resource.ex

Phase 3 — All Resources (via generator + customization)
  ├── Clouds (+ belongs_to Customer)
  ├── Data Centers
  ├── Machines (+ belongs_to Cloud, Data Center)
  ├── Jobs
  ├── Incidents
  ├── Users (extend existing)
  ├── Roles
  ├── Permissions
  ├── Features
  ├── Tags
  ├── Teams
  ├── Event Logs
  └── Sessions

Phase 4 — Special Pages
  ├── On Call Overview (custom layout)
  ├── Search (/search)
  └── Documentation (/docs)
```
