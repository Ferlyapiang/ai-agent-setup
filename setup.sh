#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

info() {
  printf '%s\n' "$1"
}

has_command() {
  command -v "$1" >/dev/null 2>&1
}

get_env_value() {
  local key="$1"
  local file="$2"
  if [ ! -f "$file" ]; then
    return 0
  fi
  grep -E "^[[:space:]]*${key}=" "$file" | tail -n 1 | sed -E "s/^[[:space:]]*${key}=//; s/^[[:space:]]+//; s/[[:space:]]+$//; s/^['\"]//; s/['\"]$//"
}

info "Checking terminal AI coding agent..."
AGENT_COMMAND=""
if has_command codewhale; then
  info "CodeWhale command found."
  AGENT_COMMAND="codewhale"
elif has_command deepseek || has_command deepseek-tui; then
  info "DeepSeek-TUI command found."
  AGENT_COMMAND="deepseek"
else
  if ! has_command npm; then
    info "npm is required to install the terminal AI coding agent, but npm was not found."
    info "Install Node.js/npm first, then rerun this script."
    exit 1
  fi
  info "No supported agent was found. Installing CodeWhale with: npm install -g codewhale"
  info "DeepSeek-TUI is deprecated upstream; CodeWhale is its recommended replacement."
  npm install -g codewhale
  AGENT_COMMAND="codewhale"
fi

info "Checking Python document-reading dependencies..."
PYTHON_BIN=""
if has_command python; then
  PYTHON_BIN="python"
elif has_command python3; then
  PYTHON_BIN="python3"
fi

if [ -z "$PYTHON_BIN" ]; then
  info "Python was not found. Install Python, then install document dependencies with:"
  info "  python -m pip install pandas openpyxl pdfplumber"
else
  if "$PYTHON_BIN" -c "import pandas, openpyxl, pdfplumber" >/dev/null 2>&1; then
    info "Document-reading Python dependencies are available."
  else
    info "Some document-reading Python dependencies are missing."
    info "Install them when needed with:"
    info "  $PYTHON_BIN -m pip install pandas openpyxl pdfplumber"
  fi
fi

mkdir -p docs-input
if [ ! -f docs-input/.gitkeep ]; then
  : > docs-input/.gitkeep
fi

if [ ! -f .env ]; then
  cp .env.example .env
  info ".env was created from .env.example."
  info "Please fill DEEPSEEK_API_KEY in .env, then rerun this script."
  exit 1
fi

DEEPSEEK_API_KEY_VALUE="$(get_env_value "DEEPSEEK_API_KEY" ".env")"
if [ -z "$DEEPSEEK_API_KEY_VALUE" ]; then
  info ".env exists, but DEEPSEEK_API_KEY is empty."
  info "Please fill DEEPSEEK_API_KEY in .env, then rerun this script."
  exit 1
fi

info "setup selesai, jalankan: $AGENT_COMMAND"
