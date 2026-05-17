#!/usr/bin/env bash
set -euo pipefail

VERSION="1.1"
BASE_DIR="$HOME/.shokunin"
SKILLS_DIR="$HOME/.config/opencode/skills"
CONFIG_DIR="$HOME/.config/opencode"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo ""
echo "=========================================="
echo "  Shokunin Lite v$VERSION"
echo "  Memory + Docker, Kubernetes, Senior Engineer, Linux Triage"
echo "=========================================="
echo ""

if [ -z "${BASH_VERSION:-}" ]; then
    echo "ERROR: This script must be run with bash, not sh."
    exit 1
fi

echo "  Prerequisites: Python 3.11+, git"
echo ""

check_cmd() {
    if command -v "$1" &>/dev/null; then
        echo "  $1: $(command -v "$1")"
        return 0
    fi
    echo "  $1: NOT FOUND"
    return 1
}

ALL_OK=true
check_cmd python3.11 || check_cmd python3 || ALL_OK=false
check_cmd git || ALL_OK=false

if [ "$ALL_OK" = false ]; then
    echo ""
    echo "  Install missing requirements and re-run."
    exit 1
fi

PY_CMD="python3.11"
command -v python3.11 &>/dev/null || PY_CMD="python3"
PY_VER=$($PY_CMD --version 2>&1 | sed 's/Python //' | cut -d. -f1-2)
PY_MAJOR=$(echo "$PY_VER" | cut -d. -f1)
PY_MINOR=$(echo "$PY_VER" | cut -d. -f2)
if [ "$PY_MAJOR" -lt 3 ] || { [ "$PY_MAJOR" -eq 3 ] && [ "$PY_MINOR" -lt 11 ]; }; then
    echo "  ERROR: Python 3.11+ required. Found: $PY_VER"
    exit 1
fi
echo "  Python $PY_VER: OK"

if [ -f "$SCRIPT_DIR/opencode.json.template" ] && [ -d "$SCRIPT_DIR/skills-lite" ]; then
    echo ""
    echo "  Installing from local repo..."
    SOURCE_DIR="$SCRIPT_DIR"
elif [ -d "$SCRIPT_DIR/.pack" ]; then
    echo ""
    echo "  Installing from local repo..."
    SOURCE_DIR="$SCRIPT_DIR"
else
    echo ""
    echo "  Cloning repo..."
    REPO_DIR="/tmp/shokunin-repo"
    if [ -d "$REPO_DIR" ]; then rm -rf "$REPO_DIR"; fi
    for retry in 1 2 3; do
        git clone --depth 1 https://github.com/EliasOulkadi/shokunin.git "$REPO_DIR" 2>/dev/null && break
        sleep 1
    done
    if [ ! -d "$REPO_DIR" ]; then
        echo "  ERROR: git clone failed. Check network."
        exit 1
    fi
    SOURCE_DIR="$REPO_DIR"
fi

echo ""
echo "  Installing Python dependencies..."
PIP_FLAGS=""
if $PY_CMD -m pip install --dry-run chromadb 2>&1 | grep -q "externally-managed"; then
    PIP_FLAGS="$PIP_FLAGS --break-system-packages"
fi

$PY_CMD -m pip install chromadb $PIP_FLAGS >> /tmp/shokunin-lite-install.log 2>&1 || {
    echo "  ERROR: pip install chromadb failed. Check /tmp/shokunin-lite-install.log"
    exit 1
}
echo "  chromadb: installed"

echo ""
echo "  Creating directories..."
mkdir -p "$BASE_DIR/memory/chroma_db" "$BASE_DIR/memory/sessions" "$BASE_DIR/scripts"
mkdir -p "$SKILLS_DIR"
mkdir -p "$CONFIG_DIR"
echo "  Directories created"

echo ""
echo "  Installing memory system..."
cp "$SOURCE_DIR/.pack/memory/mcp-server.py" "$BASE_DIR/memory/mcp-server.py" 2>/dev/null || true
cp "$SOURCE_DIR/.pack/scripts/chroma-helper.py" "$BASE_DIR/scripts/chroma-helper.py" 2>/dev/null || true
echo "  Memory system: installed"

echo ""
echo "  Installing skills..."
for skill in docker kubernetes senior-engineer arch-linux-triage; do
    SRC="$SOURCE_DIR/skills-lite/$skill"
    if [ -d "$SRC" ]; then
        TARGET="$SKILLS_DIR/$skill"
        mkdir -p "$TARGET"
        cp -r "$SRC"/* "$TARGET/" 2>/dev/null || true
        echo "  - $skill"
    else
        SRC="$SOURCE_DIR/.pack/skills/$skill"
        if [ -d "$SRC" ]; then
            TARGET="$SKILLS_DIR/$skill"
            mkdir -p "$TARGET"
            cp -r "$SRC"/* "$TARGET/" 2>/dev/null || true
            echo "  - $skill"
        fi
    fi
done

echo ""
echo "  Configuring OpenCode..."
MCP_MEMORY_PATH="$BASE_DIR/memory/mcp-server.py"
SKILLS_PATH="$SKILLS_DIR"
if [ -f "$SOURCE_DIR/opencode.json.template" ]; then
    sed "s|{{PYTHON_CMD}}|$PY_CMD|g; \
         s|{{MCP_MEMORY_PATH}}|$MCP_MEMORY_PATH|g; \
         s|{{SKILLS_PATH}}|$SKILLS_PATH|g" \
        "$SOURCE_DIR/opencode.json.template" > "$CONFIG_DIR/opencode.json"
else
    cat > "$CONFIG_DIR/opencode.json" << EOF
{
  "\$schema": "https://opencode.ai/config.json",
  "model": "opencode-go/deepseek-v4-flash",
  "mcp": {
    "memory": {
      "type": "local",
      "command": ["$PY_CMD", "$MCP_MEMORY_PATH"]
    }
  },
  "skills": {
    "paths": ["$SKILLS_PATH"]
  }
}
EOF
fi
echo "  opencode.json: configured"

if [ -n "${REPO_DIR:-}" ] && [ -d "$REPO_DIR" ]; then
    echo ""
    echo "  Cleanup..."
    rm -rf "$REPO_DIR"
fi
echo "  Done"

echo ""
echo "=========================================="
echo "  Shokunin Lite - Installed"
echo "=========================================="
echo ""
echo "  Memory: ChromaDB at $BASE_DIR/memory"
echo "  Skills: docker, kubernetes, senior-engineer, arch-linux-triage"
echo ""
echo "  Usage:"
echo "  - $PY_CMD ~/.shokunin/scripts/chroma-helper.py search \"query\""
echo "  - $PY_CMD ~/.shokunin/scripts/chroma-helper.py session list"
echo ""