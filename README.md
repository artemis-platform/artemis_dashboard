# Artemis Dashboard

> An Operational Dashboard in Elixir and Phoenix

Artemis Dashboard is built on top of [Artemis Platform](https://github.com/chrislaskey/artemis_platform), a collection of production-ready design patterns for Elixir and Phoenix.

[![Build Status](https://travis-ci.com/chrislaskey/artemis_dashboard.svg?branch=master)](https://travis-ci.com/chrislaskey/artemis_dashboard)

## Patterns

General Patterns:

- Authentication with OAuth2
- Role-Based Access Control [⬈ Documentation](https://github.com/chrislaskey/artemis_platform/wiki/Role-Based-Access-Control) [⬈ Discussion](https://github.com/chrislaskey/artemis_platform/issues/12)
- Full Text Search [⬈ Documentation](https://github.com/chrislaskey/artemis_platform/wiki/Full-Text-Search) [⬈ Discussion](https://github.com/chrislaskey/artemis_platform/issues/13)
- Event Based Pub/Sub
- Dedicated Audit Logging
- Feature Flipper
- GraphQL API Endpoint
- Phoenix Web Endpoint
- Docker Support
- Unit Testing
- Browser-based Feature Testing

UI Patterns:

- Breadcrumbs
- Pagination
- Table Search

In Flight:

- Optional RabbitMQ Support
- On-demand Caching

Planned:

- Node Clustering
- Table Sorting
- Table Filtering
- Table Export

## Demo

A container-based demo environment is available. Assuming [docker](https://www.docker.com/) and [docker compose](https://docs.docker.com/compose/) is installed:

```bash
bin/demo/build # Build the demo environment
bin/demo/up # Start the demo environment
bin/demo/stop # Stop the demo environment
bin/demo/remove # Remove the demo environment
```

## Looking for More?

> ### [Artemis Platform](https://github.com/chrislaskey/artemis_platform)

Artemis Platform is a generic Elixir / Phoenix platform ready to be the foundation of your next web application.

> ### [Artemis Teams](https://github.com/chrislaskey/artemis_teams)

Collaborative Team-Based Tools written in Elixir and Phoenix.
