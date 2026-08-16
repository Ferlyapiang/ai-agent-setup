#!/usr/bin/env bash
set -euo pipefail

SETUP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_PATH="."
TASK=""
PROVIDER="deepseek"
MODEL=""
NO_BOOTSTRAP=0
INTERACTIVE=0
INSTALL_LOCAL_SKILLS=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --path|-Path|-p)
      TARGET_PATH="$2"
      shift 2
      ;;
    --task|-Task|-t)
      TASK="$2"
      shift 2
      ;;
    --provider|-Provider)
      PROVIDER="$2"
      shift 2
      ;;
    --model|-Model)
      MODEL="$2"
      shift 2
      ;;
    --no-bootstrap)
      NO_BOOTSTRAP=1
      shift
      ;;
    --interactive)
      INTERACTIVE=1
      shift
      ;;
    --install-local-skills)
      INSTALL_LOCAL_SKILLS=1
      shift
      ;;
    *)
      TARGET_PATH="$1"
      shift
      ;;
  esac
done

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

copy_dir_if_missing() {
  local source="$1"
  local destination="$2"
  if [ ! -e "$destination" ]; then
    cp -R "$source" "$destination"
    info "Copied: $destination"
  else
    info "Already exists, skipped: $destination"
  fi
}

ensure_gitignore_block() {
  local repo_root="$1"
  local ignore_deepseek="${2:-0}"
  local gitignore="$repo_root/.gitignore"

  touch "$gitignore"

  add_ignore_rule() {
    local rule="$1"
    if ! grep -Fxq "$rule" "$gitignore"; then
      printf '%s\n' "$rule" >> "$gitignore"
    fi
  }

  add_ignore_rule "# AI agent local files"
  add_ignore_rule ".env"
  add_ignore_rule ".env.*"
  add_ignore_rule "!.env.example"
  add_ignore_rule "docs-input/*"
  add_ignore_rule "!docs-input/.gitkeep"
  add_ignore_rule ".codewhale/state/"
  if [ "$ignore_deepseek" -eq 1 ]; then
    add_ignore_rule ".deepseek/"
  fi
}

if ! has_command codewhale; then
  info "CodeWhale command was not found."
  info "Run setup first:"
  info "  $SETUP_ROOT/setup.sh"
  exit 1
fi

if [ -f "$SETUP_ROOT/.env" ]; then
  DEEPSEEK_API_KEY_VALUE="$(get_env_value "DEEPSEEK_API_KEY" "$SETUP_ROOT/.env")"
  if [ -n "$DEEPSEEK_API_KEY_VALUE" ]; then
    export DEEPSEEK_API_KEY="$DEEPSEEK_API_KEY_VALUE"
  fi
  OPENROUTER_API_KEY_VALUE="$(get_env_value "OPENROUTER_API_KEY" "$SETUP_ROOT/.env")"
  if [ -n "$OPENROUTER_API_KEY_VALUE" ]; then
    export OPENROUTER_API_KEY="$OPENROUTER_API_KEY_VALUE"
  fi
fi

if [ "$PROVIDER" = "deepseek" ] && [ -z "${DEEPSEEK_API_KEY:-}" ]; then
  info "DEEPSEEK_API_KEY is empty. Fill it in .env or choose another provider."
  exit 1
fi

if [ "$PROVIDER" = "openrouter" ] && [ -z "${OPENROUTER_API_KEY:-}" ]; then
  info "OPENROUTER_API_KEY is empty. Fill it in .env or choose another provider."
  info "For temporary testing, you can use OpenRouter free models after creating an API key."
  exit 1
fi

export CODEWHALE_PROVIDER="$PROVIDER"

if [ -z "$MODEL" ] && [ "$PROVIDER" = "openrouter" ]; then
  MODEL="openrouter/free"
fi

TARGET_ROOT="$(cd "$TARGET_PATH" && pwd)"

