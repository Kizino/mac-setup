#!/usr/bin/env bash
# ##############################################################################
#
#  mac-reforge — New Mac installer
#
#  Usage:
#    ./setup.sh            install everything
#    DRY_RUN=1 ./setup.sh  preview without making changes
#    ./setup.sh firefox    install a specific app only
#
#  Sections (in order):
#    1. Configuration        — DEFAULT_CASKS / DEFAULT_FORMULAE / VSCODE_EXTENSIONS
#    2. Utilities            — log(), run(), run_soft()
#    3. Homebrew             — helpers, prerequisites, install functions
#    4. Shell Setup          — Oh My Zsh, Powerlevel10k, zsh plugins, .zshrc aliases
#    5. Developer Tools      — git, VS Code extensions, SSH key, Firefox extensions,
#                              dev folder, AI skills dirs, Obsidian skills, Claude Code
#    6. macOS Preferences    — Computer Name, Finder, Dock, Keyboard, Screen, System,
#                              Power, Mail, Safari, Spotlight, Transmission
#    7. Security             — Gatekeeper
#    8. Entry Point          — main()
#
# ##############################################################################

set -euo pipefail

[[ "${OSTYPE:-}" == darwin* ]] || { echo "This script only supports macOS." >&2; exit 1; }

# ==============================================================================
# 1. CONFIGURATION
# ==============================================================================

DEFAULT_CASKS=(
  firefox              # Web browser
  visual-studio-code   # Code editor
  docker               # Container platform (includes docker CLI + compose)
  bruno                # API client
  discord              # Voice, video & text chat
  lm-studio            # Run local AI/LLM models
  obsidian             # Markdown note-taking & knowledge base
)

DEFAULT_FORMULAE=(
  bat        # Better cat — syntax highlighting, line numbers, git diff
  btop       # Modern resource monitor
  eza        # Modern ls replacement with icons and git status
  fastfetch  # Fast system info display (shown at shell startup)
  fzf        # Fuzzy finder for the terminal
  gh         # GitHub CLI — create PRs, manage issues, clone repos
  git        # Latest version of Git
  htop       # Interactive process monitor
  jq         # JSON parser for the terminal
  kubectl    # Kubernetes CLI
  ncdu       # Disk usage visualizer
  node       # Node.js runtime + npm (required for Claude Code and JS tooling)
  python     # Python 3 + pip3
  ripgrep    # Extremely fast grep replacement (rg)
  tree       # Display folder structure as a tree
  uv         # Extremely fast Python package installer and resolver (replaces pip/venv)
  wget       # File downloader
  zoxide     # Smarter cd — jumps to frequent directories
)

VSCODE_EXTENSIONS=(
  ms-vscode-remote.remote-ssh   # SSH remote development
  ms-python.python              # Python language support
  esbenp.prettier-vscode        # Code formatter
  ms-azuretools.vscode-docker   # Docker support
)

# ==============================================================================
# 2. UTILITIES
# ==============================================================================

log() { printf '\n==> %s\n' "$*"; }

run() {
  if [[ "${DRY_RUN:-0}" == "1" ]]; then
    printf '[dry-run]'; printf ' %q' "$@"; printf '\n'; return 0
  fi
  "$@"
}

# Like run(), but silently skips if the command fails (for permission-gated settings)
run_soft() {
  if [[ "${DRY_RUN:-0}" == "1" ]]; then
    printf '[dry-run]'; printf ' %q' "$@"; printf '\n'; return 0
  fi
  "$@" 2>/dev/null || true
}

# ==============================================================================
# 3. HOMEBREW
# ==============================================================================

# ── App name helpers ───────────────────────────────────────────────────────

normalize_cask() {
  local n
  n="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')"
  case "$n" in
    firefox)                          echo "firefox" ;;
    code|vscode|vs-code|visual-studio-code) echo "visual-studio-code" ;;
    docker|docker-desktop)            echo "docker" ;;
    *)                                echo "$1" ;;
  esac
}

app_bundle_name() {
  case "$1" in
    firefox)            echo "Firefox.app" ;;
    visual-studio-code) echo "Visual Studio Code.app" ;;
    docker)             echo "Docker.app" ;;
    bruno)              echo "Bruno.app" ;;
    lm-studio)          echo "LM Studio.app" ;;
    obsidian)           echo "Obsidian.app" ;;
    *)                  return 1 ;;
  esac
}

app_already_present() {
  local bundle
  app_bundle_name "$1" > /dev/null 2>&1 || return 1
  bundle="$(app_bundle_name "$1")"
  [[ -e "/Applications/$bundle" || -e "$HOME/Applications/$bundle" ]]
}

# ── Prerequisites ──────────────────────────────────────────────────────────

load_brew() {
  if   [[ -x /opt/homebrew/bin/brew ]]; then eval "$(/opt/homebrew/bin/brew shellenv)"; return 0
  elif [[ -x /usr/local/bin/brew    ]]; then eval "$(/usr/local/bin/brew shellenv)";    return 0
  fi
  return 1
}

ensure_command_line_tools() {
  xcode-select -p >/dev/null 2>&1 && return 0
  log "Installing Xcode Command Line Tools..."
  run xcode-select --install
  echo "Finish the CLT installation popup, then rerun this script." >&2
  exit 1
}

ensure_homebrew() {
  load_brew && return 0
  log "Installing Homebrew..."
  run /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  load_brew || { echo "Homebrew installed but brew not found." >&2; exit 1; }
}

# ── Install functions ──────────────────────────────────────────────────────

install_formula() {
  local f="$1"
  brew list --formula "$f" >/dev/null 2>&1 && { log "$f is already installed."; return 0; }
  log "Installing $f..."
  run brew install "$f"
}

install_cask() {
  local c="$1"
  brew list --cask "$c" >/dev/null 2>&1 && { log "$c is already installed."; return 0; }
  app_already_present "$c"             && { log "$c already in /Applications. Skipping."; return 0; }
  log "Installing $c..."
  run brew install --cask "$c"
}

# ==============================================================================
# 4. SHELL SETUP
# ==============================================================================

