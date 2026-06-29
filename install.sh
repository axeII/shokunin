#!/usr/bin/env bash
set -euo pipefail

VERSION="4.2-lite"
CORES_DIR="$HOME/.shokunin"
SKILLS_DIR="$HOME/.config/opencode/skills"
CONFIG_DIR="$HOME/.config/opencode"
CLAUDE_DIR="$HOME/.claude"
LOG_FILE="/tmp/shokunin-install-$(date +%Y%m%d-%H%M%S).log"

NONINTERACTIVE=false

step=1
log() { echo "  $1" | tee -a "$LOG_FILE"; }
step_msg() { echo ""; echo "[$step] $1"; step=$((step + 1)); }
ok() { echo "    OK"; }
skip() { echo "    SKIP (already exists)"; }
fail() { echo "    FAIL: $1" | tee -a "$LOG_FILE"; }

for arg in "$@"; do
  case "$arg" in
    -y|--yes) NONINTERACTIVE=true ;;
  esac
done

if [ -z "${BASH_VERSION:-}" ]; then
  echo "ERROR: This script must be run with bash, not sh."
  echo "  Correct: bash install.sh"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo ""
echo "=========================================="
echo "  Shokunin AI Ecosystem v$VERSION (lite)"
echo "  Linux Installer"
echo "  github.com/axeII/shokunin-lite"
echo "=========================================="
echo ""
echo "  Requires: bash 4+, Node.js 18+, Python 3.11+"
echo ""

if [ "$NONINTERACTIVE" = false ] && [ -t 0 ]; then
  read -r -p "  Continue? (y/n): " CONFIRM
  if [ "$CONFIRM" != "y" ]; then echo "  Cancelled."; exit 0; fi
fi

# === PREREQUISITES ===
step_msg "Verifying prerequisites..."
ALL_OK=true

if bash --version | grep -q "GNU bash"; then log "bash OK"; else log "bash required"; ALL_OK=false; fi

if command -v node &>/dev/null; then
    NODE_VER=$(node --version | sed 's/v//' | cut -d. -f1)
    if [ "$NODE_VER" -ge 18 ]; then log "Node.js $(node --version)"; else log "Node.js 18+ required"; ALL_OK=false; fi
else
    log "Node.js 18+ required (apt install nodejs or https://nodejs.org)"; ALL_OK=false
fi

if command -v python3 &>/dev/null; then
    PY_VER=$(python3 --version 2>&1 | sed 's/Python //' | cut -d. -f1-2)
    PY_MAJOR=$(echo "$PY_VER" | cut -d. -f1)
    PY_MINOR=$(echo "$PY_VER" | cut -d. -f2)
    if [ "$PY_MAJOR" -ge 3 ] && [ "$PY_MINOR" -ge 11 ]; then log "Python $PY_VER"; else log "Python 3.11+ required"; ALL_OK=false; fi
else
    log "Python 3.11+ required (apt install python3)"; ALL_OK=false
fi

if command -v git &>/dev/null; then log "Git $(git --version | cut -d' ' -f3)"; else log "Git required (apt install git)"; ALL_OK=false; fi

if command -v opencode &>/dev/null; then
    log "OpenCode detected"
else
    log "Installing OpenCode..."
    if command -v npm &>/dev/null; then
      if npm install -g opencode >> "$LOG_FILE" 2>&1; then
        log "OpenCode installed"
      else
        fail "npm install -g opencode failed. Try: sudo npm install -g opencode"
        ALL_OK=false
      fi
    else
      fail "npm not found. Install Node.js first: https://nodejs.org"
      ALL_OK=false
    fi
fi

$ALL_OK || { echo "  Install missing requirements and re-run."; exit 1; }

# === PYTHON DEPENDENCIES ===
step_msg "Installing Python dependencies..."

if ! python3 -m pip --version &>/dev/null; then
  log "Installing python3-pip..."
  if command -v apt-get &>/dev/null; then
    if [ "$(id -u)" -ne 0 ]; then
      SUDO="sudo"
    fi
    $SUDO apt-get install -y python3-pip >> "$LOG_FILE" 2>&1 || {
      fail "Could not install python3-pip. Try: sudo apt-get install python3-pip"
      exit 1
    }
  else
    fail "pip3 not found. Install python3-pip for your distro."
    exit 1
  fi
fi

PIP_FLAGS=""
if python3 -m pip install --dry-run chromadb 2>&1 | grep -q "externally-managed"; then
  log "Detected PEP 668, using --break-system-packages"
  PIP_FLAGS="$PIP_FLAGS --break-system-packages"
fi

if python3 -m pip list 2>/dev/null | grep -qi "typing-extensions"; then
  log "Detected typing-extensions, ignoring installed"
  PIP_FLAGS="$PIP_FLAGS --ignore-installed typing-extensions"
