# test project terner - Design Document

## Project Overview

This is the freshly scaffolded Aether starter app for **test project terner**. The
project brief has not yet been filled in — the `## Vision` section below is a
placeholder. Until a vision is provided, the app ships with the standard Aether
starter UI: a getting-started landing page, the global app header / settings
dialog, the AI agent chat page, the Lovelace platform server-status banner, and
the prefs / tenancy probe debug pages.

To customize this app:

1. Edit the `## Vision` section below with what you want to build.
2. Re-run `/build_my_app` in Cursor — the agent will read this doc, plan the
   pages and components, and implement them on top of this starter.

**Created:** 2026-06-11
**App ID:** test-project-terner
**Description:** Aether app: test project terner
**Last updated:** 2026-06-11

## Vision

_To be filled in by the project owner. Describe what this app should do, who
the users are, and what data / workflows it should surface from the Lovelace
platform (entities, news, filings, sentiment, relationships, events). Once
this section is non-empty, run `/build_my_app` to scaffold pages and
components against it._

## Configuration

| Setting        | Value                                               |
| -------------- | --------------------------------------------------- |
| Hosting        | GKE (per-tenant cluster, BC 2.0)                    |
| Authentication | Auth0                                               |
| Query Server   | https://query.pip.prod.g.lovelace.ai                |
| Agent hosting  | GKE (in-cluster, BC 2.0)                            |
| Live URL       | https://ui.test-project-terner.tenant.g.lovelace.ai |

Tenant settings live in `broadchurch.yaml` and should not be edited by hand.

## Implementation Status

| Area                         | Status              | Notes                                                                                                                  |
| ---------------------------- | ------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| Initial scaffold             | ✅ Built & verified | `npm install` + `npm run build` succeed on the freshly initialized project.                                            |
| Vision / product brief       | ⏳ Pending          | `## Vision` above is a placeholder.                                                                                    |
| Pages                        | 🟡 Starter only     | `pages/index.vue` (getting started), `pages/chat.vue` (agent chat), `pages/prefs-demo.vue`, `pages/tenancy-probe.vue`. |
| Components                   | 🟡 Starter only     | App header, settings dialog, server status, notifications, page header, chat message.                                  |
| Composables                  | 🟡 Framework only   | Standard Aether composables for prefs, schema, theme, session, notifications.                                          |
| Server routes (`server/api`) | 🟡 Framework only   | Auth0, prefs, KV, platform status, tenancy probe.                                                                      |
| Agents (`agents/`)           | ⏳ None deployed    | `agents/example_agent` is a template — it is not deployed.                                                             |
| MCP servers (`mcp-servers/`) | ⏳ None deployed    | Add only if the vision needs custom tool servers.                                                                      |
| Compute jobs / workflows     | ⏳ None             | Add only if the vision needs scheduled or batch work.                                                                  |

## Cross-Cutting Concepts

_None yet — populate as features are added (e.g. shared scoring composables,
common entity-resolution helpers, brand styling overrides)._

## Pages

### Home (`/`)

Name: Home / Getting Started
Route: `/`
Description: Default Aether starter landing page. Replace with the app's primary view once the vision is defined.
Implementation status: Starter placeholder.
Details: Hero with app name, three-step getting-started checklist (edit DESIGN.md → run `/build_my_app` → push to deploy).

### Agent Chat (`/chat`)

Name: Agent Chat
Route: `/chat`
Description: Generic chat UI for talking to a deployed ADK agent via the `useAgentChat` composable.
Implementation status: Starter placeholder, wired but no app-specific agent yet.
Details: Becomes useful once an agent is deployed (`/deploy_agent` for Agent Engine; auto-deploys on push for GKE).

### Prefs demo (`/prefs-demo`)

Name: Prefs Demo
Route: `/prefs-demo`
Description: Debug page demonstrating per-tenant prefs round-tripping (`useAppPrefs` / `useGlobalPrefs`).
Implementation status: Framework demo.

### Tenancy probe (`/tenancy-probe`)

Name: Tenancy Probe
Route: `/tenancy-probe`
Description: Debug page that exercises the platform data plane (Query Server, prefs backend, etc.) for the current tenant.
Implementation status: Framework debug tool.

### Page Template

Name:
Route:
Description:
Implementation status:
Details:
