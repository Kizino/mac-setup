# mac-reforge

A single bash script to set up a brand new Mac — installs all your apps and CLI tools, configures git, and applies a full set of sensible macOS system preferences. Fully automated.

---

## Usage

```bash
cd mac-reforge
chmod +x setup.sh
./setup.sh
```

**Preview without making any changes (dry-run):**

```bash
DRY_RUN=1 ./setup.sh
```

**Install a specific app only:**

```bash
./setup.sh firefox vscode
```

---

## What it installs

### GUI Apps (Homebrew Casks)

| App | Description |
|-----|-------------|
| [Bruno](https://www.usebruno.com/) | Lightweight API client (Git-friendly alternative to Postman) |
| [Discord](https://discord.com/) | Voice, video & text chat |
| [Docker Desktop](https://www.docker.com/products/docker-desktop/) | Container platform with built-in `docker` and `docker compose` CLI |
| [Firefox](https://www.mozilla.org/firefox/) | Web browser |
| [Karabiner-Elements](https://karabiner-elements.pqrs.org/) | Keyboard customiser — remap keys per device |
| [LM Studio](https://lmstudio.ai/) | Run local AI/LLM models offline (Llama, Mistral, etc.) |
| [Obsidian](https://obsidian.md/) | Markdown note-taking & knowledge base |
| [VS Code](https://code.visualstudio.com/) | Code editor |

### CLI Tools (Homebrew Formulae)

| Tool | Description |
|------|-------------|
| [bat](https://github.com/sharkdp/bat) | Better `cat` — syntax highlighting, line numbers, and git diff |
| [btop](https://github.com/aristocratos/btop) | Modern resource monitor — CPU, memory, disk, network |
| [eza](https://github.com/eza-community/eza) | Modern `ls` replacement — icons, git status, human-readable sizes |
| [fastfetch](https://github.com/fastfetch-cli/fastfetch) | Fast system info display shown at shell startup |
| [fzf](https://github.com/junegunn/fzf) | Fuzzy finder — `Ctrl+R` history, `Ctrl+T` file picker, `Alt+C` cd |
| [gh](https://cli.github.com/) | GitHub CLI — create PRs, manage issues, clone repos from the terminal |
| [git](https://git-scm.com/) | Latest version of Git (newer than macOS built-in) |
| [GitHub Copilot CLI](https://github.com/github/copilot-cli) | GitHub Copilot coding agent for the terminal |
| [htop](https://htop.dev/) | Interactive process monitor |
| [jq](https://jqlang.github.io/jq/) | Parse and query JSON in the terminal |
| [kubectl](https://kubernetes.io/docs/reference/kubectl/) | Kubernetes CLI |
| [ncdu](https://dev.yorhel.nl/ncdu) | Disk usage visualizer in the terminal |
| [node](https://nodejs.org/) | Node.js runtime + npm |
| [OpenCode](https://github.com/anomalyco/opencode) | Open-source AI coding agent for the terminal |
| [python](https://www.python.org/) | Python 3 runtime + `pip3` |
| [ripgrep](https://github.com/BurntSushi/ripgrep) | Extremely fast grep replacement (`rg`) |
| [tree](http://mama.indstate.edu/users/ice/tree/) | Display folder structure as a tree |
| [uv](https://github.com/astral-sh/uv) | Extremely fast Python package installer and resolver — replaces `pip` and `venv` |
| [wget](https://www.gnu.org/software/wget/) | Download files from the command line |
| [zoxide](https://github.com/ajeetdsouza/zoxide) | Smarter `cd` — jumps to frequently-used directories |

---

## Firefox Extensions

Automatically installed into your Firefox profile on first run:

| Extension | Description |
|-----------|-------------|
| [Bitwarden](https://bitwarden.com/) | Open-source password manager |
| [uBlock Origin](https://ublockorigin.com/) | Best-in-class ad and tracker blocker |

The script launches Firefox headlessly to create the profile, then drops the extension `.xpi` file directly into the `extensions/` folder. It activates the next time you open Firefox — no manual steps needed.

---

## Shell aliases

The script adds the following aliases to `~/.zshrc`:

| Alias | Command | Description |
|-------|---------|-------------|
| `..` | `cd ..` | Go up one directory |
| `...` | `cd ../..` | Go up two directories |
| `....` | `cd ../../..` | Go up three directories |
| `c` | `clear` | Clear terminal |
| `cat` | `bat --paging=never` | Syntax-highlighted cat with git diff |
| `df` | `df -h` | Disk usage, human-readable |
| `du` | `du -h` | Directory sizes, human-readable |
| `grep` | `grep --color=auto` | Colourised grep output |
| `ls` | `eza -alh --icons --git` | Modern ls with icons, human sizes, and git status |
| `mkdir` | `mkdir -pv` | Create nested dirs, verbose |
| `pip` | `pip3` | Always use Python 3's pip |
| `ports` | `lsof -i -P -n \| grep LISTEN` | Show all listening ports |
| `rg` | `rg --line-number --smart-case --hidden --glob "!.git"` | ripgrep with line numbers, smart case, and hidden files |

---

## fastfetch

Displays system info (CPU, memory, OS, shell, terminal font) on every new shell session. Runs **before** the Powerlevel10k instant prompt so it doesn't trigger the console output warning.

---

## VS Code extensions

Automatically installed if the `code` CLI is on your PATH:

| Extension | Description |
|-----------|-------------|
| [Docker](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-docker) | Docker container management |
| [Prettier](https://marketplace.visualstudio.com/items?itemName=esbenp.prettier-vscode) | Code formatter |
| [Python](https://marketplace.visualstudio.com/items?itemName=ms-python.python) | Python language support, linting, debugging |
| [Remote - SSH](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-ssh) | Edit files on remote machines over SSH |

To add more, edit the `VSCODE_EXTENSIONS` array at the top of `setup.sh`.

### VS Code settings

The script also writes the following settings to `~/Library/Application Support/Code/User/settings.json`:

| Setting | Value |
|---------|-------|
| `terminal.external.osxExec` | `Terminal.app` |

Opens the built-in macOS Terminal when you use **Terminal → New External Terminal** (`⇧⌃C`) in VS Code.

---

## GitHub Copilot CLI

[GitHub Copilot CLI](https://github.com/github/copilot-cli) is installed via Homebrew:

```bash
brew install copilot-cli
```

This pairs with the `~/.agents/skills` directory and the bundled Obsidian skills setup later in the script.

---

## OpenCode

[OpenCode](https://github.com/anomalyco/opencode) is installed via Homebrew:

```bash
brew install anomalyco/tap/opencode
```

---

## Karabiner-Elements

[Karabiner-Elements](https://karabiner-elements.pqrs.org/) is installed and pre-configured to **swap Cmd and Ctrl on the external keyboard only**, leaving the internal MacBook keyboard layout completely unchanged.

This is useful when using a standard PC/Windows keyboard as an external keyboard — the physical Ctrl key sits where Mac users expect Cmd, so the swap makes it feel native.

The config targets a specific device by `vendor_id` / `product_id` and is written to `~/.config/karabiner/karabiner.json` automatically. To update the target device, edit the `configure_karabiner()` function in `setup.sh`.

---

## Claude Code

[Claude Code](https://docs.anthropic.com/en/docs/claude-code) is Anthropic's AI coding agent for the terminal. The script installs it via Homebrew Cask:

```bash
brew install --cask claude-code
```

Skipped automatically if `claude` is already in your PATH.

---

## AI agent skills directories

The script creates these directories if they don't already exist:

| Path | Used by |
|------|---------|
| `~/.copilot/skills` | GitHub Copilot CLI |
| `~/.claude/skills` | Claude Code |
| `~/.agents/skills` | General agent tooling |

### Obsidian skills

The script also clones [kepano/obsidian-skills](https://github.com/kepano/obsidian-skills) into `~/.agents/obsidian-skills` and symlinks each skill into `~/.agents/skills/<skill-name>/`. These skills teach Copilot CLI how to work with Obsidian vaults (notes, tags, links, templates, etc.). On re-runs, the clone is updated with `git pull --ff-only`.

After setup, verify the skills loaded in Copilot CLI:
```
/skills list
```

---

## SSH key

The script generates an **ed25519** SSH key at `~/.ssh/id_ed25519` (using your git email) and adds it to the macOS Keychain via `ssh-add --apple-use-keychain`. Skips if a key already exists.

After setup, copy the printed public key and add it to GitHub:
[https://github.com/settings/ssh/new](https://github.com/settings/ssh/new)

---

## Oh My Zsh & Powerlevel10k

The script automatically sets up a fully-featured zsh environment:

| Component | Description |
|-----------|-------------|
| [Oh My Zsh](https://ohmyz.sh/) | Framework that manages plugins, themes, and zsh config |
| [Powerlevel10k](https://github.com/romkatv/powerlevel10k) | Theme with git status, virtualenv, exit codes, and more |
| [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions) | Suggests commands as you type (press → to accept) |
| [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting) | Highlights valid commands green, unknown commands red |

**Plugins enabled:** `git`, `zsh-autosuggestions`, `zsh-syntax-highlighting`

On the first terminal launch after install, the bundled **`.p10k.zsh`** config is applied automatically — no wizard needed. To customise your prompt at any time:

```bash
p10k configure
```

> **Tip:** The script installs **MesloLGS Nerd Font** and configures it automatically in the built-in **macOS Terminal** (Pro profile). No manual font setup needed.

---

## Git configuration

The script sets the following global git config:

| Setting | Value |
|---------|-------|
| `user.name` | Thanh Nguyen |
| `user.email` | thanhnguyen1206@gmail.com |
| `core.editor` | VS Code (`code --wait`) |
| `init.defaultBranch` | `main` |
| `pull.rebase` | `false` |
| `core.autocrlf` | `input` |

To change these, edit the `configure_git()` function in `setup.sh`.

---

## macOS system preferences

The script applies the following system configuration automatically.

### Finder
- Allow Quit Finder with ⌘Q
- Disable window animations
- Text selection in Quick Look
- Folders on top when sorting by name
- Search defaults to current folder
- No extension-change warning
- No empty-trash warning
- Show path bar and status bar
- Column view by default
- Show all file extensions
- Show `~/Library` folder
- External drives shown on desktop; internal, servers, removable media hidden
- Spring-loading with no delay
- No `.DS_Store` files on network or USB volumes
- Skip disk image verification; auto-open Finder window on mount
- AirDrop works over Ethernet
- Icon views: item info shown, snap-to-grid, grid spacing 100, icon size 80
- Get Info panel expands General, Open With, and Sharing & Permissions

### Dock & Mission Control
- Icon size: 48px
- Scale minimize effect; minimize into app icon
- Stack hover highlight; app indicator dots
- No launch bounce animation; hidden apps show translucent icons
- Spring-loading on all Dock items
- Auto-hide with no delay, smooth animation
- Faster Mission Control animation; windows grouped by app
- Spaces not auto-reordered; Dashboard disabled
- Hot corners: top-left → Mission Control, top-right → Desktop, bottom-left → Screen Saver
- **All default pinned app icons removed** from the Dock on first run

### Keyboard & Input
- Fast key repeat (`KeyRepeat 1`, `InitialKeyRepeat 10`)
- Full keyboard access in dialogs (Tab through all controls)
- Smart quotes, smart dashes, and auto-correct disabled
- Natural scrolling disabled
- Tap-to-click enabled
- Bottom-right corner of trackpad = right-click
- Trackpad speed 2, mouse speed 2.5
- Bluetooth audio quality improved
- Keyboard backlight dims after 2 minutes

### Screen & Screenshots
- Screenshots saved to `~/Documents/Screenshots` in JPEG format, no drop shadow
- `~/Documents/Screenshots` folder created automatically if it doesn't exist
- Subpixel font rendering enabled on non-Apple LCDs

### General System
- **Computer name set to `dev-mac`** (ComputerName, HostName, LocalHostName, NetBIOSName)
- Startup chime disabled
- Sidebar icons: medium size
- No focus-ring animation; instant window resize
- Window resume on reopen disabled
- Inactive apps not auto-terminated
- Printer app quits when jobs finish
- Save and print panels expanded by default
- Files save to disk by default (not iCloud)
- Login screen shows hostname/IP when clicking the clock
- Auto-restart on system freeze
- Daily software update checks
- Duplicate "Open With" menu entries cleaned up
- Terminal set to UTF-8, Pro theme, MesloLGS Nerd Font
- Time Machine won't prompt for new disks
- Chrome back-swipe gesture disabled
- Battery percentage shown in menu bar

### Power Management
- Sudden motion sensor disabled (SSD optimisation)
- Hibernation disabled (faster sleep)
- Deep sleep (standby) delay: 24 hours

### Mail
- Send and reply animations disabled
- Emails copy as `foo@example.com` (not `Foo Bar <foo@example.com>`)
- Threaded view, sorted by received date (oldest at top)

### Safari
- Search queries not sent to Apple; Do Not Track enabled
- Fraud site warning enabled
- AutoFill disabled (address book, passwords, credit cards, forms)
- Blank start page
- Bookmarks bar and Top Sites sidebar hidden
- Downloads don't auto-open
- History thumbnail cache disabled
- Tab key highlights each element on page
- Backspace navigates back in history
- Debug menu and Develop menu enabled; Web Inspector available everywhere
- Continuous spell check; auto-correct disabled
- Plug-ins and Java disabled; pop-ups blocked
- Extensions auto-update

### Spotlight
- Search order: Apps → System Prefs → Folders → PDF → Fonts → Contacts
- Documents, messages, images, media, and web search results hidden
- Index rebuilt after configuration

### Transmission
- Incomplete downloads stored in `~/Downloads/Incomplete`
- No download location prompt
- Original `.torrent` files trashed after adding
- Donate message and legal disclaimer hidden

---

## Security — Gatekeeper & App Quarantine

The script does three things to let you open any app without warnings:

1. **Disables Gatekeeper** (`spctl --master-disable`) — removes the "app can't be opened" block
2. **Disables quarantine for new apps** (`LSQuarantine false`) — suppresses the *"downloaded from the internet"* dialog for apps you install in future
3. **Clears quarantine from existing apps** (`xattr -dr com.apple.quarantine /Applications/*`) — removes the flag from everything already installed

On macOS Ventura and later, disabling Gatekeeper requires a manual confirmation:

1. System Settings → Privacy & Security → scroll to **Security**
2. Under *Allow applications from* — select **Anywhere**

The script opens System Settings automatically and waits for you to confirm before continuing.

---

## How it works

1. Closes System Preferences (prevents it overriding settings mid-run)
2. Prompts for `sudo` once upfront
3. Installs **Xcode Command Line Tools** if missing; updates them if a newer version is available
4. Installs **Homebrew** if missing
5. `brew update` → `brew upgrade`
6. Installs all CLI tools (formulae)
7. Installs all GUI apps (casks) — skips apps already in `/Applications`
8. `brew cleanup`
9. Installs **Oh My Zsh** + **Powerlevel10k** theme + autosuggestions & syntax-highlighting plugins
10. Configures `~/.zshrc` — fastfetch (before p10k instant prompt), shell aliases, zoxide, fzf keybindings
11. Configures git global settings
12. Installs **MesloLGS Nerd Font**
13. Installs **VS Code extensions**; sets macOS Terminal as external terminal
14. Generates an **SSH key** (ed25519) and adds it to the macOS Keychain
15. Installs Firefox extensions (uBlock Origin, Bitwarden)
16. Creates `~/Documents/dev`
17. Creates AI agent skills directories (`~/.copilot/skills`, `~/.claude/skills`, `~/.agents/skills`)
18. Clones **Obsidian skills** (`kepano/obsidian-skills`) into `~/.agents/obsidian-skills/`, symlinks skills into `~/.agents/skills/`
19. Installs **Claude Code** via Homebrew Cask (`brew install --cask claude-code`)
20. Writes **Karabiner-Elements** config — swaps Cmd ↔ Ctrl on the external keyboard only
21. Applies all macOS system preferences (Finder → Transmission)
22. Configures macOS Terminal — UTF-8, Pro theme, MesloLGS Nerd Font
23. Disables Gatekeeper

---

## Adding more tools

Edit the lists at the top of `setup.sh`:

```bash
DEFAULT_CASKS=(
  ...
  your-app-name     # GUI app
)

DEFAULT_FORMULAE=(
  ...
  your-tool-name    # CLI tool
)
```

Find Homebrew package names at [formulae.brew.sh](https://formulae.brew.sh/).
