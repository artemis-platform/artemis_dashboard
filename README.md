# Artemis Dashboard

> An Operational Dashboard in Elixir and Phoenix

Artemis Dashboard is built on top of [Artemis Platform](https://github.com/chrislaskey/artemis_platform), a collection of production-ready design patterns for Elixir and Phoenix.

[![Build Status](https://travis-ci.com/chrislaskey/artemis_dashboard.svg?branch=master)](https://travis-ci.com/chrislaskey/artemis_dashboard)

## Patterns

General Patterns:

- Authentication with OAuth2
- Role-Based Access Control
- Full Text Search
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

## Looking for a Generic Platform?

> ### [Artemis Platform](https://github.com/chrislaskey/artemis_platform)

Artemis Platform is a generic platform ready to be the foundation of your next web application.

## Development

Artemis can be used as a pattern reference for an existing application or as a starting point for a new one.

To build a new application using Artemis, see the [`DEVELOPMENT.md`](DEVELOPMENT.md).