configure_oh_my_zsh() {
  local zshrc="$HOME/.zshrc"
  local omz_dir="$HOME/.oh-my-zsh"
  local custom_dir="$omz_dir/custom"

  # Install Oh My Zsh (unattended — no shell switch, no auto-launch)
  if [[ -d "$omz_dir" ]]; then
    log "Oh My Zsh already installed."
  else
    log "Installing Oh My Zsh..."
    run env RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  fi

  # Install Powerlevel10k theme
  local p10k_dir="$custom_dir/themes/powerlevel10k"
  if [[ -d "$p10k_dir" ]]; then
    log "Powerlevel10k already installed."
  else
    log "Installing Powerlevel10k theme..."
    run git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$p10k_dir"
  fi

  # Install zsh-autosuggestions plugin
  local autosugg_dir="$custom_dir/plugins/zsh-autosuggestions"
  if [[ -d "$autosugg_dir" ]]; then
    log "zsh-autosuggestions already installed."
  else
    log "Installing zsh-autosuggestions..."
    run git clone https://github.com/zsh-users/zsh-autosuggestions "$autosugg_dir"
  fi

  # Install zsh-syntax-highlighting plugin
  local syntax_dir="$custom_dir/plugins/zsh-syntax-highlighting"
  if [[ -d "$syntax_dir" ]]; then
    log "zsh-syntax-highlighting already installed."
  else
    log "Installing zsh-syntax-highlighting..."
    run git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$syntax_dir"
  fi

  # Set theme and plugins in .zshrc (Oh My Zsh creates this file during install)
  if [[ "${DRY_RUN:-0}" != "1" ]]; then
    sed -i '' 's|^ZSH_THEME=.*|ZSH_THEME="powerlevel10k/powerlevel10k"|' "$zshrc"
    sed -i '' 's|^plugins=.*|plugins=(git zsh-autosuggestions zsh-syntax-highlighting)|' "$zshrc"
    log "ZSH_THEME and plugins configured."
  else
    printf '[dry-run] sed ZSH_THEME → powerlevel10k/powerlevel10k\n'
    printf '[dry-run] sed plugins → (git zsh-autosuggestions zsh-syntax-highlighting)\n'
  fi

  # Apply bundled p10k config (skips the interactive wizard)
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  local p10k_src="$script_dir/.p10k.zsh"
  local p10k_dest="$HOME/.p10k.zsh"
  if [[ -f "$p10k_src" ]]; then
    if [[ ! -f "$p10k_dest" ]]; then
      log "Applying bundled Powerlevel10k config..."
      run cp "$p10k_src" "$p10k_dest"
    else
      log "~/.p10k.zsh already exists — skipping (run 'p10k configure' to regenerate)."
    fi
  fi

  # Add p10k config source line to .zshrc
  local p10k_line='[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh'
  grep -qF "$p10k_line" "$zshrc" 2>/dev/null || \
    printf '\n# Powerlevel10k config (added by mac-reforge)\n%s\n' "$p10k_line" >> "$zshrc"

  log "Oh My Zsh + Powerlevel10k ready. Open a new terminal to see your prompt."
}

configure_zshrc() {
  local zshrc="$HOME/.zshrc"

  # ── fastfetch (must run BEFORE p10k instant prompt preamble)
  # p10k warns about console I/O that happens after its preamble is sourced.
  # Running fastfetch before the preamble is the recommended fix per p10k docs.
  local fastfetch_marker='# fastfetch — system info at shell startup (added by mac-reforge)'
  if grep -qE '^fastfetch$' "$zshrc" 2>/dev/null; then
    log "fastfetch already in ~/.zshrc."
  else
    log "Adding fastfetch to ~/.zshrc (before p10k preamble)..."
    local p10k_marker='# Enable Powerlevel10k instant prompt'
    if [[ "${DRY_RUN:-0}" != "1" ]]; then
      if grep -qF "$p10k_marker" "$zshrc" 2>/dev/null; then
        # Insert before the p10k preamble block
        sed -i '' "s|${p10k_marker}|${fastfetch_marker}\nfastfetch\n\n${p10k_marker}|" "$zshrc"
      else
        # Prepend to top of file if preamble not found
        local tmp; tmp="$(mktemp)"
        { printf '%s\nfastfetch\n\n' "$fastfetch_marker"; cat "$zshrc"; } > "$tmp" && mv "$tmp" "$zshrc"
      fi
    else
      printf '[dry-run] insert fastfetch before p10k preamble in ~/.zshrc\n'
    fi
  fi

  # ── Shell aliases
  local alias_marker='# Shell aliases (added by mac-reforge)'
  if grep -qF "$alias_marker" "$zshrc" 2>/dev/null; then
    log "Shell aliases already in ~/.zshrc."
  else
    log "Adding shell aliases to ~/.zshrc..."
    cat >> "$zshrc" << 'EOF'

# Shell aliases (added by mac-reforge)
alias ls='eza -alh --icons --git'   # modern ls: icons, human sizes, git status
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias grep='grep --color=auto'
alias cat='bat --paging=never'      # modern cat: syntax highlighting + git diff
alias mkdir='mkdir -pv'
alias df='df -h'
alias du='du -h'
alias c='clear'
alias ports='lsof -i -P -n | grep LISTEN'  # show listening ports
alias pip='pip3'
alias rg='rg --line-number --smart-case --hidden --glob "!.git"'  # ripgrep with sane defaults
EOF
  fi

  # ── pip -> pip3 alias (backfill for installs that predate this entry)
  if ! grep -qF "alias pip='pip3'" "$zshrc" 2>/dev/null; then
    log "Adding pip -> pip3 alias to ~/.zshrc..."
    printf "\nalias pip='pip3'\n" >> "$zshrc"
  fi

  # ── zoxide (smarter cd)
  local zoxide_line='eval "$(zoxide init zsh)"'
  if grep -qF "$zoxide_line" "$zshrc" 2>/dev/null; then
    log "zoxide already in ~/.zshrc."
  else
    log "Adding zoxide to ~/.zshrc..."
    printf '\n# zoxide — smarter cd (added by mac-reforge)\neval "$(zoxide init zsh)"\n' >> "$zshrc"
  fi

  # ── fzf shell keybindings (Ctrl+R history, Ctrl+T file search, Alt+C cd)
  local fzf_marker='# fzf keybindings (added by mac-reforge)'
  if grep -qF "$fzf_marker" "$zshrc" 2>/dev/null; then
    log "fzf keybindings already in ~/.zshrc."
  else
    log "Configuring fzf shell keybindings..."
    local fzf_setup="$(brew --prefix)/opt/fzf/install"
    if [[ -x "$fzf_setup" ]]; then
      run "$fzf_setup" --all --no-bash --no-fish
    else
      log "WARNING: fzf install script not found — skipping keybindings setup."
    fi
    printf '\n%s\n' "$fzf_marker" >> "$zshrc"
  fi
}

