# Artemis Dashboard Migration Plan

Porting the original `master` branch demo pages to the new `main` branch Phoenix 1.8 + LiveView app.

**Goal**: A clickable demo app that shows all the same pages as the original, using stub data in LiveViews (no backend contexts, no external service clients). Data tables use the `slab` library. Detail pages use the existing `key_value_list` component.

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
| `slab` dependency in `mix.exs` | Added |

---

## Pages to Port

Each page follows the same pattern from `master`:
- **Index**: page header with title + action button, optional tabs (Overview / Event Logs), breadcrumbs, data table with search + pagination
- **Show**: page header with record name + Edit/Delete buttons, tabs (Overview / Event Logs / Comments), breadcrumbs, key-value details section, associated resource tables

We will stub all data directly in the LiveView module (no Ecto schemas or DB needed).

### Priority 1 — Core Resource Pages

These are the most-used pages and represent the primary navigation flow.

| # | Page | Route | Columns / Fields | Notes |
|---|------|-------|-----------------|-------|
| 1 | Customers Index | `/customers` | name, clouds, data_centers, machine_count, actions | Standard data table |
| 2 | Customer Show | `/customers/:id` | Name; associated clouds table | |
| 3 | Clouds Index | `/clouds` | name, customer, data_centers, machines, cpu, ram, actions | |
| 4 | Cloud Show | `/clouds/:id` | Name, Slug, Customer; associated machines table | |
| 5 | Data Centers Index | `/data-centers` | name, slug, customer_count, cloud_count, machine_count, cpu, ram, actions | |
| 6 | Data Center Show | `/data-centers/:id` | Name, Slug, Country, Latitude, Longitude; associated machines | |
| 7 | Machines Index | `/machines` | name, hostname, customer, cloud, data_center, actions | |
| 8 | Machine Show | `/machines/:id` | Name, Slug, Hostname, CPU, RAM, Customer, Cloud, Data Center | |
| 9 | Jobs Index | `/jobs` | id, name, status, type, started_at, completed_at, actions | Has status filter buttons |
| 10 | Job Show | `/jobs/:id` | Detail key-values (stub) | |

### Priority 2 — On Call / Incidents

| # | Page | Route | Columns / Fields | Notes |
|---|------|-------|-----------------|-------|
| 11 | On Call Overview | `/on-call` | Status cards / summary (stub PagerDuty-like data) | Unique layout, not a standard data table |
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

These existed in `master` but are unnecessary for the visual demo:

| Item | Reason |
|------|--------|
| Backend contexts (`Artemis.ListCustomers`, etc.) | Using stub data instead |
| Ecto schemas and migrations | No DB needed for demo |
| PagerDuty client/driver | Stub the on-call data |
| IBM Cloudant integration | Not needed |
| Authentication (OAuth, sessions) | No real auth for demo |
| Permission/authorization system | All pages visible |
| Event log real-time system (pub/sub) | Stub data |
| Comments system | Skip for now (future phase) |
| Bulk actions | Skip for demo |
| CSV/data export | Skip for demo |
| HTTP Request Logs page | Low value for demo |
| Application Config page | Internal tooling, skip |
| System Tasks page | Internal tooling, skip |
| Key Values (admin CRUD) | Internal tooling, skip |
| Wiki revision history | Skip for demo |
| Real-time presence indicators | Skip for demo |
| Form pages (new/edit) | Future phase — focus on read-only views first |

---

## Implementation Approach

### LiveView Structure

Each resource gets a single LiveView module with multiple clauses:

```
lib/artemis_web/live/
├── customers_live/
│   ├── index.ex        # List view with slab table
│   └── show.ex         # Detail view with key_value_list
├── clouds_live/
│   ├── index.ex
│   └── show.ex
├── data_centers_live/
│   ├── index.ex
│   └── show.ex
...
```

### Shared Patterns

1. **Index pages**: Use `slab` for the data table (search, sort, pagination). Stub data defined as module attributes.
2. **Show pages**: Use `Layouts.section` + `Layouts.section_title` + `key_value_list`. Associated resources shown in secondary `slab` tables.
3. **Page headers**: Use `Layouts.page_header` with title, action buttons slot, and tabs slot.
4. **Breadcrumbs**: Use `Layouts.page_nav` with home icon + path segments.
5. **Navigation**: Update router with all routes. Existing mega-dropdown links already point to the correct paths.

### Stub Data Strategy

Each LiveView defines its stub data as `@module_attributes` — simple maps with the fields needed for display. IDs are integers 1-N. Cross-resource references use matching IDs (e.g., a machine's `cloud_id: 1` corresponds to cloud with `id: 1`).

### Slab Integration

Use `slab` for all list pages:
- Define columns with labels, sort keys, and render functions
- Stub data passed as the collection
- Built-in search filtering on client-side stub data
- Built-in pagination (page size ~15-25 per resource)

---

## Suggested Build Order

1. Set up a shared stub data module (`ArtemisWeb.StubData`) so resources can cross-reference
2. Build one complete index+show pair (Customers) as the template pattern
3. Port remaining Priority 1 pages (Clouds, Data Centers, Machines, Jobs)
4. Port Priority 2 (On Call, Incidents)
5. Port Priority 3 (Admin pages — these are repetitive, fast to build once pattern is set)
6. Port Priority 4 (Search, Docs)
7. Wire up all cross-links (e.g., cloud show → customer link, machine show → cloud link)
