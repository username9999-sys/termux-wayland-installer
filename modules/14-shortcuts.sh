#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
# termux-wayland-installer - Step: Shortcuts & Desktop Entries
# ============================================================

step_shortcuts() {
    print_step $((++CURRENT_STEP)) "${TOTAL_STEPS}" "Creating Shortcuts & Desktop Entries"
    echo ""

    # Create desktop entries for proot apps
    create_proot_desktop_entries

    # Create Termux shortcuts
    create_termux_shortcuts

    # Create launcher scripts
    create_launcher_scripts

    # Create Termux widget shortcuts
    create_termux_widgets

    log_success "Shortcuts & desktop entries created"
}

create_proot_desktop_entries() {
    execute mkdir -p "${HOME}/.local/share/applications"

    # Main proot launcher
    execute cat > "${HOME}/.local/share/applications/termux-proot.desktop" << 'PROOT_DESKTOPEOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Proot Linux
Comment=Enter proot Linux container (Wayland)
Exec=/data/data/com.termux/files/home/start-proot.sh
Icon=system-run
Terminal=true
Categories=System;TerminalEmulator;
Keywords=linux;container;proot;wayland;
PROOT_DESKTOPEOF

    # Proot menu sync
    execute cat > "${HOME}/.local/share/applications/termux-proot-sync.desktop" << 'SYNC_DESKTOPEOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Sync Proot Apps
Comment=Sync proot applications to launcher
Exec=/data/data/com.termux/files/home/proot-menu-sync.sh
Icon=view-refresh
Terminal=true
Categories=System;Utility;
SYNC_DESKTOPEOF

    # Proot update
    execute cat > "${HOME}/.local/share/applications/termux-proot-update.desktop" << 'UPDATE_DESKTOPEOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Update Proot
Comment=Update proot container packages
Exec=/data/data/com.termux/files/home/start-proot.sh -c "sudo pacman -Syu"
Icon=system-software-update
Terminal=true
Categories=System;PackageManager;
UPDATE_DESKTOPEOF
}