# ==============================================================================
# 5. DEVELOPER TOOLS
# ==============================================================================

configure_git() {
  log "Configuring git..."
  run git config --global user.name        "Thanh Nguyen"
  run git config --global user.email       "thanhnguyen1206@gmail.com"
  run git config --global core.editor      "code --wait"
  run git config --global init.defaultBranch main
  run git config --global pull.rebase      false
  run git config --global core.autocrlf    input
}

install_nerd_font() {
  # Install the Nerd Font required for Powerlevel10k icons
  local font_cask="font-meslo-lg-nerd-font"
  if brew list --cask "$font_cask" >/dev/null 2>&1; then
    log "MesloLGS Nerd Font already installed."
  else
    log "Installing MesloLGS Nerd Font (required for Powerlevel10k icons)..."
    run brew install --cask "$font_cask"
  fi
}

configure_vscode() {
  command -v code >/dev/null 2>&1 || { log "VS Code CLI (code) not found — skipping."; return 0; }

  log "Installing VS Code extensions..."
  for ext in "${VSCODE_EXTENSIONS[@]}"; do
    run code --install-extension "$ext" --force
  done

  log "Configuring VS Code settings..."
  local settings_dir="$HOME/Library/Application Support/Code/User"
  local settings_file="$settings_dir/settings.json"
  run mkdir -p "$settings_dir"

  python3 - "$settings_file" << 'PYEOF'
import json, sys, os

path = sys.argv[1]
settings = {}
if os.path.exists(path):
    with open(path) as f:
        try:
            settings = json.load(f)
        except json.JSONDecodeError:
            pass

settings["terminal.external.osxExec"] = "Terminal.app"

with open(path, "w") as f:
    json.dump(settings, f, indent=2)
    f.write("\n")

print("VS Code external terminal set to Terminal.app")
PYEOF
}

configure_ssh_key() {
  local key_file="$HOME/.ssh/id_ed25519"

  if [[ -f "$key_file" ]]; then
    log "SSH key already exists at $key_file — skipping."
    return 0
  fi

  local git_email
  git_email="$(git config --global user.email 2>/dev/null || echo 'thanhnguyen1206@gmail.com')"

  log "Generating SSH key (ed25519) for $git_email..."
  run mkdir -p "$HOME/.ssh"
  run chmod 700 "$HOME/.ssh"
  run ssh-keygen -t ed25519 -C "$git_email" -N "" -f "$key_file"
  run ssh-add --apple-use-keychain "$key_file"

  log "SSH key generated. Add your public key to GitHub:"
  log "  https://github.com/settings/ssh/new"
  printf '\n%s\n\n' "$(cat "$key_file.pub")"
}

install_firefox_extensions() {
  local firefox_bin="/Applications/Firefox.app/Contents/MacOS/firefox"
  local profiles_dir="$HOME/Library/Application Support/Firefox/Profiles"

  [[ -x "$firefox_bin" ]] || { log "Firefox not found, skipping extensions."; return 0; }

  if [[ ! -d "$profiles_dir" ]]; then
    log "Launching Firefox headless to create profile..."
    "$firefox_bin" -headless &
    local ff_pid=$!
    sleep 5
    kill "$ff_pid" 2>/dev/null || true
    sleep 1
  fi

  local profile_dir
  profile_dir="$(find "$profiles_dir" -maxdepth 1 -type d -name "*default-release" 2>/dev/null | head -1)"
  [[ -z "$profile_dir" ]] && profile_dir="$(find "$profiles_dir" -maxdepth 1 -type d ! -name "Profiles" 2>/dev/null | head -1)"
  [[ -z "$profile_dir" ]] && { log "Firefox profile not found, skipping extensions."; return 0; }

  local ext_dir="$profile_dir/extensions"
  local ublock="$ext_dir/uBlock0@raymondhill.net.xpi"
  local bitwarden="$ext_dir/{446900e4-71c2-419f-a6a7-df9c091e268b}.xpi"
  run mkdir -p "$ext_dir"

  if [[ ! -f "$ublock" ]]; then
    log "Installing uBlock Origin..."
    run curl -sSL -o "$ublock" "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi"
    log "uBlock Origin will activate on next Firefox launch."
  else
    log "uBlock Origin already installed."
  fi

  if [[ ! -f "$bitwarden" ]]; then
    log "Installing Bitwarden..."
    run curl -sSL -o "$bitwarden" "https://addons.mozilla.org/firefox/downloads/latest/bitwarden-password-manager/latest.xpi"
    log "Bitwarden will activate on next Firefox launch."
  else
    log "Bitwarden already installed."
  fi
}

configure_dev_folder() {
  local dir="$HOME/Documents/dev"
  [[ -d "$dir" ]] && { log "~/Documents/dev already exists."; return 0; }
  log "Creating ~/Documents/dev..."
  run mkdir -p "$dir"
}

configure_ai_skills_dirs() {
  log "Creating AI agent skills directories..."
  for dir in \
    "$HOME/.copilot/skills" \
    "$HOME/.claude/skills" \
    "$HOME/.agents/skills"; do
    if [[ -d "$dir" ]]; then
      log "$dir already exists — skipping."
    else
      log "Creating $dir..."
      run mkdir -p "$dir"
    fi
  done
}

install_obsidian_skills() {
  local dest="$HOME/.copilot/skills/obsidian-skills"

  if [[ -d "$dest/.git" ]]; then
    log "Obsidian skills already installed — pulling latest..."
    run git -C "$dest" pull --ff-only
    return 0
  fi

  log "Installing Obsidian skills for Copilot CLI..."
  run mkdir -p "$HOME/.copilot/skills"
  run git clone https://github.com/kepano/obsidian-skills.git "$dest"
}

install_claude_code() {
  if command -v claude >/dev/null 2>&1; then
    log "Claude Code already installed — skipping."
    return 0
  fi

  if ! command -v npm >/dev/null 2>&1; then
    log "npm not found — skipping Claude Code install."
    return 0
  fi

  log "Installing Claude Code..."
  run npm install -g @anthropic-ai/claude-code
}

