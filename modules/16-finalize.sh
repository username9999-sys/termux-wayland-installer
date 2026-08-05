#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
# termux-wayland-installer - Step: Finalize Installation
# ============================================================

step_finalize() {
    print_step $((++CURRENT_STEP)) "${TOTAL_STEPS}" "Finalizing Installation"
    echo ""

    # Run post-install scripts
    run_post_install

    # Create summary
    create_install_summary

    # Set up update mechanism
    setup_update_mechanism

    # Create uninstall script
    create_uninstall_script

    # Run initial health check
    run_initial_health_check

    # Print completion message
    print_completion_message

    log_success "Installation finalized"
}

run_post_install() {
    log_info "Running post-install tasks..."

    # Rebuild font cache
    execute fc-cache -fv 2>/dev/null || true

    # Update desktop database
    execute update-desktop-database "${HOME}/.local/share/applications" 2>/dev/null || true

    # Update MIME database
    execute update-mime-database "${HOME}/.local/share/mime" 2>/dev/null || true

    # Reload systemd user daemon
    execute systemctl --user daemon-reload 2>/dev/null || true

    # Enable and start PipeWire
    execute systemctl --user enable --now pipewire pipewire-pulse wireplumber 2>/dev/null || true

    # Re-sync proot apps if proot installed
    if [[ -f "${HOME}/proot-menu-sync.sh" ]]; then
        execute bash "${HOME}/proot-menu-sync.sh" 2>/dev/null || true
    fi

    # Setup termux:boot autostart
    setup_termux_autostart

    # Download wallpaper if configured
    download_wallpaper

    log_success "Post-install tasks complete"
}

