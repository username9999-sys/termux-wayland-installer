#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
# termux-wayland-installer - Main Entry Point
# Unified installer for Hyprland and KDE Plasma Wayland on Termux
# ============================================================

# ---- Strict Mode ----
set -euo pipefail
IFS=$'\n\t'

# ---- Determine Script Directory ----
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ---- Load Libraries ----
source "${SCRIPT_DIR}/lib/common.sh"
source "${SCRIPT_DIR}/lib/yaml.sh"
source "${SCRIPT_DIR}/lib/themes.sh"

# Export functions from yaml.sh that are needed
export -f get_pinned_version

# ---- Source All Modules ----
for module in "${SCRIPT_DIR}/modules"/*.sh; do
    source "${module}"
done

# ---- Parse Arguments ----
parse_args "$@"

# ---- Load Configuration ----
CONFIG_FILE="${CONFIG_FILE:-${SCRIPT_DIR}/config/install.yaml}"
parse_yaml "${CONFIG_FILE}"

# Apply CLI overrides (must happen AFTER parse_yaml so config values exist to override)
[[ -n "${THEME_OVERRIDE:-}" ]] && export CFG_GENERAL_THEME="${THEME_OVERRIDE}"
[[ -n "${VARIANT_OVERRIDE:-}" ]] && export CFG_GENERAL_THEME_VARIANT="${VARIANT_OVERRIDE}"
[[ -n "${DISTRO_OVERRIDE:-}" ]] && export CFG_PROOT_DISTRO="${DISTRO_OVERRIDE}"
[[ -n "${DESKTOP_OVERRIDE:-}" ]] && export CFG_GENERAL_DESKTOP_ENVIRONMENT="${DESKTOP_OVERRIDE}"
[[ -n "${INPUT_METHOD_OVERRIDE:-}" ]] && export CFG_FEATURES_INPUT_METHOD="${INPUT_METHOD_OVERRIDE}"
[[ -n "${AUTOSTART_OVERRIDE:-}" ]] && export CFG_FEATURES_AUTOSTART="${AUTOSTART_OVERRIDE}"
[[ -n "${USER_OVERRIDE:-}" ]] && export CFG_USER_USERNAME="${USER_OVERRIDE}"

# Validate theme
THEME="${CFG_GENERAL_THEME:-catppuccin}"
THEME_VARIANT="${CFG_GENERAL_THEME_VARIANT:-mocha}"
validate_theme "${THEME}" "${THEME_VARIANT}" || exit 1

# Apply theme
apply_theme "${THEME}" "${THEME_VARIANT}"

# ---- Configuration Variables ----
DE="${CFG_GENERAL_DESKTOP_ENVIRONMENT:-hyprland}"
PROOT_DISTRO="${CFG_PROOT_DISTRO:-archlinux}"
PROOT_LABEL="${CFG_PROOT_LABEL:-Arch Linux}"
PROOT_USERNAME="${CFG_USER_USERNAME:-user}"
PROOT_PASSWORD="${CFG_USER_PASSWORD:-}"
PROOT_EXTRA_GROUPS="${CFG_USER_EXTRA_GROUPS:-wheel video render audio input storage}"
PROOT_SHELL="${CFG_USER_SHELL:-/bin/bash}"
PROOT_EXTRA_PACKAGES="${CFG_PROOT_EXTRA_PACKAGES:-}"
PROOT_ENABLE_SYSTEMD="${CFG_PROOT_ENABLE_SYSTEMD:-false}"
PROOT_EXTRA_BINDS="${CFG_PROOT_EXTRA_BINDS:-}"

GPU_DRIVER="${CFG_GPU_DRIVER:-auto}"
GPU_VIRGL="${CFG_GPU_VIRGL:-true}"
GPU_TURNIP="${CFG_GPU_TURNIP:-true}"
GPU_FORCE_SOFTWARE="${CFG_GPU_FORCE_SOFTWARE:-false}"

WALLPAPER_URL="${CFG_GENERAL_WALLPAPER_URL:-}"
WALLPAPER_SHA256="${CFG_GENERAL_WALLPAPER_SHA256:-}"
CREATE_SHORTCUTS="${CFG_GENERAL_CREATE_SHORTCUTS:-true}"

# Feature flags
INSTALL_PROOT="${CFG_FEATURES_INSTALL_PROOT:-true}"
INSTALL_GAMEDEV="${CFG_FEATURES_INSTALL_GAMEDEV:-true}"
INSTALL_DEVTOOLS="${CFG_FEATURES_INSTALL_DEVTOOLS:-true}"
INSTALL_VNC="${CFG_FEATURES_INSTALL_VNC:-false}"
VNC_INTERACTIVE="${CFG_FEATURES_VNC_INTERACTIVE:-true}"
VNC_PASSWORD="${CFG_FEATURES_VNC_PASSWORD:-wayland}"
VNC_GEOMETRY="${CFG_FEATURES_VNC_GEOMETRY:-1920x1080}"
SETUP_SSH="${CFG_FEATURES_SETUP_SSH:-false}"
INPUT_METHOD="${CFG_FEATURES_INPUT_METHOD:-false}"
INPUT_METHOD_ENGINE="${CFG_FEATURES_INPUT_METHOD_ENGINE:-fcitx5}"
TABLET_SUPPORT="${CFG_FEATURES_TABLET_SUPPORT:-false}"
AUTOSTART="${CFG_FEATURES_AUTOSTART:-false}"
CREATE_UNINSTALL="${CFG_FEATURES_CREATE_UNINSTALL:-true}"

# Health checks
HEALTH_ENABLED="${CFG_HEALTH_ENABLED:-true}"

# Update config
BACKUP_BEFORE_UPDATE="${CFG_UPDATE_BACKUP_BEFORE_UPDATE:-true}"
BACKUP_DIR="${CFG_UPDATE_BACKUP_DIR:-~/termux-wayland-backups}"
KEEP_BACKUPS="${CFG_UPDATE_KEEP_BACKUPS:-5}"
AUTO_MIGRATE="${CFG_UPDATE_AUTO_MIGRATE:-true}"

# Advanced
SKIP_SYSTEM_UPDATE="${CFG_ADVANCED_SKIP_SYSTEM_UPDATE:-false}"
PARALLEL_INSTALLS="${CFG_ADVANCED_PARALLEL_INSTALLS:-false}"
DEBUG="${CFG_ADVANCED_DEBUG:-false}"

[[ "${DEBUG}" == "true" ]] && set -x

# ---- Detect Device ----
detect_device

# ---- Print Banner ----
print_banner "Termux Wayland Installer" "Desktop: ${DE^} | Theme: ${THEME_NAMES[${THEME}]:-${THEME}} ${THEME_VARIANT} | Distro: ${PROOT_LABEL}"

if [[ "${DRY_RUN}" == "true" ]]; then
    log_warn "DRY RUN MODE - No changes will be made"
fi

if [[ "${UNINSTALL}" == "true" ]]; then
    log_warn "UNINSTALL MODE - Will remove installed components"
    # Run uninstall script if it exists
    if [[ "${DRY_RUN}" == "true" ]]; then
        log_info "[DRY-RUN] Would run uninstall script: ${HOME}/.local/bin/termux-wayland-uninstall"
        exit 0
    elif [[ -f "${HOME}/.local/bin/termux-wayland-uninstall" ]]; then
        log_info "Running uninstall script..."
        exec bash "${HOME}/.local/bin/termux-wayland-uninstall"
    else
        log_error "Uninstall script not found. Run installer first."
        exit 1
    fi
fi

if [[ "${UPDATE_MODE}" == "true" ]]; then
    log_info "UPDATE MODE - Running update..."
    if [[ "${DRY_RUN}" == "true" ]]; then
        log_info "[DRY-RUN] Would run update script: ${HOME}/.local/bin/termux-wayland-update"
        exit 0
    elif [[ -f "${HOME}/.local/bin/termux-wayland-update" ]]; then
        exec bash "${HOME}/.local/bin/termux-wayland-update"
    else
        log_error "Update script not found. Re-run installer."
        exit 1
    fi
fi

echo ""
log_info "Configuration loaded from: ${CONFIG_FILE}"
log_info "Desktop Environment: ${DE}"
log_info "Theme: ${THEME} (${THEME_VARIANT})"
log_info "Proot Distro: ${PROOT_LABEL} (${PROOT_DISTRO})"
log_info "Proot User: ${PROOT_USERNAME}"
log_info "Device: ${DEVICE_BRAND} ${DEVICE_MODEL} (${GPU_TYPE}, ${TOTAL_RAM_GB}GB RAM)"
echo ""

# RAM warning
if [[ "${DE}" == "kde" && ${TOTAL_RAM_GB} -lt 6 ]]; then
    log_warn "KDE Plasma Wayland recommends 6GB+ RAM. Current: ${TOTAL_RAM_GB}GB"
elif [[ "${DE}" == "hyprland" && ${TOTAL_RAM_GB} -lt 4 ]]; then
    log_warn "Hyprland recommends 4GB+ RAM. Current: ${TOTAL_RAM_GB}GB"
fi

# Auto-confirm or prompt
if [[ "${CFG_GENERAL_AUTO_CONFIRM:-false}" != "true" && "${DRY_RUN}" != "true" && "${UNINSTALL}" != "true" ]]; then
    # Check if we have a TTY for interactive prompt
    if [[ -t 0 ]]; then
        read -p "Continue with installation? (y/N): " CONFIRM
        [[ "${CONFIRM}" =~ ^[Yy]$ ]] || { log_info "Installation cancelled"; exit 0; }
    else
        log_info "Non-interactive mode, auto-confirming installation"
    fi
fi

# ---- Main Installation Flow ----
main() {
    local total_steps=0

    # Count steps based on features (use : to suppress return value)
    : $((total_steps++))  # System update
    : $((total_steps++))  # Repositories
    : $((total_steps++))  # Wayland core
    if [[ "${DE}" == "hyprland" ]]; then
        : $((total_steps++))  # Hyprland ecosystem
    else
        : $((total_steps++))  # KDE Plasma
    fi
    : $((total_steps++))  # UI tools
    : $((total_steps++))  # GPU acceleration
    : $((total_steps++))  # Audio
    : $((total_steps++))  # Fonts
    [[ "${INSTALL_DEVTOOLS}" == "true" ]] && : $((total_steps++))  # Dev tools
    [[ "${INSTALL_GAMEDEV}" == "true" ]] && : $((total_steps++))  # Game dev
    [[ "${INSTALL_PROOT}" == "true" ]] && : $((total_steps++))  # Proot
    [[ "${INPUT_METHOD}" == "true" ]] && : $((total_steps++))  # Input method
    [[ "${AUTOSTART}" == "true" ]] && : $((total_steps++))  # Autostart
    [[ "${SETUP_SSH}" == "true" ]] && : $((total_steps++))  # SSH setup
    [[ "${TABLET_SUPPORT}" == "true" ]] && : $((total_steps++))  # Tablet support
    : $((total_steps++))  # Launchers & configs
    : $((total_steps++))  # Theme configs
    [[ "${CREATE_SHORTCUTS}" == "true" ]] && : $((total_steps++))  # Shortcuts
    [[ -n "${WALLPAPER_URL:-}" ]] && : $((total_steps++))  # Wallpaper
    [[ "${INSTALL_VNC}" == "true" ]] && : $((total_steps++))  # VNC
    : $((total_steps++))  # Finalize
    [[ "${HEALTH_ENABLED}" == "true" ]] && : $((total_steps++))  # Health checks

    export TOTAL_STEPS="${total_steps}"
    export CURRENT_STEP=0

    log_info "Total installation steps: ${total_steps}"
    echo ""

    # Execute steps
    step_system_update
    step_repositories
    step_wayland_core

    if [[ "${DE}" == "hyprland" ]]; then
        step_hyprland
    else
        step_kde
    fi

    step_ui_tools
    step_gpu
    step_audio
    step_fonts

    [[ "${INSTALL_DEVTOOLS}" == "true" ]] && step_devtools
    [[ "${INSTALL_GAMEDEV}" == "true" ]] && step_gamedev
    [[ "${INSTALL_PROOT}" == "true" ]] && step_proot

    [[ "${INPUT_METHOD}" == "true" ]] && step_input_method
    [[ "${AUTOSTART}" == "true" ]] && step_autostart
    [[ "${SETUP_SSH}" == "true" ]] && step_ssh_setup
    [[ "${TABLET_SUPPORT}" == "true" ]] && step_tablet_support

    step_launchers_configs
    step_theme_configs

    [[ -n "${WALLPAPER_URL:-}" ]] && step_wallpaper

    [[ "${CREATE_SHORTCUTS}" == "true" ]] && step_shortcuts
    [[ "${INSTALL_VNC}" == "true" ]] && step_vnc

    step_finalize

    [[ "${HEALTH_ENABLED}" == "true" ]] && [[ "${DRY_RUN:-false}" != "true" ]] && step_health_checks

    print_completion_message
}

# ---- Run Main ----
main