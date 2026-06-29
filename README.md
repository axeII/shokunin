# 職人 · Shokunin-lite

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![OpenCode](https://img.shields.io/badge/OpenCode-1.15-6B46C1)](https://opencode.ai)

> Simplified fork of [EliasOulkadi/shokunin](https://github.com/EliasOulkadi/shokunin). Fewer skills, focused on cluster ops and memory. Custom install that uses local `skills-lite/` directory.

> *職人 (shokunin) means artisan in Japanese. These skills aim for that standard: every detail crafted, every edge case handled, every workflow automated.*

## Skills

| Skill | Description |
|-------|-------------|
| **cluster-debug** | Debug Kubernetes clusters with Radar MCP + Konflate MCP. Systematic triage: issues → dashboard → diagnose → changes → neighborhood. |
| **docker** | Multi-stage builds, distroless bases, BuildKit cache, multi-arch, compose watch, security hardening, vulnerability scanning. |
| **kubernetes** | Deployments, Gateway API, service mesh (Istio/Linkerd/Cilium), eBPF, security hardening, Helm, HPA, PDB. |
| **senior-engineer** | Production-grade code standards: readable, correct, maintainable, secure, failure-aware. Always active for any coding task. |
| **arch-linux-triage** | Arch Linux troubleshooting and system recovery. |

### cluster-debug (Radar MCP + Konflate MCP)

This skill enables opencode to systematically debug cluster issues using two MCP servers:

**Radar MCP** — live cluster introspection. Talks to your Kubernetes API and
Prometheus to surface issues, diagnose workloads, query metrics, and trace
dependencies. Start it locally before your opencode session.

**Konflate MCP** — offline Flux PR diff rendering. Shows blast radius, image
changes, and rendered YAML diffs for Pull Requests before they hit the
cluster. Hosted service, no local setup.

The triage cascade the skill teaches:

1. `radar_issues` — "what's broken right now?" (failing resources ranked)
2. `radar_get_dashboard` — inventory overview (pods, workloads, events, Helm)
3. `radar_search` — find a resource by symptom
4. `radar_diagnose` — deep-dive into one workload (logs + events + changes)
5. `radar_get_changes` — "this worked earlier" investigations
6. `radar_get_neighborhood` — cross-resource dependency tracing
7. `radar_top_resources` — CPU/memory pressure
8. `radar_get_cluster_audit` — static config posture
9. `radar_query_prometheus` / `radar_discover_metrics` — PromQL queries
10. `radar_list_helm_releases` / `radar_get_helm_release` — Helm debugging
11. `konflate_list_pull_requests` / `konflate_get_pr_summary` / `konflate_get_pr_diff` — PR review

Configure the MCP servers in `opencode.json`:

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

Or use the install script to get prompted for these URLs.

## Commands

**OpenCode custom commands:** `/save` (save session to ChromaDB), `/load` (load previous session), `/status` (healthcheck).

**Linux:**
```bash
opencode                              # Start AI session (with memory capture)
./memory-healthcheck.sh               # Validate all memory components
gst, ga, gc "msg", gp, gl            # Git aliases
ni, nrd, nrb, nt                       # npm aliases
dps, dlog                               # Docker aliases
```

## Compatibility

The ecosystem works across multiple AI coding runtimes. The core (skills, memory, scripts) is runtime-agnostic. Only MCP server configuration and instruction files differ.

| Runtime | Skills | Memory | MCP | Config template |
|---------|--------|--------|-----|-----------------|
| **OpenCode** | ✅ Native | ✅ Native | ✅ `.pack/opencode.json` / `opencode.json.template` | Built-in |
| **Claude Code** | ✅ Reads SKILL.md | ✅ Via MCP | ✅ `.pack/templates/claude-code.json` | Copy template |
| **Cline** (VS Code) | ✅ Reads SKILL.md | ✅ Via MCP | ✅ `.pack/templates/cline-settings.json` | Add to settings.json |
| **Cursor** | ✅ Reads SKILL.md | ✅ Via rules | ✅ `.pack/templates/cursor-mcp.json` | Copy to .cursor/ |
| **Continue.dev** | ✅ Reads SKILL.md | ✅ Via rules | ✅ `.pack/templates/continue-config.yaml` | Copy to .continue/ |
| **Windsurf** | ✅ Reads SKILL.md | ✅ Via rules | ✅ `.pack/templates/windsurf-mcp.json` | Copy template |

## Install

```bash
git clone https://github.com/axeII/shokunin-lite.git
cd shokunin-lite
bash install.sh
```

The install script will:
1. Install OpenCode (if missing)
2. Install ChromaDB (persistent memory)
3. Copy skills from `skills-lite/` to `~/.config/opencode/skills/`
4. Configure opencode with memory, Radar MCP, and Konflate MCP
5. Add shell profile integration and weekly maintenance crontab

### Setup per runtime

**Claude Code:** Copy `.pack/templates/claude-code.json` to project root as `claude.json` or configure via CLAUDE.md.

**Cline:** Add the `mcpServers` block from `.pack/templates/cline-settings.json` to VS Code's `settings.json`. Copy `.pack/rules/cline-memory.md` as `.clinerules`.

**Cursor:** Configure MCP servers in Cursor Settings > MCP using `.pack/templates/cursor-mcp.json`. Copy `.pack/rules/cursor-memory.mdc` to `.cursor/rules/memory.mdc`.

**Continue.dev:** Copy `.pack/templates/continue-config.yaml` to `.continue/config.yaml`. Add `.pack/rules/continue-memory.md` to `.continue/rules/`.

**Windsurf:** Copy `.pack/templates/windsurf-mcp.json` MCP config. Copy `.pack/rules/windsurf-memory.md` to `.windsurf/rules/memory.md`.

## Links

- **Upstream** github.com/EliasOulkadi/shokunin
- **Upstream Website** eliasoulkadi.github.io/shokunin

## License

MIT free as in freedom, free as in zero cost.