create_termux_shortcuts() {
    execute mkdir -p "${HOME}/.shortcuts"
    execute mkdir -p "${HOME}/.shortcuts/tasks"

    # Quick start Hyprland
    execute cat > "${HOME}/.shortcuts/Start Hyprland.sh" << 'HYPRLAND_SHORTCUT'
#!/data/data/com.termux/files/usr/bin/bash
# Start Hyprland Wayland session
export WAYLAND_DISPLAY=wayland-0
export XDG_SESSION_TYPE=wayland
export XDG_CURRENT_DESKTOP=Hyprland
export MESA_NO_ERROR=1
export GALLIUM_DRIVER=zink
export MESA_LOADER_DRIVER_OVERRIDE=zink
export VK_ICD_FILENAMES=/data/data/com.termux/files/usr/share/vulkan/icd.d/freedreno_icd.aarch64.json

# Start compositor
exec Hyprland
HYPRLAND_SHORTCUT
    execute chmod +x "${HOME}/.shortcuts/Start Hyprland.sh"

    # Quick start KDE
    execute cat > "${HOME}/.shortcuts/Start KDE Plasma.sh" << 'KDE_SHORTCUT'
#!/data/data/com.termux/files/usr/bin/bash
# Start KDE Plasma Wayland session
export WAYLAND_DISPLAY=wayland-0
export XDG_SESSION_TYPE=wayland
export XDG_CURRENT_DESKTOP=KDE
export KDE_SESSION_VERSION=6
export KDE_SESSION_UID=$(id -u)

# Start Plasma
exec startplasma-wayland
KDE_SHORTCUT
    execute chmod +x "${HOME}/.shortcuts/Start KDE Plasma.sh"

    # Enter proot
    execute cat > "${HOME}/.shortcuts/Enter Proot.sh" << 'ENTER_PROOT_SHORTCUT'
#!/data/data/com.termux/files/usr/bin/bash
# Enter proot Linux container
exec ~/start-proot.sh
ENTER_PROOT_SHORTCUT
    execute chmod +x "${HOME}/.shortcuts/Enter Proot.sh"

    # Sync proot apps
    execute cat > "${HOME}/.shortcuts/Sync Proot Apps.sh" << 'SYNC_SHORTCUT'
#!/data/data/com.termux/files/usr/bin/bash
# Sync proot applications to launcher
exec ~/proot-menu-sync.sh
SYNC_SHORTCUT
    execute chmod +x "${HOME}/.shortcuts/Sync Proot Apps.sh"

    # Update system
    execute cat > "${HOME}/.shortcuts/Update System.sh" << 'UPDATE_SHORTCUT'
#!/data/data/com.termux/files/usr/bin/bash
# Update Termux and proot packages
echo "Updating Termux packages..."
pkg update && pkg upgrade -y

echo ""
echo "Updating proot packages..."
~/start-proot.sh -c "sudo pacman -Syu"

echo ""
echo "Updating Flatpaks..."
flatpak update -y 2>/dev/null || true

echo ""
echo "All updates complete!"
read -p "Press Enter to exit..."
UPDATE_SHORTCUT
    execute chmod +x "${HOME}/.shortcuts/Update System.sh"

    # GPU Info
    execute cat > "${HOME}/.shortcuts/GPU Info.sh" << 'GPU_INFO_SHORTCUT'
#!/data/data/com.termux/files/usr/bin/bash
# Show GPU information
echo "═══════════════════════════════════════════"
echo "       GPU Information"
echo "═══════════════════════════════════════════"
echo ""
echo "--- Vulkan Devices ---"
vulkaninfo --summary 2>/dev/null | head -50 || echo "vulkaninfo not available"

echo ""
echo "--- OpenGL Info ---"
glxinfo -B 2>/dev/null | head -30 || echo "glxinfo not available"

echo ""
echo "--- DRM Devices ---"
ls -la /dev/dri/ 2>/dev/null || echo "No DRM devices"

echo ""
echo "--- KGSL Devices ---"
ls -la /dev/kgsl* 2>/dev/null || echo "No KGSL devices"

echo ""
echo "--- Environment ---"
env | grep -E '(MESA|GALLIUM|VK_ICD|ZINK|TU_DEBUG)' | sort

read -p "Press Enter to exit..."
GPU_INFO_SHORTCUT
    execute chmod +x "${HOME}/.shortcuts/GPU Info.sh"

    # Health Check
    execute cat > "${HOME}/.shortcuts/Health Check.sh" << 'HEALTH_SHORTCUT'
#!/data/data/com.termux/files/usr/bin/bash
# Run health checks
exec ~/health-check.sh
HEALTH_SHORTCUT
    execute chmod +x "${HOME}/.shortcuts/Health Check.sh"

    # Theme Switcher
    execute cat > "${HOME}/.shortcuts/Switch Theme.sh" << 'THEME_SHORTCUT'
#!/data/data/com.termux/files/usr/bin/bash
# Switch theme
exec ~/.local/bin/theme-switch
THEME_SHORTCUT
    execute chmod +x "${HOME}/.shortcuts/Switch Theme.sh"
}