create_install_summary() {
    local summary_file="${HOME}/.local/share/termux-wayland-installer/summary.txt"
    execute mkdir -p "$(dirname "${summary_file}")"

    local install_date=$(date)
    local git_commit=$(cd "${SCRIPT_DIR}/.." && git rev-parse --short HEAD 2>/dev/null || echo "unknown")

    execute cat > "${summary_file}" << SUMMARYEOF
═══════════════════════════════════════════════════════════════
           termux-wayland-installer - Installation Summary
═══════════════════════════════════════════════════════════════

Installation Date: ${install_date}
Installer Version: ${git_commit}
Config File: ${CONFIG_FILE:-default}

═══════════════════════════════════════════════════════════════
                        Configuration
═══════════════════════════════════════════════════════════════

Desktop Environment: ${DE}
Theme: ${THEME} (${THEME_VARIANT:-default})
Proot Distro: ${PROOT_DISTRO} (${PROOT_LABEL})
Proot Username: ${PROOT_USERNAME}
GPU Acceleration: $(cfg_is_true "gpu.hardware_acceleration" && echo "Enabled (Zink/Turnip)" || echo "Disabled")
Audio: PipeWire + WirePlumber $(cfg_is_true "audio.bluetooth" && echo "+ Bluetooth" || echo "")
VNC: $(cfg_is_true "features.vnc" && echo "Enabled" || echo "Disabled")
Termux:API: $(cfg_is_true "features.termux_api" && echo "Enabled" || echo "Disabled")
Game Dev: $(cfg_is_true "features.gamedev" && echo "Enabled" || echo "Disabled")

═══════════════════════════════════════════════════════════════
                       Key Files Created
═══════════════════════════════════════════════════════════════

~/start-proot.sh              - Enter proot container
~/proot-menu-sync.sh          - Sync proot apps to launcher
~/health-check.sh             - Run system health checks
~/.local/bin/proot-run        - Run command in proot
~/.local/bin/proot-install    - Install package in proot
~/.local/bin/wayland-start    - Start Wayland session
~/.local/bin/vnc-start        - Start VNC server
~/.local/bin/vnc-stop         - Stop VNC server
~/.local/bin/vnc-status       - Check VNC status
~/.local/bin/theme-switch     - Switch theme
~/.local/bin/mangohud-launch  - Launch with MangoHud
~/.local/bin/gamemode-launch  - Launch with gamemode
~/.shortcuts/*.sh             - Termux widget shortcuts

═══════════════════════════════════════════════════════════════
                        Quick Start Guide
═══════════════════════════════════════════════════════════════

1. Start Wayland Session:
   ~/.shortcuts/Start Hyprland.sh
   # OR
   ~/.local/bin/wayland-start hyprland

2. Enter Proot Linux:
   ~/start-proot.sh
   # OR from Termux widget: "Enter Proot"

3. Sync Proot Apps (after installing apps in proot):
   ~/proot-menu-sync.sh

4. Run Health Check:
   ~/health-check.sh

5. Switch Theme:
   ~/.local/bin/theme-switch catppuccin mocha

6. Start VNC Server (remote access):
   ~/.local/bin/vnc-start

═══════════════════════════════════════════════════════════════
                        Proot Commands
═══════════════════════════════════════════════════════════════

Inside proot (as user '${PROOT_USERNAME}'):

  # Update system
  sudo pacman -Syu

  # Install package
  sudo pacman -S <package>

  # Search package
  pacman -Ss <query>

  # List installed
  pacman -Q

From Termux host:

  # Run command in proot
  proot-run <command>

  # Install package in proot
  proot-install <package>

═══════════════════════════════════════════════════════════════
                        Troubleshooting
═══════════════════════════════════════════════════════════════

GPU not working?
  - Run: ~/health-check.sh
  - Check: vulkaninfo --summary
  - Try: Toggle GPU Accel widget

Audio not working?
  - Run: systemctl --user status pipewire wireplumber
  - Restart: systemctl --user restart pipewire wireplumber

Proot apps not showing?
  - Run: ~/proot-menu-sync.sh
  - Check: ls ~/.local/share/applications/proot-bridge/

Wayland not starting?
  - Check logs: ~/health-check.sh
  - Verify: export WAYLAND_DISPLAY=wayland-0

VNC connection refused?
  - Check: ~/.local/bin/vnc-status
  - Verify password: cat ~/.vnc/password.txt
  - Try wayvnc: ~/.local/bin/wayvnc-start

═══════════════════════════════════════════════════════════════
                        Support & Updates
═══════════════════════════════════════════════════════════════

Update installer:
  cd "${SCRIPT_DIR}/.." && git pull
  ./install.sh --update

Uninstall:
  ./install.sh --uninstall

Report issues:
  https://github.com/your-repo/termux-wayland-installer/issues

Configuration:
  Edit: ~/.config/termux-wayland-installer/config.yaml
  Themes: ~/.local/bin/theme-switch --help

SUMMARYEOF

    # Also create a short version for quick reference
    execute cat > "${HOME}/.local/share/termux-wayland-installer/quickref.txt" << QUICKREFEOF
termux-wayland-installer Quick Reference
=========================================

DE: ${DE} | Theme: ${THEME} | Distro: ${PROOT_DISTRO}

Key Commands:
  ~/start-proot.sh              Enter Linux container
  ~/proot-menu-sync.sh          Sync apps to launcher
  ~/health-check.sh             System diagnostics
  ~/.local/bin/wayland-start    Start Wayland (hyprland|kde)
  ~/.local/bin/vnc-start        Start VNC server
  ~/.local/bin/theme-switch     Change theme
  proot-run <cmd>               Run cmd in proot
  proot-install <pkg>           Install pkg in proot

Shortcuts (Termux Widgets):
  Start Hyprland / Start KDE Plasma
  Enter Proot / Sync Proot Apps
  Update System / GPU Info
  Health Check / Switch Theme
  Toggle GPU Accel / Restart Wayland / Clear Cache

Config: ~/.config/termux-wayland-installer/config.yaml
QUICKREFEOF

    log_success "Installation summary created"
}

setup_update_mechanism() {
    execute mkdir -p "${HOME}/.local/share/termux-wayland-installer"

    # Update script
    execute cat > "${HOME}/.local/bin/termux-wayland-update" << 'UPDATEEOF'
#!/data/data/com.termux/files/usr/bin/bash
# termux-wayland-installer Update Script

INSTALLER_DIR="${SCRIPT_DIR}/.."
CONFIG_FILE="${HOME}/.config/termux-wayland-installer/config.yaml"

echo "═══════════════════════════════════════════"
echo "  termux-wayland-installer Update"
echo "═══════════════════════════════════════════"
echo ""

# Update installer repo
if [[ -d "${INSTALLER_DIR}/.git" ]]; then
    echo "[*] Updating installer repository..."
    cd "${INSTALLER_DIR}"
    git pull
else
    echo "[!] Installer directory not found at ${INSTALLER_DIR}"
    exit 1
fi

# Run installer in update mode
echo "[*] Running installer in update mode..."
exec "${INSTALLER_DIR}/install.sh" --config "${CONFIG_FILE}" --update
UPDATEEOF
    execute chmod +x "${HOME}/.local/bin/termux-wayland-update"

    # Rollback script
    execute cat > "${HOME}/.local/bin/termux-wayland-rollback" << 'ROLLBACKEOF'
#!/data/data/com.termux/files/usr/bin/bash
# termux-wayland-installer Rollback Script

BACKUP_DIR="${HOME}/.local/share/termux-wayland-installer/backups"

echo "═══════════════════════════════════════════"
echo "  termux-wayland-installer Rollback"
echo "═══════════════════════════════════════════"
echo ""

if [[ ! -d "${BACKUP_DIR}" ]]; then
    echo "[!] No backups found"
    exit 1
fi

echo "Available backups:"
ls -la "${BACKUP_DIR}"/backup-*.tar.gz 2>/dev/null | head -10

echo ""
read -p "Enter backup filename to restore (or 'latest'): " backup_file

if [[ "${backup_file}" == "latest" ]]; then
    backup_file=$(ls -t "${BACKUP_DIR}"/backup-*.tar.gz 2>/dev/null | head -1)
fi

if [[ ! -f "${backup_file}" ]]; then
    echo "[!] Backup not found: ${backup_file}"
    exit 1
fi

echo "[*] Restoring from ${backup_file}..."
tar -xzf "${backup_file}" -C /

echo "[*] Restore complete. Please restart Termux."
ROLLBACKEOF
    execute chmod +x "${HOME}/.local/bin/termux-wayland-rollback"

    # Create backup function
    execute cat > "${HOME}/.local/share/termux-wayland-installer/backup.sh" << 'BACKUPEOF'
#!/data/data/com.termux/files/usr/bin/bash
# Create backup of current configuration

BACKUP_DIR="${HOME}/.local/share/termux-wayland-installer/backups"
mkdir -p "${BACKUP_DIR}"

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_FILE="${BACKUP_DIR}/backup-${TIMESTAMP}.tar.gz"

echo "[*] Creating backup: ${BACKUP_FILE}"

tar -czf "${BACKUP_FILE}" \
    "${HOME}/.config/hypr" \
    "${HOME}/.config/waybar" \
    "${HOME}/.config/wofi" \
    "${HOME}/.config/swaync" \
    "${HOME}/.config/foot" \
    "${HOME}/.config/gtk-3.0" \
    "${HOME}/.config/gtk-4.0" \
    "${HOME}/.config/qt6ct" \
    "${HOME}/.config/qt5ct" \
    "${HOME}/.config/starship.toml" \
    "${HOME}/.config/termux-wayland-installer" \
    "${HOME}/.local/bin" \
    "${HOME}/.local/share/applications" \
    "${HOME}/.shortcuts" \
    "${HOME}/.vnc" \
    "${HOME}/start-proot.sh" \
    "${HOME}/proot-menu-sync.sh" \
    "${HOME}/health-check.sh" 2>/dev/null

echo "[*] Backup created: ${BACKUP_FILE}"

# Keep only last 5 backups
ls -t "${BACKUP_DIR}"/backup-*.tar.gz 2>/dev/null | tail -n +6 | xargs rm -f 2>/dev/null

BACKUPEOF
    execute chmod +x "${HOME}/.local/share/termux-wayland-installer/backup.sh"

    log_success "Update mechanism configured"
}

create_uninstall_script() {
    execute cat > "${HOME}/.local/bin/termux-wayland-uninstall" << 'UNINSTALLEOF'
#!/data/data/com.termux/files/usr/bin/bash
# termux-wayland-installer Uninstall Script

echo "═══════════════════════════════════════════"
echo "  termux-wayland-installer Uninstall"
echo "═══════════════════════════════════════════"
echo ""
echo "This will remove:"
echo "  - Hyprland/KDE configurations"
echo "  - Waybar, Wofi, SwayNC, Foot configs"
echo "  - GTK/Qt theme configurations"
echo "  - Proot container (archlinux)"
echo "  - Proot scripts (start-proot.sh, proot-menu-sync.sh)"
echo "  - Health check script"
echo "  - VNC configuration"
echo "  - Shortcuts and desktop entries"
echo "  - Theme configurations"
echo ""
echo "This will NOT remove:"
echo "  - Termux packages (installed via pkg)"
echo "  - User data in ~/ (Documents, Downloads, etc.)"
echo ""
read -p "Are you sure you want to uninstall? (yes/no): " confirm

if [[ "${confirm}" != "yes" ]]; then
    echo "Aborted."
    exit 0
fi

echo "[*] Stopping services..."
systemctl --user stop pipewire wireplumber pipewire-pulse 2>/dev/null || true
systemctl --user disable pipewire wireplumber pipewire-pulse 2>/dev/null || true
vncserver -kill :1 2>/dev/null || true
pkill -f "wayvnc" 2>/dev/null || true

echo "[*] Removing proot container..."
proot-distro remove archlinux 2>/dev/null || true

echo "[*] Removing configuration files..."
rm -rf "${HOME}/.config/hypr"
rm -rf "${HOME}/.config/waybar"
rm -rf "${HOME}/.config/wofi"
rm -rf "${HOME}/.config/swaync"
rm -rf "${HOME}/.config/foot"
rm -rf "${HOME}/.config/gtk-3.0"
rm -rf "${HOME}/.config/gtk-4.0"
rm -rf "${HOME}/.config/qt6ct"
rm -rf "${HOME}/.config/qt5ct"
rm -rf "${HOME}/.config/starship.toml"
rm -rf "${HOME}/.config/termux-wayland-installer"
rm -rf "${HOME}/.vnc"

echo "[*] Removing scripts..."
rm -f "${HOME}/start-proot.sh"
rm -f "${HOME}/proot-menu-sync.sh"
rm -f "${HOME}/health-check.sh"
rm -f "${HOME}/.local/bin/proot-run"
rm -f "${HOME}/.local/bin/proot-install"
rm -f "${HOME}/.local/bin/wayland-start"
rm -f "${HOME}/.local/bin/vnc-start"
rm -f "${HOME}/.local/bin/vnc-stop"
rm -f "${HOME}/.local/bin/vnc-status"
rm -f "${HOME}/.local/bin/vnc-passwd"
rm -f "${HOME}/.local/bin/wayvnc-start"
rm -f "${HOME}/.local/bin/theme-switch"
rm -f "${HOME}/.local/bin/mangohud-launch"
rm -f "${HOME}/.local/bin/gamemode-launch"
rm -f "${HOME}/.local/bin/termux-wayland-update"
rm -f "${HOME}/.local/bin/termux-wayland-rollback"
rm -f "${HOME}/.local/bin/termux-wayland-uninstall"
rm -f "${HOME}/.local/share/termux-wayland-installer/backup.sh"

echo "[*] Removing shortcuts and desktop entries..."
rm -rf "${HOME}/.shortcuts"
rm -rf "${HOME}/.local/share/applications/proot-bridge"
rm -rf "${HOME}/.local/share/applications/termux-proot.desktop"
rm -rf "${HOME}/.local/share/applications/termux-proot-sync.desktop"
rm -rf "${HOME}/.local/share/applications/termux-proot-update.desktop"
rm -rf "${HOME}/.local/share/applications/vnc-viewer.desktop"
rm -rf "${HOME}/.local/share/termux-wayland-installer"

echo "[*] Removing proot wrappers..."
rm -rf "${HOME}/.local/share/proot-wrappers"

echo ""
echo "═══════════════════════════════════════════"
echo "  Uninstall Complete"
echo "═══════════════════════════════════════════"
echo ""
echo "To reinstall, run:"
echo "  ${SCRIPT_DIR}/../install.sh"
echo ""
echo "Note: Termux packages were NOT removed."
echo "To remove packages: pkg uninstall <package>"
UNINSTALLEOF
    execute chmod +x "${HOME}/.local/bin/termux-wayland-uninstall"

    log_success "Uninstall script created"
}

run_initial_health_check() {
    log_info "Running initial health check..."

    # Create health check script if not exists
    if [[ ! -f "${HOME}/health-check.sh" ]]; then
        create_health_check_script
    fi

    # Run quick health check
    execute bash "${HOME}/health-check.sh" --quick 2>/dev/null || true
}

create_health_check_script() {
    execute cat > "${HOME}/health-check.sh" << 'HEALTHCHECKEOF'
#!/data/data/com.termux/files/usr/bin/bash
# termux-wayland-installer Health Check

QUICK_MODE=false
[[ "$1" == "--quick" ]] && QUICK_MODE=true

print_header() {
    echo ""
    echo "═══════════════════════════════════════════"
    echo "  $1"
    echo "═══════════════════════════════════════════"
}

check_pass() { echo "  [✓] $1"; }
check_warn() { echo "  [!] $1"; }
check_fail() { echo "  [✗] $1"; }

print_header "termux-wayland-installer Health Check"

# Termux
print_header "Termux Environment"
echo "  Termux: $(pkg --version 2>/dev/null | head -1)"
echo "  Android: $(getprop ro.build.version.release 2>/dev/null || echo "unknown")"
echo "  Architecture: $(uname -m)"
echo "  Kernel: $(uname -r)"

# Storage
print_header "Storage"
df -h /data/data/com.termux/files 2>/dev/null | tail -1 | awk '{print "  Termux: " $4 " free of " $2}'
df -h /sdcard 2>/dev/null | tail -1 | awk '{print "  Shared: " $4 " free of " $2}'

# GPU
print_header "GPU / Vulkan"
if command -v vulkaninfo &>/dev/null; then
    vulkaninfo --summary 2>/dev/null | grep -E "(deviceName|driverVersion|apiVersion)" | head -5 | sed 's/^/  /'
else
    check_warn "vulkaninfo not installed"
fi

if [[ -d /dev/dri ]]; then
    check_pass "DRI devices: $(ls /dev/dri/ | tr '\n' ' ')"
else
    check_warn "No DRI devices"
fi

if [[ -e /dev/kgsl-3d0 ]]; then
    check_pass "KGSL (Adreno) available"
else
    check_warn "KGSL not available"
fi

# Environment variables
print_header "GPU Environment"
for var in MESA_LOADER_DRIVER_OVERRIDE GALLIUM_DRIVER VK_ICD_FILENAMES TU_DEBUG ZINK_DESCRIPTORS; do
    val="${!var}"
    [[ -n "$val" ]] && check_pass "$var=$val" || check_warn "$var not set"
done

# Audio
print_header "Audio (PipeWire)"
systemctl --user is-active pipewire >/dev/null 2>&1 && check_pass "pipewire running" || check_fail "pipewire not running"
systemctl --user is-active wireplumber >/dev/null 2>&1 && check_pass "wireplumber running" || check_fail "wireplumber not running"
systemctl --user is-active pipewire-pulse >/dev/null 2>&1 && check_pass "pipewire-pulse running" || check_warn "pipewire-pulse not running"

# Proot
print_header "Proot Container"
if command -v proot-distro &>/dev/null; then
    check_pass "proot-distro installed"
    if proot-distro list 2>/dev/null | grep -q "archlinux"; then
        check_pass "archlinux installed"
        # Check proot packages
        proot-distro login archlinux -- bash -c "pacman -Q hyprland wayland mesa 2>/dev/null" | head -5 | sed 's/^/  /'
    else
        check_warn "archlinux not installed"
    fi
else
    check_fail "proot-distro not installed"
fi

# Wayland
print_header "Wayland"
if [[ -n "$WAYLAND_DISPLAY" ]]; then
    check_pass "WAYLAND_DISPLAY=$WAYLAND_DISPLAY"
else
    check_warn "WAYLAND_DISPLAY not set (not in Wayland session)"
fi

# Config files
print_header "Configuration Files"
configs=(
    "~/.config/hypr/hyprland.conf:Hyprland"
    "~/.config/waybar/config.jsonc:Waybar"
    "~/.config/wofi/config:Wofi"
    "~/.config/swaync/config.json:SwayNC"
    "~/.config/foot/foot.ini:Foot"
    "~/.config/starship.toml:Starship"
    "~/.config/gtk-3.0/settings.ini:GTK3"
    "~/.config/gtk-4.0/settings.ini:GTK4"
    "~/.config/qt6ct/qt6ct.conf:Qt6"
)
for entry in "${configs[@]}"; do
    IFS=':' read -r file desc <<< "$entry"
    eval "expanded=$file"
    [[ -f "$expanded" ]] && check_pass "$desc" || check_warn "$desc missing"
done

# Scripts
print_header "Helper Scripts"
scripts=(
    "~/start-proot.sh:Proot launcher"
    "~/proot-menu-sync.sh:App sync"
    "~/health-check.sh:Health check"
    "~/.local/bin/proot-run:Proot run"
    "~/.local/bin/wayland-start:Wayland start"
    "~/.local/bin/vnc-start:VNC start"
    "~/.local/bin/theme-switch:Theme switch"
)
for entry in "${scripts[@]}"; do
    IFS=':' read -r file desc <<< "$entry"
    eval "expanded=$file"
    [[ -f "$expanded" ]] && [[ -x "$expanded" ]] && check_pass "$desc" || check_warn "$desc missing or not executable"
done

if [[ "$QUICK_MODE" == "true" ]]; then
    print_header "Quick Check Complete"
    exit 0
fi

# Network
print_header "Network"
ip route get 1.1.1.1 2>/dev/null | head -1 | sed 's/^/  /' || check_warn "No default route"

# VNC
print_header "VNC"
if command -v vncserver &>/dev/null; then
    check_pass "vncserver installed"
    ~/.local/bin/vnc-status 2>/dev/null | sed 's/^/  /'
else
    check_warn "vncserver not installed"
fi

# Summary
print_header "Summary"
echo "  Run '~/health-check.sh --quick' for quick check"
echo "  Run '~/health-check.sh' for full check"
HEALTHCHECKEOF
    execute chmod +x "${HOME}/health-check.sh"
}

print_completion_message() {
    echo ""
    echo "═══════════════════════════════════════════════════════════════"
    echo "       termux-wayland-installer - Installation Complete!"
    echo "═══════════════════════════════════════════════════════════════"
    echo ""
    echo "  Desktop: ${DE} | Theme: ${THEME} | Distro: ${PROOT_DISTRO}"
    echo ""
    echo "  Quick Start:"
    echo "    Start Wayland:  ~/.shortcuts/Start Hyprland.sh"
    echo "    Enter Proot:    ~/start-proot.sh"
    echo "    Health Check:   ~/health-check.sh"
    echo ""
    echo "  Full summary: ~/.local/share/termux-wayland-installer/summary.txt"
    echo "  Quick ref:    ~/.local/share/termux-wayland-installer/quickref.txt"
    echo ""
    echo "  Next steps:"
    echo "    1. Start a Wayland session (Hyprland or KDE)"
    echo "    2. Run '~/start-proot.sh' to enter Linux container"
    echo "    3. Install apps in proot, then run '~/proot-menu-sync.sh'"
    echo "    4. Enjoy your Wayland desktop on Android!"
    echo ""
}

setup_termux_autostart() {
    if [[ "${AUTOSTART:-false}" != "true" ]]; then
        return 0
    fi

    log_info "Setting up termux:boot autostart..."

    execute mkdir -p "${HOME}/.termux/boot"

    local de_start_cmd=""
    if [[ "${DE}" == "kde" ]]; then
        de_start_cmd="startplasma-wayland"
    else
        de_start_cmd="Hyprland"
    fi

    execute cat > "${HOME}/.termux/boot/wayland-autostart.sh" << BOOTEOF
#!/data/data/com.termux/files/usr/bin/bash
# Auto-start Wayland on Termux boot

export WAYLAND_DISPLAY=wayland-0
export XDG_SESSION_TYPE=wayland
export XDG_CURRENT_DESKTOP=$(echo ${DE} | tr '[:lower:]' '[:upper:]')
export MESA_NO_ERROR=1
export GALLIUM_DRIVER=zink
export MESA_LOADER_DRIVER_OVERRIDE=zink
export VK_ICD_FILENAMES=/data/data/com.termux/files/usr/share/vulkan/icd.d/freedreno_icd.aarch64.json

# Start PipeWire
systemctl --user start pipewire pipewire-pulse wireplumber 2>/dev/null || true

# Wait a bit for services
sleep 2

# Start Wayland compositor
exec ${de_start_cmd}
BOOTEOF

    execute chmod +x "${HOME}/.termux/boot/wayland-autostart.sh"
    log_success "termux:boot autostart configured for ${DE}"
}

download_wallpaper() {
    if [[ -z "${WALLPAPER_URL:-}" ]]; then
        log_info "No wallpaper URL configured, skipping download"
        return 0
    fi

    log_info "Downloading wallpaper from ${WALLPAPER_URL}..."

    local wallpaper_dir="${HOME}/Pictures/Wallpapers"
    execute mkdir -p "${wallpaper_dir}"

    local wallpaper_file="${wallpaper_dir}/wallpaper.jpg"

    # Download with verification
    if execute download_verified "${WALLPAPER_URL}" "${wallpaper_file}" "${WALLPAPER_SHA256:-}" 3 30; then
        # Set as wallpaper for both DEs
        if [[ "${DE}" == "hyprland" ]]; then
            # Update hyprland.conf with wallpaper path
            if [[ -f "${HOME}/.config/hypr/hyprland.conf" ]]; then
                execute sed -i "s|^# monitor =.*|monitor = ,preferred,auto,${wallpaper_file}|" "${HOME}/.config/hypr/hyprland.conf" 2>/dev/null || true
            fi
        elif [[ "${DE}" == "kde" ]]; then
            # KDE wallpaper is set via plasma config (already in configure_kde)
            log_info "Wallpaper downloaded for KDE (configured in plasma settings)"
        fi

        log_success "Wallpaper downloaded to ${wallpaper_file}"
    else
        log_warn "Failed to download wallpaper, using default gradient"
    fi
}

export -f step_finalize run_post_install create_install_summary setup_update_mechanism create_uninstall_script run_initial_health_check create_health_check_script print_completion_message setup_termux_autostart download_wallpaper