configure_eza() {
  # On macOS, eza reads its theme from ~/Library/Application Support/eza/theme.yml
  # (the platform-native XDG_CONFIG_HOME equivalent).
  local eza_config_dir="$HOME/Library/Application Support/eza"
  local theme_file="$eza_config_dir/theme.yml"

  if [[ -f "$theme_file" ]]; then
    log "eza theme already configured — skipping."
    return 0
  fi

  log "Configuring eza icon theme..."
  run mkdir -p "$eza_config_dir"

  # Write theme using a temp variable to allow run() to handle DRY_RUN mode.
  if [[ "${DRY_RUN:-0}" == "1" ]]; then
    printf '[dry-run] write eza theme to %s\n' "$theme_file"
    return 0
  fi

  cat > "$theme_file" << 'THEME_EOF'
# eza icon overrides — Nerd Fonts v3 (nf-md-* range)
# Edit glyphs at: https://www.nerdfonts.com/cheat-sheet
filenames:
  .git:      {icon: {glyph: 󰊢}}
  .github:   {icon: {glyph: 󰊤}}
  .obsidian: {icon: {glyph: 󱓅}}
  .p10k.zsh: {icon: {glyph: 󱐋}}

extensions:
  md:  {icon: {glyph: 󰍔}}
  sh:  {icon: {glyph: 󰆍}}
  zsh: {icon: {glyph: 󰆍}}
THEME_EOF
}

# ==============================================================================
# 6. MACOS PREFERENCES
# ==============================================================================

# ── Finder ────────────────────────────────────────────────────────────────

configure_finder() {
  log "Configuring Finder..."

  # Behaviour
  run defaults write com.apple.finder QuitMenuItem                    -bool true   # Allow Cmd+Q to quit Finder
  run defaults write com.apple.finder DisableAllAnimations            -bool true   # Disable window animations
  run defaults write com.apple.finder QLEnableTextSelection           -bool true   # Text selection in Quick Look
  run defaults write com.apple.finder _FXSortFoldersFirst             -bool true   # Folders on top when sorting
  run defaults write com.apple.finder FXDefaultSearchScope            -string "SCcf" # Search current folder by default
  run defaults write com.apple.finder FXEnableExtensionChangeWarning  -bool false  # No extension-change warning
  run defaults write com.apple.finder WarnOnEmptyTrash                -bool false  # No empty-trash warning

  # Visibility
  run defaults write com.apple.finder ShowPathbar                     -bool true   # Path bar at bottom
  run defaults write com.apple.finder ShowStatusBar                   -bool true   # Status bar at bottom
  run defaults write com.apple.finder FXPreferredViewStyle            Clmv         # Column view by default
  run defaults write NSGlobalDomain   AppleShowAllExtensions          -bool true   # Show all file extensions
  run chflags nohidden ~/Library                                                   # Show ~/Library folder

  # Desktop icons
  run defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool true   # External drives on desktop
  run defaults write com.apple.finder ShowHardDrivesOnDesktop         -bool false  # Hide internal drives on desktop
  run defaults write com.apple.finder ShowMountedServersOnDesktop     -bool false  # Hide servers on desktop
  run defaults write com.apple.finder ShowRemovableMediaOnDesktop     -bool false  # Hide removable media on desktop

  # Spring loading (hold over a folder to open it)
  run defaults write NSGlobalDomain com.apple.springing.enabled       -bool true
  run defaults write NSGlobalDomain com.apple.springing.delay         -float 0    # No spring-load delay

  # No .DS_Store on network or USB volumes
  run defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
  run defaults write com.apple.desktopservices DSDontWriteUSBStores     -bool true

  # Disk images: skip verification and auto-open Finder window on mount
  run defaults write com.apple.frameworks.diskimages skip-verify        -bool true
  run defaults write com.apple.frameworks.diskimages skip-verify-locked -bool true
  run defaults write com.apple.frameworks.diskimages skip-verify-remote -bool true
  run defaults write com.apple.frameworks.diskimages auto-open-ro-root  -bool true
  run defaults write com.apple.frameworks.diskimages auto-open-rw-root  -bool true
  run defaults write com.apple.finder OpenWindowForNewRemovableDisk     -bool true

  # AirDrop over Ethernet and on unsupported Macs
  run defaults write com.apple.NetworkBrowser BrowseAllInterfaces -bool true

  # Icon view: show item info, snap-to-grid, grid spacing, icon size
  run /usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:showItemInfo true"    ~/Library/Preferences/com.apple.finder.plist
  run /usr/libexec/PlistBuddy -c "Set :FK_StandardViewSettings:IconViewSettings:showItemInfo true" ~/Library/Preferences/com.apple.finder.plist
  run /usr/libexec/PlistBuddy -c "Set :StandardViewSettings:IconViewSettings:showItemInfo true"   ~/Library/Preferences/com.apple.finder.plist
  run /usr/libexec/PlistBuddy -c "Set DesktopViewSettings:IconViewSettings:labelOnBottom false"   ~/Library/Preferences/com.apple.finder.plist
  run /usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:arrangeBy grid"       ~/Library/Preferences/com.apple.finder.plist
  run /usr/libexec/PlistBuddy -c "Set :FK_StandardViewSettings:IconViewSettings:arrangeBy grid"   ~/Library/Preferences/com.apple.finder.plist
  run /usr/libexec/PlistBuddy -c "Set :StandardViewSettings:IconViewSettings:arrangeBy grid"      ~/Library/Preferences/com.apple.finder.plist
  run /usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:gridSpacing 100"      ~/Library/Preferences/com.apple.finder.plist
  run /usr/libexec/PlistBuddy -c "Set :FK_StandardViewSettings:IconViewSettings:gridSpacing 100"  ~/Library/Preferences/com.apple.finder.plist
  run /usr/libexec/PlistBuddy -c "Set :StandardViewSettings:IconViewSettings:gridSpacing 100"     ~/Library/Preferences/com.apple.finder.plist
  run /usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:iconSize 80"          ~/Library/Preferences/com.apple.finder.plist
  run /usr/libexec/PlistBuddy -c "Set :FK_StandardViewSettings:IconViewSettings:iconSize 80"      ~/Library/Preferences/com.apple.finder.plist
  run /usr/libexec/PlistBuddy -c "Set :StandardViewSettings:IconViewSettings:iconSize 80"         ~/Library/Preferences/com.apple.finder.plist

  # Expand General, Open With, and Sharing & Permissions in File Info (Cmd+I)
  run defaults write com.apple.finder FXInfoPanesExpanded -dict \
    General -bool true OpenWith -bool true Privileges -bool true

  run osascript -e 'tell application "Finder" to quit' 2>/dev/null || true
}

