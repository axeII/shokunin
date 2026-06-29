---
name: cluster-debug
description: Debug Kubernetes cluster issues using Radar MCP. Use when the user mentions pods crashing, OOMKills, failing deployments, unhealthy workloads, GitOps sync failures, Helm release errors, scheduling problems, image pull errors, readiness probes, resource usage, node issues, network problems, or any cluster troubleshooting. Also use for "check the cluster", "what's broken", "cluster health", and post-deploy verification.
license: MIT
compatibility: opencode
metadata:
  workflow: operations
  audience: devops
  version: "1.0"
  author: shokunin-lite
allowed-tools: Read Bash Write Grep Glob radar_issues radar_get_dashboard radar_search radar_diagnose radar_get_resource radar_get_cluster_audit radar_query_prometheus radar_get_changes radar_get_neighborhood radar_get_workload_logs radar_get_pod_logs radar_top_resources radar_list_helm_releases radar_get_helm_release radar_discover_metrics konflate_list_pull_requests konflate_get_pr_summary konflate_get_pr_diff
---

# Cluster Debug — Radar MCP + Konflate MCP

Systematic Kubernetes cluster debugging via Radar MCP (live cluster introspection)
and Konflate MCP (offline Flux diff rendering for PR review).

## Prerequisites

These MCP servers must be configured in `opencode.json`:

```json
{
  "mcp": {
    "radar": {
      "type": "remote",
      "url": "http://localhost:49412/mcp"
    },
    "konflate": {
      "type": "remote",
      "url": "https://konflate.juno.moe/mcp"
    }
  }
}
```

- **Radar MCP** — local agent that talks to your cluster's Kubernetes API and
  Prometheus. Start it before the session (runs on `localhost:49412` by default).
- **Konflate MCP** — hosted service that renders Flux PR diffs, blast radius,
  and image changes. No local setup needed.

## Triage cascade

Follow this order — start broad, narrow to a suspect, then drill down.

### 1. Start with `radar_issues` — "what's broken right now?"

```
radar_issues(namespace="<ns>")
```

Returns ranked failing resources with severity, cause, action, and remediation.
Use `filter=` with CEL to narrow: `'severity=="critical"'`,
`'category_group=="startup"'`. `issue_timing` tells you if the problem started
at creation or after the resource was healthy.

### 2. Overview with `radar_get_dashboard`

```
radar_get_dashboard(namespace="<ns>")
```

Resource counts, failing pods, unhealthy workloads, recent Warning events,
Helm release status. Use when you don't know which resource is the problem.

### 3. Unknown resource → `radar_search`

```
radar_search(query="error message or config key or image name")
```

Use modifiers: `kind:Pod`, `ns:foo`, `label:app=bar`, `image:redis`.

### 4. Drill into a suspect → `radar_diagnose`

```
radar_diagnose(kind="Deployment", namespace="<ns>", name="<name>")
```

Bundles: resource spec/status, current AND previous container logs across all
pods, recent Warning events, recent spec/config changes, startup blockers.
Also works for GitOps reconcilers (ArgoCD `Application`, Flux `Kustomization`
/ `HelmRelease`).

### 5. "This worked earlier" → `radar_get_changes`

```
radar_get_changes(namespace="<ns>", kind="Deployment", name="<name>", since="1h")
```

Recent spec/config changes with field-level diffs.

### 6. Cross-resource deps → `radar_get_neighborhood`

```
radar_get_neighborhood(kind="Service", namespace="<ns>", name="<name>")
```

BFS-expanded topology: service routing, selector/targetPort issues,
ConfigMap/Secret refs, owner chains.

### 7. CPU/memory → `radar_top_resources`

```
radar_top_resources(kind="pods", namespace="<ns>", sort="memory")
```

Live metrics with pod status, readiness, restarts, requests/limits context.

### 8. Config posture → `radar_get_cluster_audit`

```
radar_get_cluster_audit(namespace="<ns>")
```

Static posture: security (runAsRoot, privileged, hostPath), reliability (single
replicas, missing PDB), efficiency (missing requests/limits). **Separate from
live health** — don't conflate audit findings with runtime issues.

### 9. Metrics queries → `radar_query_prometheus` / `radar_discover_metrics`

```
radar_discover_metrics(match="{__name__=~\"container_memory.*\"}")
radar_query_prometheus(query="rate(container_cpu_usage_seconds_total[5m])")
```

Always `discover_metrics` first when unsure of metric names. Wrap high-
cardinality queries in `topk(5, ...)`.

### 10. Helm release debugging

```
radar_list_helm_releases(namespace="<ns>")
radar_get_helm_release(namespace="<ns>", name="<release>", include="history,operations")
```

## Konflate MCP — PR diff review

Available after a Flux PR has been rendered by Konflate:

```
konflate_list_pull_requests()                # List tracked PRs
konflate_get_pr_summary(number=42)           # Blast radius, cautions, image changes
konflate_get_pr_diff(number=42)              # Full rendered YAML diff
konflate_get_pr_diff(number=42, resource="r0")  # Single resource diff
```

Use during code review of Flux PRs to verify the rendered output matches
intent before merging.

## Important distinctions

| Tool | Answers |
|------|---------|
| `radar_issues` | What's broken RIGHT NOW (live state) |
| `radar_get_cluster_audit` | Is it configured CORRECTLY (static posture) |
| `radar_get_changes` | What changed recently |
| `radar_diagnose` | Full bundle for one workload |
| `konflate_get_pr_summary` | What a PR will do to the cluster |

**Never** report audit findings as "broken" or issues as "misconfigured."

## Post-change verification

1. `radar_issues(namespace="<ns>")` — confirm the issue cleared
2. `radar_get_dashboard(namespace="<ns>")` — verify overall health
3. Wait for `radar_diagnose(...)` to show the workload reaching Running

## Common pitfalls

- **Don't fetch all pod logs** — use `radar_diagnose` which bundles logs per
  workload.
- **Don't call `get_resource` for every pod** — use `radar_list_resources` or
  `radar_search` first.
- **Don't guess metric names** — use `radar_discover_metrics` first.
- **Don't confuse correlation with causation** — a pod restarting during a
  deploy doesn't mean the deploy caused it.
