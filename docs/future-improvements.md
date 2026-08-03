# Future Improvements

Ideas for enhancing the Artemis Dashboard beyond the initial faithful port. These are not in scope for the current phase but are worth tracking for iteration.

---

## UI/UX Enhancements

### Search Experience
- **Command palette (Cmd+K)**: Replace the `/search` page with a modal command palette that searches across all resources. More modern UX than a full-page redirect.
- **Recent searches**: Show recently accessed resources in the search modal.
- **Fuzzy matching**: Client-side fuzzy search across stub data for instant results.

### Dashboard Page
- **Sparkline charts**: Add small inline trend charts to the summary count cards (e.g., machines added this week).
- **Customizable widgets**: Let users drag/reorder dashboard sections.
- **Data center map**: Port the original world map visualization showing data center locations (use a lightweight library like Leaflet or a static SVG map).

### Data Tables
- **Column pinning**: Allow pinning the name/actions columns while scrolling horizontally.
- **Saved views**: Let users save filter + column + sort configurations.
- **Inline editing**: Double-click a cell to edit in place (once forms are added).
- **Row expansion**: Click to expand a row and see additional details without navigating to the show page.

### Navigation
- **Keyboard shortcuts**: Global hotkeys for common navigation (g+c for customers, g+u for users, etc.).
- **Recently visited**: A "recent" section in the nav showing last 5 visited resources.
- **Sidebar navigation option**: Some users preferred the sidebar nav from the original. Could offer both layouts.

### Detail Pages
- **Tabs as LiveView patches**: Use `patch` navigation for tabs (Overview/Event Logs/Comments) so they don't do full page loads.
- **Activity timeline**: Show a chronological activity feed on each resource's detail page.
- **Related resource cards**: Show associated resources as linked cards instead of just tables.

---

## Functional Enhancements

### Forms & CRUD
- **New/Edit forms**: Add create and edit forms for all resources with LiveView `phx-change` validation.
- **Delete confirmation modal**: Replace browser `confirm()` with a styled modal.
- **Bulk operations**: Multi-select rows + bulk actions (delete, update status, assign).

### Comments System
- **Threaded comments**: Add a comments section to each resource's show page.
- **Markdown support**: Render comment content as markdown.
- **@mentions**: Mention other users in comments.

### Real-time Features
- **Live presence**: Show which users are viewing the same resource.
- **Live updates**: PubSub-driven table updates when resources change.
- **Notifications**: Real-time notification bell with a dropdown.

### Export & Reporting
- **CSV export**: Export any data table to CSV.
- **PDF reports**: Generate summary reports for customers/clouds.
- **Scheduled reports**: Email periodic summaries.

---

## Technical Improvements

### Backend
- **API layer**: JSON API for programmatic access.
- **Background jobs (Oban)**: For async operations, imports, syncs.
- **Richer seed data generator**: Script that creates interconnected demo data with realistic volumes.

### Performance
- **LiveView streams**: Already using for collections, but could add virtual scrolling for very large lists.
- **Caching**: Cache expensive computations or external API calls.
- **Lazy loading**: Load associated resources on-demand (click to expand).

### Testing
- **LiveView integration tests**: Test all pages render correctly with stub data.
- **Visual regression tests**: Screenshot-based tests to catch UI drift.
- **Accessibility audit**: Ensure proper ARIA labels, keyboard nav, contrast ratios.

### Developer Experience
- **Storybook**: Component gallery (already have `/components`, could expand).
- **Design tokens**: Extract color/spacing values into a token system.
- **Dark mode polish**: Ensure all custom components look great in dark mode.

---

## Content & Data

### Richer Demo Data
- **Realistic names**: Use industry-relevant naming (cloud provider names, real city data centers, etc.).
- **Consistent relationships**: Ensure cross-references tell a coherent story (Customer A → Cloud X → Data Center Y → Machines 1-20).
- **Time-series data**: Stub event logs with realistic timestamps spread over days/weeks.

### Documentation Pages
- **Real content**: Write actual helpful documentation pages (onboarding guide, architecture overview, API docs).
- **Tagging system**: Categorize docs by topic and audience.

---

## Generator Enhancements

Once the `mix artemis.gen.resource` igniter generator is built, it could be extended:

- **Form generation**: Generate new/edit forms with all fields pre-wired
- **Filter generation**: Auto-generate filter UI based on schema field types
- **Relationship UI**: Auto-detect belongs_to/has_many and generate linked tables on show pages
- **Test generation**: Auto-generate LiveView integration tests for index + show
- **Component variants**: Generate with different table styles (compact, expanded, card-based)

---

## Design System

### Component Library Expansion
- **Toast notifications**: Richer notification system with different severities and auto-dismiss.
- **Modal system**: Reusable modal component for confirmations, forms, search.
- **Dropdown menus**: Context menus on right-click for table rows.
- **Empty states**: Illustrated empty states for each resource type.
- **Loading skeletons**: Shimmer placeholders while data loads.
- **Avatar component**: User avatars with initials fallback (already partially done).

### Theming
- **Multiple themes**: Beyond light/dark — offer brand-customizable themes.
- **High contrast mode**: Accessibility-focused high contrast option.
- **Compact mode**: Denser layout option for power users.
