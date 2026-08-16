# Project Conventions

Use this skill whenever you work inside this repository. The repository currently starts from a generic baseline, so update this file as soon as the project language, framework, or architecture becomes clearer.

## First Steps

1. Inspect the repository before editing:
   - List files with `rg --files` when available.
   - Read existing config files such as `package.json`, `pyproject.toml`, `composer.json`, `go.mod`, `Cargo.toml`, `README.md`, and framework-specific config.
   - Prefer existing patterns over introducing new ones.
2. Avoid committing secrets or local data:
   - Never write API keys, tokens, passwords, cookies, private certificates, or credentials into committed files.
   - Use `.env` locally and keep `.env.example` as the committed template.
   - Treat files in `docs-input/` as potentially sensitive local inputs.

## Communication Preferences

- Use Bahasa Indonesia by default for explanations, summaries, reports, and status updates.
- Keep technical names, commands, filenames, error messages, API names, and code identifiers in their original language.
- When reporting repository analysis, use this structure:
  - Ringkasan singkat.
  - Struktur folder penting.
  - Bahasa/framework/tools yang terdeteksi.
  - Cara menjalankan project.
  - Cara menjalankan test/build jika tersedia.
  - Risiko, TODO, atau hal yang perlu dikonfirmasi.
- Before editing files, briefly explain what will be changed.
- After editing files, summarize changed files and verification performed.
- Ask before destructive actions such as deleting files, resetting git state, or overwriting local secrets.

## Code Style

When no project-specific style exists yet:

- Keep code simple, explicit, and easy to review.
- Use descriptive names for public APIs, scripts, functions, classes, and files.
- Prefer small modules with clear responsibilities.
- Follow the formatter and linter already configured in the repo.
- If no formatter exists, follow the default formatter for the language:
  - JavaScript/TypeScript: Prettier-compatible formatting.
  - Python: Black-compatible formatting and type hints for new public functions.
  - Go: `gofmt`.
  - Rust: `rustfmt`.
  - PHP: PSR-12 unless the framework says otherwise.

## Folder Structure

Until the project defines its own structure, use this convention:

- `src/`: application source code.
- `tests/`: automated tests.
- `scripts/`: local helper scripts.
- `docs/`: committed documentation.
- `docs-input/`: local, uncommitted PDF/Excel inputs for AI agents.
- `.deepseek/skills/`: AI coding agent skills and project instructions.

Keep generated output, dependency folders, local caches, and sensitive data out of git.

## Testing Convention

- Add or update tests when behavior changes.
- Keep tests close to the affected behavior.
- Prefer deterministic tests that do not rely on real external services.
- Document any test that cannot be run locally without credentials or external infrastructure.
- Before finishing a coding task, run the narrowest useful verification command available. Examples:
  - Node.js: `npm test`, `npm run lint`, `npm run build`.
  - Python: `pytest`, `ruff check .`, `mypy .`.
  - Go: `go test ./...`.
  - Rust: `cargo test`.

## Commit Message Format

Use concise, imperative commit messages:

```text
type(scope): short summary
```

Recommended types:

- `feat`: user-facing feature.
- `fix`: bug fix.
- `docs`: documentation only.
- `test`: tests only.
- `refactor`: code restructuring without behavior change.
- `chore`: maintenance, tooling, setup.

Examples:

```text
chore(ai): add DeepSeek coding agent setup
docs(readme): explain document input workflow
fix(parser): handle empty worksheet rows
```

## Review Checklist

Before handing work back:

- Confirm no secrets were added.
- Confirm `.env` is ignored and `.env.example` contains empty placeholders only.
- Confirm local document inputs remain ignored except `docs-input/.gitkeep`.
- Summarize files changed and verification performed.