# ── Dock & Mission Control ────────────────────────────────────────────────

configure_dock() {
  log "Configuring Dock & Mission Control..."

  run defaults write com.apple.dock tilesize                                -int   48       # Icon size: 48px
  run defaults write com.apple.dock mineffect                               -string "scale" # Scale minimize effect
  run defaults write com.apple.dock minimize-to-application                 -bool  true     # Minimize into app icon
  run defaults write com.apple.dock mouse-over-hilite-stack                 -bool  true     # Highlight stacks on hover
  run defaults write com.apple.dock show-process-indicators                 -bool  true     # Dots for open apps
  run defaults write com.apple.dock launchanim                              -bool  false    # No launch bounce animation
  run defaults write com.apple.dock showhidden                              -bool  true     # Translucent icons for hidden apps
  run defaults write com.apple.dock enable-spring-load-actions-on-all-items -bool  true     # Spring-load all Dock items

  # Auto-hide
  run defaults write com.apple.dock autohide                  -bool  true  # Auto-hide Dock
  run defaults write com.apple.dock autohide-delay            -float 0     # No auto-hide delay
  run defaults write com.apple.dock autohide-time-modifier    -float 0.5   # Smooth show/hide animation

  # Mission Control & Spaces
  run defaults write com.apple.dock expose-animation-duration -float 0.1  # Faster Mission Control animation
  run defaults write com.apple.dock "expose-group-by-app"     -bool  true  # Group Mission Control by app
  run defaults write com.apple.dock mru-spaces                -bool  false # Don't reorder Spaces automatically
  run defaults write com.apple.dashboard mcx-disabled         -bool  true  # Disable Dashboard
  run defaults write com.apple.dock dashboard-in-overlay      -bool  true  # Don't show Dashboard as a Space

  # Hot corners — values: 2=Mission Control  4=Desktop  5=Screen saver
  run defaults write com.apple.dock wvous-tl-corner   -int 2  # Top-left  → Mission Control
  run defaults write com.apple.dock wvous-tl-modifier -int 0
  run defaults write com.apple.dock wvous-tr-corner   -int 4  # Top-right → Desktop
  run defaults write com.apple.dock wvous-tr-modifier -int 0
  run defaults write com.apple.dock wvous-bl-corner   -int 5  # Bot-left  → Screen saver
  run defaults write com.apple.dock wvous-bl-modifier -int 0

  # Reset Launchpad layout (keeps wallpaper)
  run find "${HOME}/Library/Application Support/Dock" -name "*-*.db" -maxdepth 1 -delete 2>/dev/null || true

  run osascript -e 'tell application "Dock" to quit' 2>/dev/null || true
}

# ── Keyboard & Input ─────────────────────────────────────────────────────

configure_keyboard() {
  log "Configuring keyboard & input..."

  # Key repeat
  run defaults write NSGlobalDomain ApplePressAndHoldEnabled             -bool false # Key repeat instead of accent popup
  run defaults write NSGlobalDomain KeyRepeat                            -int  1     # Blazingly fast repeat rate
  run defaults write NSGlobalDomain InitialKeyRepeat                     -int  20    # Short delay before repeat starts (~300ms)

  # Full keyboard access & control
  run defaults write NSGlobalDomain AppleKeyboardUIMode                  -int  3     # Tab through all controls in dialogs

  # Smart substitutions — off (annoying when coding)
  run defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled   -bool false
  run defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled    -bool false
  run defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled  -bool false # Disable auto-correct

  # Scrolling
  run defaults write NSGlobalDomain com.apple.swipescrolldirection       -bool false # Disable natural (Lion) scrolling

  # Trackpad
  run defaults write -g com.apple.trackpad.scaling 2                                 # Trackpad speed
  run defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true # Tap to click
  run defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadCornerSecondaryClick -int 2
  run defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadRightClick           -bool true
  run defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior    -int 1
  run defaults write NSGlobalDomain             com.apple.mouse.tapBehavior     -int 1
  run defaults -currentHost write NSGlobalDomain com.apple.trackpad.trackpadCornerClickBehavior -int 1
  run defaults -currentHost write NSGlobalDomain com.apple.trackpad.enableSecondaryClick        -bool true

  # Mouse
  run defaults write -g com.apple.mouse.scaling 2.5                                  # Mouse speed

  # Bluetooth audio quality
  run defaults write com.apple.BluetoothAudioAgent "Apple Bitpool Min (editable)" -int 40

  # Keyboard backlight: dim after 2 minutes of inactivity
  run defaults write com.apple.BezelServices kDimTime -int 120
}

# ── Screen & Screenshots ─────────────────────────────────────────────────

configure_screen() {
  log "Configuring screen & screenshots..."

  # Create Screenshots folder if it doesn't exist
  run mkdir -p "$HOME/Documents/Screenshots"

  run defaults write com.apple.screencapture location       -string "$HOME/Documents/Screenshots" # Save to Documents/Screenshots
  run defaults write com.apple.screencapture type           -string "jpg"                         # JPEG format
  run defaults write com.apple.screencapture disable-shadow -bool true                            # No drop shadow in screenshots
  run defaults write NSGlobalDomain AppleFontSmoothing      -int  2                               # Subpixel font rendering on LCD

  # Reload screencapture to apply new location immediately
  run killall SystemUIServer 2>/dev/null || true

  # Show battery percentage in menu bar
  run defaults write com.apple.controlcenter "NSStatusItem Visible Battery" -bool true
  run defaults -currentHost write com.apple.controlcenter Battery            -int 1        # Show battery in menu bar
  run defaults write com.apple.menuextra.battery ShowPercent                 -string "YES" # Show percentage (all macOS versions)

}
# ── Terminal ─────────────────────────────────────────────────────────────

