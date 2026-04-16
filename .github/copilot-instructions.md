# Copilot Instructions

## Session continuity

**At the start of every session:** Read `progress.md` in the repo root to understand what has been done and what is pending.

**After every task or significant change** (do not wait until end of session): Update `progress.md` immediately — move completed items into the Completed section with the date, and update the Next / Pending section. Do this after every meaningful action, not just at session end.

## Repository overview

Single-file macOS setup automation: `setup.sh` installs apps/tools via Homebrew, configures shell (Oh My Zsh + Powerlevel10k), git, VS Code, SSH, Firefox extensions, and applies ~100 `defaults write` macOS system preferences. The companion `.p10k.zsh` is a pre-built Powerlevel10k prompt config that bypasses the interactive wizard.

There are no tests, no build step, and no linter.

## Running the script

```bash
./setup.sh                    # install everything
DRY_RUN=1 ./setup.sh          # preview all commands without executing
./setup.sh firefox vscode     # install specific apps only
```

## Architecture

`setup.sh` is divided into 8 clearly-labelled sections (see the header comment):

1. **Configuration** — the only section users normally edit: `DEFAULT_CASKS`, `DEFAULT_FORMULAE`, `VSCODE_EXTENSIONS` arrays at the top of the file.
2. **Utilities** — `log()`, `run()`, `run_soft()`
3. **Homebrew** — helpers, prerequisites, `install_formula()` / `install_cask()`
4. **Shell Setup** — `configure_oh_my_zsh()`, `configure_zshrc()`
5. **Developer Tools** — git, VS Code, SSH key, Firefox extensions, dev folder
6. **macOS Preferences** — one `configure_*()` function per app/subsystem
7. **Security** — Gatekeeper / quarantine
8. **Entry Point** — `main()` wires it all together

`main()` must call `configure_oh_my_zsh()` before any other `.zshrc` write — OMZ rewrites the file during install and would clobber any earlier additions.

## Key conventions

- **`run()`** wraps every side-effecting command. In `DRY_RUN=1` mode it prints the command instead of executing it. Use `run` for all destructive or system-modifying calls.
- **`run_soft()`** is identical to `run()` but silently swallows failures (`2>/dev/null || true`). Use it for permission-gated `defaults write` domains (e.g. Safari on Ventura+) where failure is expected on some setups.
- **`normalize_cask()`** maps user-friendly aliases (`vscode`, `code`, `vs-code`) to their canonical Homebrew cask names. Add entries here when a cask has multiple common aliases.
- **`app_already_present()`** skips cask installs when the `.app` bundle already exists in `/Applications` or `~/Applications`. Add new entries to `app_bundle_name()` when adding new casks.
- The script uses `set -euo pipefail` — any unguarded non-zero exit aborts everything. Wrap expected-to-fail commands with `|| true` or use `run_soft()`.
- **Idempotency**: every section checks whether its target already exists before acting. New functions should follow the same guard pattern (`[[ -d ... ]] && return 0`).
- `sudo` is requested once upfront in `main()` and kept alive via a background loop (`sudo -n true; sleep 60`). Individual functions call `sudo` directly without re-prompting.

## Personalisation points

These are hardcoded and must be changed before using on a different machine:

- **Git identity**: `configure_git()` — `user.name` and `user.email`
- **Computer name**: `configure_system()` — `scutil --set ComputerName/HostName/LocalHostName` (currently `dev-mac`)
- **App/tool lists**: `DEFAULT_CASKS` and `DEFAULT_FORMULAE` arrays at the top of the file