create_launcher_scripts() {
    execute mkdir -p "${HOME}/.local/bin"

    # Proot run command (run single command in proot)
    execute cat > "${HOME}/.local/bin/proot-run" << 'PROOT_RUN_EOF'
#!/data/data/com.termux/files/usr/bin/bash
# Run a command inside proot container
# Usage: proot-run <command> [args...]

PROOT_DISTRO="${PROOT_DISTRO:-archlinux}"
PROOT_USERNAME="${PROOT_USERNAME:-user}"
TERMUX_TMP="${TMPDIR:-/data/data/com.termux/files/usr/tmp}"

if [[ $# -eq 0 ]]; then
    echo "Usage: proot-run <command> [args...]"
    exit 1
fi

BINDS=""
[ -d "${TERMUX_TMP}/.X11-unix" ] && BINDS="${BINDS} --bind ${TERMUX_TMP}/.X11-unix:/tmp/.X11-unix"
[ -d "/dev/dri" ]               && BINDS="${BINDS} --bind /dev/dri:/dev/dri"
[ -e "/dev/kgsl-3d0" ]          && BINDS="${BINDS} --bind /dev/kgsl-3d0:/dev/kgsl-3d0"
[ -d "/data/data/com.termux/files/usr/share/vulkan/icd.d" ] && \
    BINDS="${BINDS} --bind /data/data/com.termux/files/usr/share/vulkan/icd.d:/usr/share/vulkan/icd.d.termux"

proot-distro login "${PROOT_DISTRO}" ${BINDS} --user "${PROOT_USERNAME}" -- bash -c "
export DISPLAY=:0
export WAYLAND_DISPLAY=wayland-0
export XDG_SESSION_TYPE=wayland
export XDG_CURRENT_DESKTOP=Hyprland
export XDG_RUNTIME_DIR=/tmp
export MESA_NO_ERROR=1
export GALLIUM_DRIVER=zink
export MESA_LOADER_DRIVER_OVERRIDE=zink
export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d.termux/freedreno_icd.aarch64.json
$*
"
PROOT_RUN_EOF
    execute chmod +x "${HOME}/.local/bin/proot-run"

    # Proot install package
    execute cat > "${HOME}/.local/bin/proot-install" << 'PROOT_INSTALL_EOF'
#!/data/data/com.termux/files/usr/bin/bash
# Install package in proot container
# Usage: proot-install <package> [package...]

PROOT_DISTRO="${PROOT_DISTRO:-archlinux}"

if [[ $# -eq 0 ]]; then
    echo "Usage: proot-install <package> [package...]"
    exit 1
fi

case "${PROOT_DISTRO}" in
    archlinux|arch)
        proot-distro login "${PROOT_DISTRO}" -- bash -c "sudo pacman -S --needed $*"
        ;;
    debian|ubuntu)
        proot-distro login "${PROOT_DISTRO}" -- bash -c "sudo apt-get update && sudo apt-get install -y $*"
        ;;
    fedora)
        proot-distro login "${PROOT_DISTRO}" -- bash -c "sudo dnf install -y $*"
        ;;
    alpine)
        proot-distro login "${PROOT_DISTRO}" -- bash -c "sudo apk add $*"
        ;;
    *)
        echo "Unknown distro: ${PROOT_DISTRO}"
        exit 1
        ;;
esac
PROOT_INSTALL_EOF
    execute chmod +x "${HOME}/.local/bin/proot-install"

    # Wayland session starter
    execute cat > "${HOME}/.local/bin/wayland-start" << 'WAYLAND_START_EOF'
#!/data/data/com.termux/files/usr/bin/bash
# Start Wayland session (Hyprland or KDE)
# Usage: wayland-start [hyprland|kde]

SESSION="${1:-hyprland}"

case "${SESSION}" in
    hyprland)
        export WAYLAND_DISPLAY=wayland-0
        export XDG_SESSION_TYPE=wayland
        export XDG_CURRENT_DESKTOP=Hyprland
        export MESA_NO_ERROR=1
        export GALLIUM_DRIVER=zink
        export MESA_LOADER_DRIVER_OVERRIDE=zink
        export VK_ICD_FILENAMES=/data/data/com.termux/files/usr/share/vulkan/icd.d/freedreno_icd.aarch64.json
        export TU_DEBUG=noconform
        export ZINK_DESCRIPTORS=lazy
        exec Hyprland
        ;;
    kde)
        export WAYLAND_DISPLAY=wayland-0
        export XDG_SESSION_TYPE=wayland
        export XDG_CURRENT_DESKTOP=KDE
        export KDE_SESSION_VERSION=6
        export KDE_SESSION_UID=$(id -u)
        exec startplasma-wayland
        ;;
    *)
        echo "Usage: wayland-start [hyprland|kde]"
        exit 1
        ;;
esac
WAYLAND_START_EOF
    execute chmod +x "${HOME}/.local/bin/wayland-start"

    # MangoHud launcher
    execute cat > "${HOME}/.local/bin/mangohud-launch" << 'MANGO_EOF'
#!/data/data/com.termux/files/usr/bin/bash
# Launch app with MangoHud overlay
# Usage: mangohud-launch <command> [args...]