configure_terminal() {
  log "Configuring Terminal..."

  run defaults write com.apple.terminal StringEncodings -array 4           # UTF-8 only
  run defaults write com.apple.Terminal "Default Window Settings" -string "Pro"
  run defaults write com.apple.Terminal "Startup Window Settings" -string "Pro"

  # Apply One Dark theme + MesloLGS Nerd Font to the Pro profile
  python3 - << 'PYEOF'
import plistlib, subprocess, sys, tempfile, os

def hex_to_rgb(h):
    h = h.lstrip('#')
    return tuple(int(h[i:i+2], 16) / 255 for i in (0, 2, 4))

def make_color(r, g, b):
    return plistlib.dumps({
        "$version":  100000,
        "$archiver": "NSKeyedArchiver",
        "$top":      {"root": plistlib.UID(1)},
        "$objects": [
            "$null",
            {"NSColorSpace": 1, "NSRGB": f"{r:.8f} {g:.8f} {b:.8f}".encode() + b"\x00", "$class": plistlib.UID(2)},
            {"$classname": "NSColor", "$classes": ["NSColor", "NSObject"]},
        ],
    }, fmt=plistlib.FMT_BINARY)

def c(hex_): return make_color(*hex_to_rgb(hex_))

def make_font(name, size):
    return plistlib.dumps({
        "$version":  100000,
        "$archiver": "NSKeyedArchiver",
        "$top":      {"root": plistlib.UID(1)},
        "$objects": [
            "$null",
            {"NSSize": size, "NSfFlags": 16, "NSName": plistlib.UID(2), "$class": plistlib.UID(3)},
            name,
            {"$classname": "NSFont", "$classes": ["NSFont", "NSObject"]},
        ],
    }, fmt=plistlib.FMT_BINARY)

result = subprocess.run(["defaults", "export", "com.apple.Terminal", "-"], capture_output=True)
if result.returncode != 0:
    sys.exit(0)

prefs = plistlib.loads(result.stdout)
window_settings = prefs.setdefault("Window Settings", {})

# Apply MesloLGS Nerd Font to every existing profile so no matter which
# profile is active the icons render correctly.
for profile in window_settings.values():
    if isinstance(profile, dict):
        profile["Font"]         = make_font("MesloLGSNF-Regular", 13.0)
        profile["FontAntialias"] = True

pro = window_settings.setdefault("Pro", {})

pro.update({
    # Font (also set explicitly on Pro in case it was just created above)
    "Font":                    make_font("MesloLGSNF-Regular", 13.0),
    "FontAntialias":           True,
    # One Dark colours
    "BackgroundColor":         c("#282C34"),
    "TextColor":               c("#ABB2BF"),
    "TextBoldColor":           c("#E5E5E5"),
    "CursorColor":             c("#528BFF"),
    "SelectionColor":          c("#3E4451"),
    "ANSIBlackColor":          c("#3F4451"),
    "ANSIRedColor":            c("#E06C75"),
    "ANSIGreenColor":          c("#98C379"),
    "ANSIYellowColor":         c("#E5C07B"),
    "ANSIBlueColor":           c("#61AFEF"),
    "ANSIMagentaColor":        c("#C678DD"),
    "ANSICyanColor":           c("#56B6C2"),
    "ANSIWhiteColor":          c("#ABB2BF"),
    "ANSIBrightBlackColor":    c("#4F5666"),
    "ANSIBrightRedColor":      c("#E06C75"),
    "ANSIBrightGreenColor":    c("#98C379"),
    "ANSIBrightYellowColor":   c("#E5C07B"),
    "ANSIBrightBlueColor":     c("#4DC4FF"),
    "ANSIBrightMagentaColor":  c("#C678DD"),
    "ANSIBrightCyanColor":     c("#56B6C2"),
    "ANSIBrightWhiteColor":    c("#FFFFFF"),
    # Window size
    "columnCount":             120,
    "rowCount":                35,
})

with tempfile.NamedTemporaryFile(suffix=".plist", delete=False) as tmp:
    plistlib.dump(prefs, tmp, fmt=plistlib.FMT_BINARY)
    tmp_path = tmp.name

subprocess.run(["defaults", "import", "com.apple.Terminal", tmp_path], check=True)
os.unlink(tmp_path)
print("Terminal: MesloLGS Nerd Font applied to all profiles; Pro profile set to One Dark theme.")
PYEOF
}

# ── General System ───────────────────────────────────────────────────────

configure_system() {
  log "Configuring system preferences..."

  # Computer name
  run sudo scutil --set ComputerName  "dev-mac"
  run sudo scutil --set HostName      "dev-mac"
  run sudo scutil --set LocalHostName "dev-mac"
  run sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName -string "dev-mac"

  # Boot
  run sudo nvram StartupMute=%01                                                     # Disable startup chime (macOS Big Sur+)
  run sudo nvram SystemAudioVolume=" "                                               # Disable startup chime (legacy fallback)

  # UI / UX
  run defaults write NSGlobalDomain NSTableViewDefaultSizeMode          -int  2     # Sidebar icons: medium
  run defaults write NSGlobalDomain NSUseAnimatedFocusRing              -bool false # No focus-ring animation
  run defaults write NSGlobalDomain NSWindowResizeTime                  -float 0.001 # Instant window resize
  run defaults write NSGlobalDomain NSTextShowsControlCharacters        -bool true   # Show ASCII control characters

  # App behaviour
  run defaults write NSGlobalDomain NSQuitAlwaysKeepsWindows             -bool false # Disable window resume on reopen
  run defaults write NSGlobalDomain NSDisableAutomaticTermination        -bool true  # Keep inactive apps alive
  run defaults write com.apple.print.PrintingPrefs "Quit When Finished"  -bool true  # Auto-quit printer app
  run defaults write com.apple.helpviewer DevMode                        -bool true  # Help Viewer non-floating

  # File & Save dialogs
  run defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud    -bool false # Save to disk not iCloud
  run defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode   -bool true  # Expanded save panel
  run defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2  -bool true
  run defaults write NSGlobalDomain PMPrintingExpandedStateForPrint      -bool true  # Expanded print panel
  run defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2     -bool true

  # Login window: show IP/hostname/OS version when clicking the clock
  run sudo defaults write /Library/Preferences/com.apple.loginwindow AdminHostInfo HostName

  # Stability
  run sudo systemsetup -setrestartfreeze on 2>/dev/null || true           # Auto-restart on freeze

  # Software updates
  run defaults write com.apple.SoftwareUpdate ScheduleFrequency           -int  1   # Daily update checks

  # Remove duplicate entries from "Open With" context menu
  run /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister \
    -kill -r -domain local -domain system -domain user 2>/dev/null || true

  # Apps
  run defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup    -bool true  # No Time Machine prompts
  run defaults write com.google.Chrome AppleEnableSwipeNavigateWithScrolls -bool false # No back-swipe in Chrome
}

