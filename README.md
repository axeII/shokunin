# 職人 · Shokunin-lite

[![CI](https://github.com/EliasOulkadi/shokunin/actions/workflows/ci.yml/badge.svg)](https://github.com/EliasOulkadi/shokunin/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![OpenCode](https://img.shields.io/badge/OpenCode-1.15-6B46C1?logo=openai)](https://opencode.ai)
[![Maintenance](https://img.shields.io/badge/Maintained%3F-yes-green.svg)](https://github.com/EliasOulkadi/shokunin/graphs/commit-activity)

> **Note**: This is a fork I call shokunin-lite. It's much simplier fork. It just installs memeory and few skills. For my own usecase right now.

> *職人 (shokunin) means artisan in Japanese. These skills aim for that standard: every detail crafted, every edge case handled, every workflow automated.*


## Commands

**OpenCode custom commands:** `/save` (save session to ChromaDB), `/load` (load previous session), `/status` (healthcheck).

**Windows:**
```powershell
.\run-opencode.ps1                    # Start AI session (with memory capture)
opencode                              # Start AI session (simple mode)
.\memory-healthcheck.ps1              # Validate all memory components
gst, ga, gc "msg", gp, gl            # Git aliases
ni, nrd, nrb, nt                       # npm aliases
dps, dlog                               # Docker aliases
mkcd, touch, which, admin             # Utility aliases
```

**Linux:**
```bash
opencode                              # Start AI session (with memory capture)
./memory-healthcheck.sh               # Validate all memory components
gst, ga, gc "msg", gp, gl            # Git aliases
ni, nrd, nrb, nt                       # npm aliases
dps, dlog                               # Docker aliases
mkcd, which                           # Utility functions
```

## Compatibility

The ecosystem works across multiple AI coding runtimes. The core (skills, memory, scripts) is runtime-agnostic. Only MCP server configuration and instruction files differ.

| Runtime | Skills | Memory | MCP | Scripts | Config template |
|---------|--------|--------|-----|---------|-----------------|
| **OpenCode** | ✅ Native | ✅ Native | ✅ .pack/opencode.json | ✅ .ps1 + .sh | Built-in |
| **Claude Code** | ✅ Reads SKILL.md | ✅ Via MCP | ✅ .pack/templates/claude-code.json | ✅ .ps1 + .sh | Copy template |
| **Cline** (VS Code) | ✅ Reads SKILL.md | ✅ Via MCP | ✅ .pack/templates/cline-settings.json | ✅ .ps1 + .sh | Add to settings.json |
| **Cursor** | ✅ Reads SKILL.md | ✅ Via rules | ✅ .pack/templates/cursor-mcp.json | ✅ .ps1 + .sh | Copy to .cursor/ |
| **Continue.dev** | ✅ Reads SKILL.md | ✅ Via rules | ✅ .pack/templates/continue-config.yaml | ✅ .ps1 + .sh | Copy to .continue/ |
| **Windsurf** | ✅ Reads SKILL.md | ✅ Via rules | ✅ .pack/templates/windsurf-mcp.json | ✅ .sh | Copy template |

### Setup per runtime

**Claude Code:** Copy `.pack/templates/claude-code.json` to project root as `claude.json` or configure via CLAUDE.md.

**Cline:** Add the `mcpServers` block from `.pack/templates/cline-settings.json` to VS Code's `settings.json`. Copy `.pack/rules/cline-memory.md` as `.clinerules`.

**Cursor:** Configure MCP servers in Cursor Settings > MCP using `.pack/templates/cursor-mcp.json`. Copy `.pack/rules/cursor-memory.mdc` to `.cursor/rules/memory.mdc`.

**Continue.dev:** Copy `.pack/templates/continue-config.yaml` to `.continue/config.yaml`. Add `.pack/rules/continue-memory.md` to `.continue/rules/`.

**Windsurf:** Copy `.pack/templates/windsurf-mcp.json` MCP config. Copy `.pack/rules/windsurf-memory.md` to `.windsurf/rules/memory.md`.

## Links

- **GitHub** github.com/EliasOulkadi/shokunin
- **Website** eliasoulkadi.github.io/shokunin
- [Shokunin Enterprise White Paper](/docs/Shokunin-Enterprise-White-Paper.pdf)

## License

MIT free as in freedom, free as in zero cost.