if [[ $# -eq 0 ]]; then
    echo "Usage: mangohud-launch <command> [args...]"
    exit 1
fi

MANGOHUD=1 MANGOHUD_CONFIGFILE="${HOME}/.config/MangoHud/MangoHud.conf" "$@"
MANGO_EOF
    execute chmod +x "${HOME}/.local/bin/mangohud-launch"

    # Gamemode launcher
    execute cat > "${HOME}/.local/bin/gamemode-launch" << 'GAMEMODE_EOF'
#!/data/data/com.termux/files/usr/bin/bash
# Launch app with gamemode
# Usage: gamemode-launch <command> [args...]

if [[ $# -eq 0 ]]; then
    echo "Usage: gamemode-launch <command> [args...]"
    exit 1
fi

gamemoderun "$@"
GAMEMODE_EOF
    execute chmod +x "${HOME}/.local/bin/gamemode-launch"
}

create_termux_widgets() {
    execute mkdir -p "${HOME}/.shortcuts/tasks"

    # Widget: Quick GPU toggle
    execute cat > "${HOME}/.shortcuts/tasks/Toggle GPU Accel.sh" << 'GPU_TOGGLE_EOF'
#!/data/data/com.termux/files/usr/bin/bash
# Toggle GPU acceleration mode

CURRENT=$(grep "MESA_LOADER_DRIVER_OVERRIDE" ~/.bashrc 2>/dev/null | head -1)

if [[ "$CURRENT" == *"zink"* ]]; then
    sed -i 's/MESA_LOADER_DRIVER_OVERRIDE=zink/MESA_LOADER_DRIVER_OVERRIDE=/' ~/.bashrc
    sed -i 's/GALLIUM_DRIVER=zink/GALLIUM_DRIVER=/' ~/.bashrc
    termux-toast "GPU: Switched to llvmpipe (software)"
else
    grep -q "MESA_LOADER_DRIVER_OVERRIDE" ~/.bashrc || echo 'export MESA_LOADER_DRIVER_OVERRIDE=zink' >> ~/.bashrc
    grep -q "GALLIUM_DRIVER" ~/.bashrc || echo 'export GALLIUM_DRIVER=zink' >> ~/.bashrc
    sed -i 's/MESA_LOADER_DRIVER_OVERRIDE=.*/MESA_LOADER_DRIVER_OVERRIDE=zink/' ~/.bashrc
    sed -i 's/GALLIUM_DRIVER=.*/GALLIUM_DRIVER=zink/' ~/.bashrc
    termux-toast "GPU: Switched to Zink (hardware accel)"
fi
GPU_TOGGLE_EOF
    execute chmod +x "${HOME}/.shortcuts/tasks/Toggle GPU Accel.sh"

    # Widget: Restart Wayland
    execute cat > "${HOME}/.shortcuts/tasks/Restart Wayland.sh" << 'RESTART_WAYLAND_EOF'
#!/data/data/com.termux/files/usr/bin/bash
# Restart Wayland compositor

pkill -f "Hyprland|startplasma-wayland" 2>/dev/null
sleep 1
termux-toast "Wayland restarted. Start new session from launcher."
RESTART_WAYLAND_EOF
    execute chmod +x "${HOME}/.shortcuts/tasks/Restart Wayland.sh"

    # Widget: Clear cache
    execute cat > "${HOME}/.shortcuts/tasks/Clear Cache.sh" << 'CLEAR_CACHE_EOF'
#!/data/data/com.termux/files/usr/bin/bash
# Clear various caches

echo "Clearing caches..."
rm -rf ~/.cache/* 2>/dev/null
rm -rf /tmp/* 2>/dev/null
rm -rf ~/.local/share/Trash/* 2>/dev/null
flatpak uninstall --unused -y 2>/dev/null || true

# Proot cache
proot-distro login archlinux -- bash -c "
    sudo pacman -Sc --noconfirm 2>/dev/null || true
    rm -rf /var/cache/pacman/pkg/* 2>/dev/null
    rm -rf ~/.cache/* 2>/dev/null
" 2>/dev/null || true

termux-toast "Caches cleared"
CLEAR_CACHE_EOF
    execute chmod +x "${HOME}/.shortcuts/tasks/Clear Cache.sh"

    log_success "Termux widgets created in ~/.shortcuts/tasks/"
}

export -f step_shortcuts create_proot_desktop_entries create_termux_shortcuts create_launcher_scripts create_termux_widgets