# ── Power Management ─────────────────────────────────────────────────────

configure_power() {
  log "Configuring power management..."

  run sudo pmset -a sms           0      # Disable sudden motion sensor (not needed on SSDs)
  run sudo pmset -a hibernatemode 0      # Disable hibernation (speeds up entering sleep)
  run sudo pmset -a standbydelay  86400  # Deep sleep delay: 24 hours instead of 1 hour
}

# ── Mail ─────────────────────────────────────────────────────────────────

configure_mail() {
  log "Configuring Mail..."

  run defaults write com.apple.mail DisableReplyAnimations           -bool true  # No reply animations
  run defaults write com.apple.mail DisableSendAnimations            -bool true  # No send animations
  run defaults write com.apple.mail AddressesIncludeNameOnPasteboard -bool false # Copy as foo@bar.com not Foo <foo@bar.com>

  # Threaded view sorted by date (oldest at top)
  run defaults write com.apple.mail DraftsViewerAttributes -dict-add "DisplayInThreadedMode" -string "yes"
  run defaults write com.apple.mail DraftsViewerAttributes -dict-add "SortedDescending"      -string "yes"
  run defaults write com.apple.mail DraftsViewerAttributes -dict-add "SortOrder"             -string "received-date"
}

# ── Safari ───────────────────────────────────────────────────────────────

configure_safari() {
  log "Configuring Safari..."
  # Safari lives in a sandboxed container on Ventura+; use run_soft so failures are silent
  osascript -e 'tell application "Safari" to quit' 2>/dev/null || true
  sleep 1

  # Privacy
  run_soft defaults write com.apple.Safari UniversalSearchEnabled                -bool false  # Don't send searches to Apple
  run_soft defaults write com.apple.Safari SuppressSearchSuggestions             -bool true
  run_soft defaults write com.apple.Safari SendDoNotTrackHTTPHeader              -bool true   # Send Do Not Track header
  run_soft defaults write com.apple.Safari WarnAboutFraudulentWebsites           -bool true   # Fraud site warning
  run_soft defaults write com.apple.Safari AutoFillFromAddressBook               -bool false  # Disable AutoFill
  run_soft defaults write com.apple.Safari AutoFillPasswords                     -bool false
  run_soft defaults write com.apple.Safari AutoFillCreditCardData                -bool false
  run_soft defaults write com.apple.Safari AutoFillMiscellaneousForms            -bool false

  # UI
  run_soft defaults write com.apple.Safari HomePage                              -string "about:blank"  # Blank start page
  run_soft defaults write com.apple.Safari ShowFavoritesBar                      -bool false  # Hide bookmarks bar
  run_soft defaults write com.apple.Safari ShowSidebarInTopSites                 -bool false  # Hide Top Sites sidebar
  run_soft defaults write com.apple.Safari AutoOpenSafeDownloads                 -bool false  # Don't auto-open downloads
  run_soft defaults write com.apple.Safari DebugSnapshotsUpdatePolicy            -int  2      # Disable thumbnail cache

  # Search
  run_soft defaults write com.apple.Safari FindOnPageMatchesWordStartsOnly       -bool false  # Find: match anywhere in word
  run_soft defaults write com.apple.Safari ProxiesInBookmarksBar                 "()"         # Remove proxy icons from bar

  # Tab navigation
  run_soft defaults write com.apple.Safari WebKitTabToLinksPreferenceKey         -bool true   # Tab highlights each item on page
  run_soft defaults write com.apple.Safari "com.apple.Safari.ContentPageGroupIdentifier.WebKit2TabsToLinks" -bool true
  run_soft defaults write com.apple.Safari "com.apple.Safari.ContentPageGroupIdentifier.WebKit2BackspaceKeyNavigationEnabled" -bool true

  # Developer tools
  run_soft defaults write com.apple.Safari IncludeInternalDebugMenu              -bool true   # Debug menu
  run_soft defaults write com.apple.Safari IncludeDevelopMenu                    -bool true   # Develop menu
  run_soft defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true
  run_soft defaults write com.apple.Safari "com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled" -bool true
  run defaults write NSGlobalDomain   WebKitDeveloperExtras                      -bool true   # Web Inspector in all webviews

  # Spell check
  run_soft defaults write com.apple.Safari WebContinuousSpellCheckingEnabled     -bool true
  run_soft defaults write com.apple.Safari WebAutomaticSpellingCorrectionEnabled -bool false  # No auto-correct

  # Security: disable plug-ins and Java
  run_soft defaults write com.apple.Safari WebKitPluginsEnabled                  -bool false
  run_soft defaults write com.apple.Safari "com.apple.Safari.ContentPageGroupIdentifier.WebKit2PluginsEnabled" -bool false
  run_soft defaults write com.apple.Safari WebKitJavaEnabled                     -bool false
  run_soft defaults write com.apple.Safari "com.apple.Safari.ContentPageGroupIdentifier.WebKit2JavaEnabled"   -bool false

  # Block pop-ups
  run_soft defaults write com.apple.Safari WebKitJavaScriptCanOpenWindowsAutomatically -bool false
  run_soft defaults write com.apple.Safari "com.apple.Safari.ContentPageGroupIdentifier.WebKit2JavaScriptCanOpenWindowsAutomatically" -bool false

  # Auto-update extensions
  run_soft defaults write com.apple.Safari InstallExtensionUpdatesAutomatically  -bool true
}

# ── Spotlight ────────────────────────────────────────────────────────────