if [ "$NO_BOOTSTRAP" -eq 0 ]; then
  info "Preparing AI agent files in: $TARGET_ROOT"

  if [ "$INSTALL_LOCAL_SKILLS" -eq 1 ] && [ -d "$SETUP_ROOT/.deepseek" ]; then
    mkdir -p "$TARGET_ROOT/.deepseek"
    mkdir -p "$TARGET_ROOT/.deepseek/skills"

    if [ -d "$SETUP_ROOT/.deepseek/skills" ]; then
      for skill_dir in "$SETUP_ROOT"/.deepseek/skills/*; do
        if [ -d "$skill_dir" ]; then
          copy_dir_if_missing "$skill_dir" "$TARGET_ROOT/.deepseek/skills/$(basename "$skill_dir")"
        fi
      done
    fi

    if [ -f "$SETUP_ROOT/.deepseek/mcp.json" ] && [ ! -f "$TARGET_ROOT/.deepseek/mcp.json" ]; then
      cp "$SETUP_ROOT/.deepseek/mcp.json" "$TARGET_ROOT/.deepseek/mcp.json"
      info "Copied: $TARGET_ROOT/.deepseek/mcp.json"
    fi
  else
    info "Using skills from setup repo; not copying .deepseek into target."
  fi

  mkdir -p "$TARGET_ROOT/docs-input"
  if [ ! -f "$TARGET_ROOT/docs-input/.gitkeep" ]; then
    : > "$TARGET_ROOT/docs-input/.gitkeep"
  fi

  IGNORE_DEEPSEEK=0
  if [ "$TARGET_ROOT" != "$SETUP_ROOT" ]; then
    IGNORE_DEEPSEEK=1
  fi
  ensure_gitignore_block "$TARGET_ROOT" "$IGNORE_DEEPSEEK"
fi

cd "$TARGET_ROOT"

if [ "$INSTALL_LOCAL_SKILLS" -eq 1 ] && [ -d "$TARGET_ROOT/.deepseek/skills" ]; then
  export CODEWHALE_SKILLS_DIR="$TARGET_ROOT/.deepseek/skills"
elif [ -d "$SETUP_ROOT/.deepseek/skills" ]; then
  export CODEWHALE_SKILLS_DIR="$SETUP_ROOT/.deepseek/skills"
fi
if [ "$INSTALL_LOCAL_SKILLS" -eq 1 ] && [ -f "$TARGET_ROOT/.deepseek/mcp.json" ]; then
  export CODEWHALE_MCP_CONFIG="$TARGET_ROOT/.deepseek/mcp.json"
elif [ -f "$SETUP_ROOT/.deepseek/mcp.json" ]; then
  export CODEWHALE_MCP_CONFIG="$SETUP_ROOT/.deepseek/mcp.json"
fi

DEFAULT_TASK='Jawab selalu dalam Bahasa Indonesia kecuali untuk nama file, command, error, dan istilah teknis.
Saya sudah masuk ke folder repo ini.
Baca repo ini terlebih dahulu. Mulai dari README.md dan file instruksi di .deepseek/skills jika ada.
Gunakan skill project-conventions sebagai aturan kerja default jika tersedia.
Scan struktur folder, deteksi bahasa/framework/tools, jelaskan cara menjalankan project,
cara test/build jika tersedia, risiko penting, dan rekomendasi langkah berikutnya.
Jangan mengedit file apa pun dulu sebelum saya minta.'

if [ -z "$TASK" ]; then
  TASK="$DEFAULT_TASK"
fi

info "Running CodeWhale in: $TARGET_ROOT"
info "Provider: $PROVIDER"
if [ -n "$MODEL" ]; then
  info "Model: $MODEL"
fi
if [ -n "${CODEWHALE_SKILLS_DIR:-}" ]; then
  info "Using skills dir: $CODEWHALE_SKILLS_DIR"
fi
info ""

if [ "$INTERACTIVE" -eq 1 ]; then
  info "Interactive mode. Paste this prompt into CodeWhale:"
  info ""
  info "$TASK"
  info ""
  if [ -n "$MODEL" ]; then
    codewhale --provider "$PROVIDER" --model "$MODEL"
  else
    codewhale --provider "$PROVIDER"
  fi
else
  if [ -n "$MODEL" ]; then
    codewhale --provider "$PROVIDER" --model "$MODEL" -p "$TASK"
  else
    codewhale --provider "$PROVIDER" -p "$TASK"
  fi
fi
