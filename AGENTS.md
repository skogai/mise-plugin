# Repository guidelines

## Project structure

This repository implements the SkogAI mise environment plugin. It supplies workspace environment variables and optional PATH entries. Keep hooks limited to computing values; do not add downloads, file writes, or command execution.

- `metadata.lua`: plugin identity, version, and minimum supported mise version.
- `hooks/mise_env.lua`: `SKOGAI_MONOREPO_DIR` and `SKOGAI_CONFIG_DIR`, and the `SKOGAI_HOST`, `SKOGAI_OS` and `SKOGAI_ARCH` defaults that keep a value already set.
- `hooks/mise_path.lua`: PATH entries.
- `lib/skogai.lua`: shared option handling and path resolution.
- `types/mise-plugin.lua`: LuaCATS definitions for the mise plugin API.
- `test/run.sh`: integration checks through mise in temporary directories.
- `mise.toml` and `mise.lock`: development tools and task definitions.
- `hk.pkl`, `stylua.toml`, and `.luarc.json`: linting, formatting, and Lua analysis configuration.

Keep user-facing usage and option defaults in `README.md`. Do not commit machine-local state, credentials, logs, or session histories. If present, treat `codex-old/` and `.skogai/` as workspace data rather than source.

## Development commands

- `mise install`: install development tools.
- `mise run lint`: run StyLua, Lua language server checks, and actionlint through hk over all files.
- `mise run lint-fix`: apply configured automatic fixes.
- `mise run test`: execute `sh test/run.sh`.

The plugin requires mise 2026.11.5 or later. Tests require mise on PATH and isolate its config, data, state, and cache directories. Preserve this isolation; do not link test plugins into the user's normal mise setup.

## Style and implementation

Follow `stylua.toml`: four-space indentation, Unix line endings, a 120-column target, and double quotes where practical. Keep Lua compatible with the Lua 5.1 runtime configured in `.luarc.json`, even though the development toolchain installs a newer Lua version. Add LuaCATS annotations for hook interfaces and shared helpers.

Keep common option logic in `lib/skogai.lua` and hooks small. Resolve relative roots against the declaring config directory, and relative option paths against the workspace root. Preserve tilde expansion, option defaults, PATH ordering, and duplicate filtering when changing path handling.

Write Markdown with ATX headings, short paragraphs, and backticks around paths and commands.

## Verification

For executable changes, extend `test/run.sh` with checks named for the behavior under test, then run `mise run lint` and `mise run test`. CI runs both commands for pushes and pull requests to `main`. Update the README when public options or behavior change.

For documentation-only changes, review the rendered structure and run `git diff --check`. Before handing off any change, inspect `git status --short` and the relevant diff; for this guide, use `git diff -- AGENTS.md`. Newly created, untracked files must also be reviewed directly.

## Commits and pull requests

Use short, imperative commit summaries. Prefer `<type>(<scope>): <summary>` for new work, with types such as `docs`, `feat`, `fix`, or `chore`. Keep commits focused.

Pull requests should explain purpose and impact, list verification performed, and link relevant issues. Include screenshots only for visible UI changes. Never include authentication files, databases, or other machine-local artifacts.