configure_spotlight() {
  log "Configuring Spotlight..."

  run defaults write com.apple.spotlight orderedItems -array \
    '{"enabled" = 1;"name" = "APPLICATIONS";}' \
    '{"enabled" = 1;"name" = "SYSTEM_PREFS";}' \
    '{"enabled" = 1;"name" = "DIRECTORIES";}' \
    '{"enabled" = 1;"name" = "PDF";}' \
    '{"enabled" = 1;"name" = "FONTS";}' \
    '{"enabled" = 1;"name" = "CONTACT";}' \
    '{"enabled" = 0;"name" = "DOCUMENTS";}' \
    '{"enabled" = 0;"name" = "MESSAGES";}' \
    '{"enabled" = 0;"name" = "EVENT_TODO";}' \
    '{"enabled" = 0;"name" = "IMAGES";}' \
    '{"enabled" = 0;"name" = "BOOKMARKS";}' \
    '{"enabled" = 0;"name" = "MUSIC";}' \
    '{"enabled" = 0;"name" = "MOVIES";}' \
    '{"enabled" = 0;"name" = "PRESENTATIONS";}' \
    '{"enabled" = 0;"name" = "SPREADSHEETS";}' \
    '{"enabled" = 0;"name" = "SOURCE";}' \
    '{"enabled" = 0;"name" = "MENU_DEFINITION";}' \
    '{"enabled" = 0;"name" = "MENU_OTHER";}' \
    '{"enabled" = 0;"name" = "MENU_CONVERSION";}' \
    '{"enabled" = 0;"name" = "MENU_EXPRESSION";}' \
    '{"enabled" = 0;"name" = "MENU_WEBSEARCH";}' \
    '{"enabled" = 0;"name" = "MENU_SPOTLIGHT_SUGGESTIONS";}'

  # Rebuild Spotlight index
  run sudo mdutil -i on / >/dev/null 2>&1 || true
  run sudo mdutil -E /   >/dev/null 2>&1 || true
}

# ── Transmission ─────────────────────────────────────────────────────────

configure_transmission() {
  log "Configuring Transmission..."

  run defaults write org.m0k.transmission UseIncompleteDownloadFolder -bool true
  run defaults write org.m0k.transmission IncompleteDownloadFolder    -string "${HOME}/Downloads/Incomplete"
  run defaults write org.m0k.transmission DownloadAsk                 -bool false # Skip download location prompt
  run defaults write org.m0k.transmission DeleteOriginalTorrent       -bool true  # Trash .torrent files after add
  run defaults write org.m0k.transmission WarningDonate               -bool false # Hide donate message
  run defaults write org.m0k.transmission WarningLegal                -bool false # Hide legal disclaimer
}

# ==============================================================================
# 7. SECURITY
# ==============================================================================

disable_gatekeeper() {
  log "Disabling Gatekeeper..."
  sudo spctl --master-disable || true
  sudo defaults write /var/db/SystemPolicy-prefs.plist enabled -string no || true
  defaults write com.apple.LaunchServices LSQuarantine -bool false || true

  # Strip quarantine flag from all apps already in /Applications
  sudo xattr -dr com.apple.quarantine /Applications/* 2>/dev/null || true

  if spctl --status 2>&1 | grep -q "assessments enabled"; then
    echo ""
    echo "  +--------------------------------------------------------------+"
    echo "  |  ACTION REQUIRED: Gatekeeper needs manual confirmation       |"
    echo "  |                                                              |"
    echo "  |  1. System Settings will open to Privacy & Security         |"
    echo "  |  2. Scroll down to the 'Security' section                   |"
    echo "  |  3. Under 'Allow applications from' — select 'Anywhere'     |"
    echo "  |  4. Come back here and press ENTER to continue              |"
    echo "  +--------------------------------------------------------------+"
    echo ""
    open "x-apple.systempreferences:com.apple.preference.security"
    read -r -p "Press ENTER once you have allowed apps from Anywhere..."
  else
    log "Gatekeeper disabled successfully."
  fi
}

# ==============================================================================
# 8. ENTRY POINT
# ==============================================================================

main() {
  local requested_casks=()
  local requested_formulae=()
  local item

  if [[ $# -eq 0 ]]; then
    requested_casks=("${DEFAULT_CASKS[@]}")
    requested_formulae=("${DEFAULT_FORMULAE[@]}")
  else
    for item in "$@"; do
      requested_casks+=("$(normalize_cask "$item")")
    done
  fi

  # ── Full Disk Access check ────────────────────────────────────────────────
  # macOS blocks `defaults write` on protected domains unless the terminal has
  # Full Disk Access. Detect by probing the TCC database (readable only with FDA).
  if ! cat "$HOME/Library/Application Support/com.apple.TCC/TCC.db" >/dev/null 2>&1; then
    echo ""
    echo "  +----------------------------------------------------------------+"
    echo "  |  ACTION REQUIRED: Full Disk Access needed                      |"
    echo "  |                                                                |"
    echo "  |  macOS will block many system preference changes unless your   |"
    echo "  |  terminal app has Full Disk Access.                            |"
    echo "  |                                                                |"
    echo "  |  1. System Settings will open to Privacy & Security           |"
    echo "  |  2. Click 'Full Disk Access'                                   |"
    echo "  |  3. Enable your terminal app (e.g. Terminal)                   |"
    echo "  |  4. Come back here and press ENTER to continue                |"
    echo "  +----------------------------------------------------------------+"
    echo ""
    open "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles"
    read -r -p "Press ENTER once Full Disk Access is granted..."
  fi

  # Close System Preferences to prevent it overriding our settings
  osascript -e 'tell application "System Preferences" to quit' 2>/dev/null || true

  # Ask for sudo upfront and keep the ticket alive for the duration of the script
  sudo -v
  while true; do sudo -n true; sleep 60; kill -0 "$$" 2>/dev/null || exit; done &
  SUDO_KEEPALIVE_PID=$!

  # ── Prerequisites ──────────────────────────────────────────────────────────
  ensure_command_line_tools
  ensure_homebrew

  # ── Packages ───────────────────────────────────────────────────────────────
  log "Updating Homebrew..."
  run brew update

  log "Upgrading existing Homebrew packages..."
  run brew upgrade

  for item in "${requested_formulae[@]}"; do install_formula "$item"; done
  for item in "${requested_casks[@]}";    do install_cask    "$item"; done

  log "Cleaning up Homebrew cache..."
  run brew cleanup

  # ── Shell setup ────────────────────────────────────────────────────────────
  configure_oh_my_zsh       # Must run before other .zshrc writes (rewrites the file)
  configure_zshrc

  # ── Developer tools ────────────────────────────────────────────────────────
  configure_git
  install_nerd_font
  configure_eza
  configure_vscode
  configure_ssh_key
  install_firefox_extensions
  configure_dev_folder
  configure_ai_skills_dirs
  install_obsidian_skills
  install_claude_code

  # ── macOS preferences ──────────────────────────────────────────────────────
  configure_finder
  configure_dock
  configure_keyboard
  configure_screen
  configure_terminal
  configure_system
  configure_power
  configure_mail
  configure_safari
  configure_spotlight
  configure_transmission

  # ── Security (last — may pause for user input) ─────────────────────────────
  disable_gatekeeper

  kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true
  log "Done. Restart your Mac for all changes to take effect."
}

main "$@"
