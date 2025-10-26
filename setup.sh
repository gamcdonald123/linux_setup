#!/usr/bin/env bash
set -euo pipefail

# ======== Config ========
REPO_DIR="${REPO_DIR:-$HOME/bootstrap}"   # allow override
DOTFILES_DIR="$REPO_DIR/dotfiles"
LOGFILE="${LOGFILE:-/tmp/bootstrap.log}"
ZSH_BIN="${ZSH_BIN:-/usr/bin/zsh}"        # will be validated later

# ======== Logging ========
log()   { printf "[%s] %s\n" "$(date +'%F %T')" "$*" | tee -a "$LOGFILE"; }
fail()  { log "ERROR: $*"; exit 1; }
need()  { command -v "$1" >/dev/null 2>&1 || return 1; }

# ======== Sudo check (only when needed) ========
ensure_sudo() {
  if ! need sudo; then
    if [ "$(id -u)" -ne 0 ]; then
      fail "sudo is required but not installed. Login as root to install sudo or run as root."
    fi
  fi
}

# ======== Distro detection ========
distro=""
if [ -f /etc/os-release ]; then
  . /etc/os-release
  case "${ID,,}" in
    ubuntu|debian)   distro="debian" ;;
    pop)             distro="debian" ;;
    fedora)          distro="fedora" ;;
    rhel|centos|rocky|almalinux) distro="fedora" ;;
    arch|manjaro|endeavouros)    distro="arch" ;;
    *) log "Unknown ID=$ID; trying ID_LIKE=$ID_LIKE"
       case "${ID_LIKE,,}" in
         *debian*)  distro="debian" ;;
         *rhel*|*fedora*) distro="fedora" ;;
         *arch*)    distro="arch" ;;
         *) fail "Unsupported distro. Add a packages file and handler." ;;
       esac
       ;;
  esac
else
  fail "/etc/os-release not found"
fi
log "Detected distro: $distro"

# ======== Package installer ========
install_pkg_debian() {
  ensure_sudo
  sudo apt-get update -y
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "$@"
}

install_pkg_fedora() {
  ensure_sudo
  sudo dnf install -y "$@"
}

install_pkg_arch() {
  ensure_sudo
  sudo pacman -Syu --noconfirm
  sudo pacman -S --noconfirm --needed "$@"
}

install_pkgs() {
  local list="$REPO_DIR/packages/${distro}.txt"
  [ -f "$list" ] || fail "Missing package list: $list"
  mapfile -t pkgs < <(grep -vE '^\s*(#|$)' "$list")

  case "$distro" in
    debian) install_pkg_debian "${pkgs[@]}" ;;
    fedora) install_pkg_fedora "${pkgs[@]}" ;;
    arch)   install_pkg_arch   "${pkgs[@]}" ;;
  esac
}

# ======== Ensure base tooling ========
ensure_base_tools() {
  case "$distro" in
    debian)
      install_pkg_debian curl ca-certificates git stow
      ;;
    fedora)
      install_pkg_fedora curl ca-certificates git stow
      ;;
    arch)
      install_pkg_arch curl ca-certificates git stow
      ;;
  esac
}

# ======== Set default shell to zsh (idempotent) ========
set_default_shell_zsh() {
  # Find zsh path, prefer /usr/bin/zsh, fallback to $(command -v zsh)
  if [ ! -x "$ZSH_BIN" ]; then
    if need zsh; then ZSH_BIN="$(command -v zsh)"; else fail "zsh not installed"; fi
  fi

  grep -q "^$ZSH_BIN$" /etc/shells || {
    ensure_sudo
    echo "$ZSH_BIN" | sudo tee -a /etc/shells >/dev/null
  }

  if [ "${SHELL:-}" != "$ZSH_BIN" ]; then
    log "Changing default shell to $ZSH_BIN"
    chsh -s "$ZSH_BIN" || log "chsh failed (non-interactive shell?). You may need to re-login and run: chsh -s $ZSH_BIN"
  else
    log "Default shell already $ZSH_BIN"
  fi
}

# ======== Dotfiles deploy via stow (idempotent) ========
stow_package() {
  local pkg="$1"
  pushd "$DOTFILES_DIR" >/dev/null
  stow -v -R "$pkg" || fail "stow failed for $pkg"
  popd >/dev/null
}

deploy_dotfiles() {
  need stow || fail "stow not installed"
  # Example: always stow zsh; add others as needed (git, wezterm, nvim, etc.)
  [ -d "$DOTFILES_DIR/zsh" ] && stow_package zsh
}

# ======== Language/toolchain installers (optional) ========
install_rbenv() {
  if ! need rbenv; then
    log "Installing rbenv"
    git clone https://github.com/rbenv/rbenv.git ~/.rbenv
    mkdir -p ~/.rbenv/plugins
    git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
  fi
}

install_nvm() {
  if [ ! -d "${NVM_DIR:-$HOME/.nvm}" ]; then
    log "Installing nvm"
    curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
  fi
}

# ======== Main ========
main() {
  log "Starting bootstrap"
  ensure_base_tools

  log "Installing packages from packages/${distro}.txt"
  install_pkgs

  log "Deploying dotfiles with stow"
  deploy_dotfiles

  log "Setting default shell to zsh"
  set_default_shell_zsh

  # Optional language managers:
  # install_rbenv
  # install_nvm

  log "Done. Re-login (or start a new terminal) to load zsh."
}

main "$@"