fi

python3 -m pip install chromadb $PIP_FLAGS >> "$LOG_FILE" 2>&1 && ok || {
  fail "pip install chromadb failed. Try: python3 -m pip install chromadb $PIP_FLAGS"
  exit 1
}

# === DIRECTORIES ===
step_msg "Creating directories..."
mkdir -p "$CORES_DIR/memory/chroma_db" "$CORES_DIR/memory/sessions" "$CORES_DIR/scripts/linux" "$CORES_DIR/backups"
mkdir -p "$SKILLS_DIR" "$CONFIG_DIR" "$CLAUDE_DIR"
ok

# === SKILLS (from skills-lite/) ===
step_msg "Installing skills..."
COUNT=0
for dir in "$SCRIPT_DIR/skills-lite"/*/; do
    if [ -f "${dir}SKILL.md" ]; then
        NAME=$(basename "$dir")
        TARGET="$SKILLS_DIR/$NAME"
        mkdir -p "$TARGET"
        cp -r "${dir}"* "$TARGET/" 2>/dev/null || true
        COUNT=$((COUNT + 1))
    fi
done
log "$COUNT skills installed"

# === MEMORY SYSTEM ===
step_msg "Installing memory system..."
cp "$SCRIPT_DIR/.pack/memory/mcp-server.py" "$CORES_DIR/memory/mcp-server.py" 2>/dev/null || curl -sL "https://raw.githubusercontent.com/axeII/shokunin-lite/main/.pack/memory/mcp-server.py" -o "$CORES_DIR/memory/mcp-server.py"
cp "$SCRIPT_DIR/.pack/scripts/chroma-helper.py" "$CORES_DIR/scripts/chroma-helper.py" 2>/dev/null || curl -sL "https://raw.githubusercontent.com/axeII/shokunin-lite/main/.pack/scripts/chroma-helper.py" -o "$CORES_DIR/scripts/chroma-helper.py"
ok

# === LINUX SCRIPTS ===
step_msg "Installing Linux scripts..."
for script in run-opencode.sh memory-healthcheck.sh weekly-maintenance.sh profile.sh; do
    SRC="$SCRIPT_DIR/.pack/scripts/linux/$script"
    if [ -f "$SRC" ]; then
        cp "$SRC" "$CORES_DIR/scripts/linux/$script"
        chmod +x "$CORES_DIR/scripts/linux/$script"
    else
        curl -sL "https://raw.githubusercontent.com/axeII/shokunin-lite/main/.pack/scripts/linux/$script" -o "$CORES_DIR/scripts/linux/$script" 2>/dev/null
        chmod +x "$CORES_DIR/scripts/linux/$script" 2>/dev/null || true
    fi
done
log "Linux scripts installed"

# === OPENCODE CONFIG ===
step_msg "Configuring OpenCode..."
CONFIG_SRC="$SCRIPT_DIR/opencode.json.template"
if [ -f "$CONFIG_DIR/opencode.json" ]; then
    cp "$CONFIG_DIR/opencode.json" "$CONFIG_DIR/opencode.json.shokunin-backup-$(date +%Y%m%d-%H%M%S)"
fi

# Prompt for Radar MCP URL
RADAR_URL="${RADAR_MCP_URL:-}"
if [ -z "$RADAR_URL" ] && [ "$NONINTERACTIVE" = false ] && [ -t 0 ]; then
    echo ""
    echo "  Optional: Radar MCP URL for cluster debugging"
    echo "  Radar MCP provides live Kubernetes introspection."
    echo "  Leave empty to skip — the skill can be configured later."
    echo "  Example: http://localhost:49412/mcp"
    echo ""
    read -r -p "  Radar MCP URL (optional): " RADAR_URL
fi
if [ -z "$RADAR_URL" ]; then
    RADAR_URL="http://localhost:49412/mcp"
fi

# Prompt for Konflate MCP URL
KONFLATE_URL="${KONFLATE_MCP_URL:-}"
if [ -z "$KONFLATE_URL" ] && [ "$NONINTERACTIVE" = false ] && [ -t 0 ]; then
    echo ""
    echo "  Optional: Konflate MCP URL for Flux PR diff review"
    echo "  Konflate renders Flux PR diffs with blast radius and image changes."
    echo "  Leave empty to skip — the skill can be configured later."
    echo "  Example: https://konflate.example.com/mcp"
    echo ""
    read -r -p "  Konflate MCP URL (optional): " KONFLATE_URL
fi
if [ -z "$KONFLATE_URL" ]; then
    KONFLATE_URL=""
fi

NVIDIA_KEY="${NVIDIA_API_KEY:-}"
if [ -z "$NVIDIA_KEY" ] && [ "$NONINTERACTIVE" = false ] && [ -t 0 ]; then
    echo ""
    echo "  Optional: NVIDIA API key for NVIDIA models"
    echo "  Leave empty to skip — OpenCode Go works without it."
    echo "  Get a key: https://build.nvidia.com/ (free signup)"
    echo ""
    read -r -p "  NVIDIA API Key (optional): " NVIDIA_KEY
fi

if [ -f "$CONFIG_SRC" ]; then
    PYTHON_BIN="python3"
    command -v python3 &>/dev/null || PYTHON_BIN="python"

    # Generate from template
    sed "s|{{MCP_ROOT_PATH}}|$HOME|g; \
         s|{{PYTHON_CMD}}|$PYTHON_BIN|g; \
         s|{{MCP_MEMORY_PATH}}|$CORES_DIR/memory/mcp-server.py|g; \
         s|{{SKILLS_PATH}}|$SKILLS_DIR|g; \
         s|{{RADAR_MCP_URL}}|$RADAR_URL|g; \
         s|{{KONFLATE_MCP_URL}}|$KONFLATE_URL|g" \
      "$CONFIG_SRC" > "$CONFIG_DIR/opencode.json" 2>/dev/null || cp "$CONFIG_SRC" "$CONFIG_DIR/opencode.json"

    if grep -q "{{MCP_\|{{PYTHON_\|{{SKILLS_\|{{RADAR_\|{{KONFLATE_" "$CONFIG_DIR/opencode.json" 2>/dev/null; then
        log "WARNING: Placeholders remain in opencode.json. Check the file."
    fi
fi

NVIDIA_PROFILE=""
if [ -f "$HOME/.zshrc" ]; then NVIDIA_PROFILE="$HOME/.zshrc"
elif [ -f "$HOME/.bashrc" ]; then NVIDIA_PROFILE="$HOME/.bashrc"
elif [ -f "$HOME/.bash_profile" ]; then NVIDIA_PROFILE="$HOME/.bash_profile"
fi
if [ -n "$NVIDIA_KEY" ] && [ -n "$NVIDIA_PROFILE" ] && ! grep -q "NVIDIA_API_KEY" "$NVIDIA_PROFILE" 2>/dev/null; then
    printf 'export NVIDIA_API_KEY="%s"\n' "$NVIDIA_KEY" >> "$NVIDIA_PROFILE"
fi
log "Config generated"

# === OPENCODE QUOTA ===
step_msg "Installing OpenCode Quota plugin..."
if command -v node &>/dev/null && command -v npm &>/dev/null; then
    NODE_VER=$(node --version | sed 's/v//' | cut -d. -f1)
    if [ "$NODE_VER" -ge 20 ]; then
        if npm install -g @slkiser/opencode-quota --legacy-peer-deps >> "$LOG_FILE" 2>&1; then
            log "@slkiser/opencode-quota installed"
            mkdir -p "$CONFIG_DIR/opencode-quota"

            # tui.json — add plugin if present, create if not
            if [ -f "$CONFIG_DIR/tui.json" ]; then
                if ! grep -q "opencode-quota" "$CONFIG_DIR/tui.json" 2>/dev/null; then
                    python3 -c "
import json
with open('$CONFIG_DIR/tui.json') as f:
    cfg = json.load(f)
if 'plugin' not in cfg:
    cfg['plugin'] = []
if '@slkiser/opencode-quota' not in cfg['plugin']:
    cfg['plugin'].append('@slkiser/opencode-quota')
with open('$CONFIG_DIR/tui.json', 'w') as f:
    json.dump(cfg, f, indent=2)
"
                    log "tui.json: plugin added"
                else
                    log "tui.json: already configured"
                fi
            else
                cat > "$CONFIG_DIR/tui.json" << EOF
{
  "\$schema": "https://opencode.ai/tui.json",
  "plugin": ["@slkiser/opencode-quota"],
  "theme": "catppuccin"
}
EOF
                log "tui.json: configured"
            fi

            cat > "$CONFIG_DIR/opencode-quota/quota-toast.json" << EOF
{
  "\$schema": "https://opencode.ai/config.json",
  "enabledProviders": ["opencode-go"],
  "enableToast": true,
  "tuiSidebarPanel": {
    "enabled": true
  },
  "tuiCompactStatus": {
    "enabled": true,
    "homeBottom": true,
    "sessionPrompt": true
  },
  "maintainerAnnouncements": {
    "enabled": true,
    "home": true
  },
  "opencodeGoWindows": ["rolling", "weekly", "monthly"]
}
EOF
            log "quota-toast.json: configured"
        else
            log "WARNING: npm install @slkiser/opencode-quota failed"
        fi
    else
        log "WARNING: Node.js 20+ required for opencode-quota (found v$NODE_VER). Skipping."
    fi
else
    log "WARNING: Node.js/npm not found. Skipping opencode-quota setup."
fi

# === CLAUDE.md ===
step_msg "Configuring global instructions..."
CLAUDE_SRC="$SCRIPT_DIR/.pack/CLAUDE.md"
if [ -f "$CLAUDE_SRC" ]; then
    if [ -f "$CLAUDE_DIR/CLAUDE.md" ]; then
        cp "$CLAUDE_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md.shokunin-backup-$(date +%Y%m%d-%H%M%S)"
    fi
    cp "$CLAUDE_SRC" "$CLAUDE_DIR/CLAUDE.md"
fi

AGENTS_SRC="$SCRIPT_DIR/.pack/AGENTS.md"
if [ -f "$AGENTS_SRC" ]; then
    cp "$AGENTS_SRC" "$HOME/AGENTS.md"
fi
log "Instructions configured"

# === PROFILE ===
step_msg "Configuring shell profile..."
PROFILE_FILE=""
if [ -f "$HOME/.zshrc" ]; then PROFILE_FILE="$HOME/.zshrc"
elif [ -f "$HOME/.bashrc" ]; then PROFILE_FILE="$HOME/.bashrc"
elif [ -f "$HOME/.bash_profile" ]; then PROFILE_FILE="$HOME/.bash_profile"
fi

if [ -n "$PROFILE_FILE" ]; then
    if grep -q "Shokunin" "$PROFILE_FILE" 2>/dev/null; then
        log "Shokunin already in $PROFILE_FILE"
    else
        echo "" >> "$PROFILE_FILE"
        echo "# Shokunin AI Ecosystem (lite)" >> "$PROFILE_FILE"
        echo "source \$HOME/.shokunin/scripts/linux/profile.sh" >> "$PROFILE_FILE"
        log "Added to $PROFILE_FILE"
    fi
else
    log "No .bashrc/.zshrc found. Add 'source ~/.shokunin/scripts/linux/profile.sh' manually"
fi

# === CRONTAB ===
step_msg "Setting up weekly maintenance..."
if command -v crontab &>/dev/null; then
  if crontab -l 2>/dev/null | grep -q "shokunin"; then
      log "Crontab already configured"
  else
      (crontab -l 2>/dev/null; echo "0 21 * * 0 \$HOME/.shokunin/scripts/linux/weekly-maintenance.sh") | crontab -
      log "Crontab added (Sunday 21:00)"
  fi
else
  log "crontab not available — weekly maintenance won't auto-schedule"
fi

# === VERIFICATION ===
step_msg "Verifying installation..."
if [ -f "$CORES_DIR/scripts/linux/memory-healthcheck.sh" ]; then
  bash "$CORES_DIR/scripts/linux/memory-healthcheck.sh" && ok || fail "Some checks failed"
fi

# === SUMMARY ===
echo ""
echo "=========================================="
echo "  Shokunin AI Ecosystem (lite) - Installed"
echo "=========================================="
echo ""
echo "  Skills: $COUNT installed"
echo "  Memory: ChromaDB in $CORES_DIR/memory"
echo "  Shell: source ~/.shokunin/scripts/linux/profile.sh"
echo "  Crontab: Sunday 21:00 (backup + cleanup)"
echo "  Quota: sidebar panel + compact status line (openCode Go)"
echo ""
if [ -n "$RADAR_URL" ] && [ "$RADAR_URL" != "http://localhost:49412/mcp" ]; then
    echo "  Radar MCP: $RADAR_URL"
fi
if [ -n "$KONFLATE_URL" ]; then
    echo "  Konflate MCP: $KONFLATE_URL"
fi
echo ""
echo "  NEXT STEPS:"
echo "  1. Reload your shell: source ~/.bashrc"
echo "  2. Start coding: opencode"
echo "  3. Test memory: ~/.shokunin/scripts/linux/memory-healthcheck.sh"
echo ""
echo "  OPENCODE GO QUOTA SETUP:"
echo "  Add these to your Fish shell config (~/.config/fish/config.fish):"
echo '    set -gx OPENCODE_GO_WORKSPACE_ID "wrk_01KFRYBAA0N22SYSEG2QF1RG9R"'
echo '    set -gx OPENCODE_GO_AUTH_COOKIE "<your-cookie>"'
echo ""
echo "  Get the auth cookie:"
echo "    1. Open your OpenCode Go dashboard in a browser"
echo "    2. DevTools -> Storage -> Cookies -> copy 'auth' cookie value"
echo "    3. Replace <your-cookie> with the actual value"
echo "    4. source ~/.config/fish/config.fish"
echo "    5. Restart opencode"
echo ""
echo "  Repo: https://github.com/axeII/shokunin-lite"
echo "=========================================="
