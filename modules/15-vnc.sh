#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
# termux-wayland-installer - Step: VNC Server (Optional Remote Access)
# ============================================================

step_vnc() {
    print_step $((++CURRENT_STEP)) "${TOTAL_STEPS}" "Setting Up VNC Server"
    echo ""

    if ! cfg_is_true "features.vnc"; then
        log_info "VNC disabled in config, skipping"
        return 0
    fi

    # Install VNC packages
    local packages_str=$(cfg_get_array "packages.vnc")
    local failed=()

    # Temporarily restore IFS to include space for word splitting
    local old_ifs="$IFS"
    IFS=$' \t\n'
    for pkg_spec in ${packages_str}; do
        IFS='|' read -r pkg name <<< "${pkg_spec}"
        name="${name:-$pkg}"
        if ! execute install_pkg "${pkg}" "${name}"; then
            failed+=("${name}")
        fi
    done
    IFS="$old_ifs"

    if [[ ${#failed[@]} -gt 0 ]]; then
        log_error "Failed to install VNC packages: ${failed[*]}"
        return 1
    fi

    # Configure VNC server
    configure_vnc_server

    # Create VNC launcher scripts
    create_vnc_scripts

    # Configure VNC for Wayland (wayvnc)
    configure_wayvnc

    log_success "VNC server configured"
}

configure_vnc_server() {
    execute mkdir -p "${HOME}/.vnc"

    # VNC password
    local vnc_password="${VNC_PASSWORD:-}"
    if [[ -z "${vnc_password}" ]]; then
        # Generate random password if not set
        vnc_password=$(openssl rand -base64 12 | tr -d "=+/" | cut -c1-12)
        log_info "Generated VNC password: ${vnc_password}"
        echo "VNC Password: ${vnc_password}" > "${HOME}/.vnc/password.txt"
        execute chmod 600 "${HOME}/.vnc/password.txt"
    fi

    # Store password
    echo "${vnc_password}" | vncpasswd -f > "${HOME}/.vnc/passwd"
    execute chmod 600 "${HOME}/.vnc/passwd"

    # VNC server config
    execute cat > "${HOME}/.vnc/config" << 'VNCCONFIGEOF'
# TigerVNC configuration
geometry=1920x1080
depth=24
pixelformat=rgb888
dpi=96
localhost=no
securitytypes=vncauth,tlsvnc
TlsvncCipher=HIGH
TlsvncMinVersion=1.2
TlsvncMaxVersion=1.3
VNCCONFIGEOF

    # Use configured resolution
    local resolution=$(cfg_get_str "vnc.resolution" "1920x1080")
    local dpi=$(cfg_get_str "vnc.dpi" "96")
    sed -i "s/geometry=.*/geometry=${resolution}/" "${HOME}/.vnc/config"
    sed -i "s/dpi=.*/dpi=${dpi}/" "${HOME}/.vnc/config"

    # Xstartup for VNC (starts Wayland compositor)
    execute cat > "${HOME}/.vnc/xstartup" << 'XSTARTUPEOF'
#!/data/data/com.termux/files/usr/bin/bash
# VNC Xstartup - launches Wayland session inside VNC

# Export required environment
export WAYLAND_DISPLAY=wayland-0
export XDG_SESSION_TYPE=wayland
export XDG_CURRENT_DESKTOP=Hyprland
export XDG_RUNTIME_DIR=/tmp/runtime-$USER
export MESA_NO_ERROR=1
export GALLIUM_DRIVER=zink
export MESA_LOADER_DRIVER_OVERRIDE=zink
export VK_ICD_FILENAMES=/data/data/com.termux/files/usr/share/vulkan/icd.d/freedreno_icd.aarch64.json

# Create runtime directory
mkdir -p "${XDG_RUNTIME_DIR}"
chmod 700 "${XDG_RUNTIME_DIR}"

# Start dbus
if ! pgrep -x "dbus-daemon" > /dev/null; then
    dbus-daemon --session --fork
fi

# Start Wayland compositor based on DE
DE="${DE:-hyprland}"
case "${DE}" in
    hyprland)
        exec Hyprland
        ;;
    kde)
        export KDE_SESSION_VERSION=6
        export KDE_SESSION_UID=$(id -u)
        exec startplasma-wayland
        ;;
    *)
        exec Hyprland
        ;;
esac
XSTARTUPEOF
    execute chmod +x "${HOME}/.vnc/xstartup"

    # systemd user service for VNC
    execute mkdir -p "${HOME}/.config/systemd/user"

    execute cat > "${HOME}/.config/systemd/user/vncserver@.service" << 'VNCSERVICEEOF'
[Unit]
Description=Remote desktop service (VNC)
After=syslog.target network.target

[Service]
Type=forking
User=%i
PIDFile=/home/%i/.vnc/%H:%i.pid
ExecStartPre=-/usr/bin/vncserver -kill :%i
ExecStart=/usr/bin/vncserver :%i -geometry 1920x1080 -depth 24 -dpi 96
ExecStop=/usr/bin/vncserver -kill :%i
Restart=on-failure

[Install]
WantedBy=multi-user.target
VNCSERVICEEOF

    # VNC viewer desktop entry
    execute mkdir -p "${HOME}/.local/share/applications"
    execute cat > "${HOME}/.local/share/applications/vnc-viewer.desktop" << 'VNCVIEWEREOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=VNC Viewer
Comment=Connect to VNC server
Exec=vncviewer
Icon=network-vnc
Terminal=false
Categories=Network;RemoteAccess;
VNCVIEWEREOF
}

create_vnc_scripts() {
    execute mkdir -p "${HOME}/.local/bin"

    # Start VNC server
    execute cat > "${HOME}/.local/bin/vnc-start" << 'VNCSTARTEOF'
#!/data/data/com.termux/files/usr/bin/bash
# Start VNC server

DISPLAY_NUM="${1:-1}"
RESOLUTION="${2:-1920x1080}"
DPI="${3:-96}"

echo "Starting VNC server on display :${DISPLAY_NUM}..."
vncserver :"${DISPLAY_NUM}" -geometry "${RESOLUTION}" -depth 24 -dpi "${DPI}"

if [[ $? -eq 0 ]]; then
    echo "VNC server started on port $((5900 + DISPLAY_NUM))"
    echo "Connect with: vncviewer localhost:$((5900 + DISPLAY_NUM))"
    echo "Or from network: vncviewer <device-ip>:$((5900 + DISPLAY_NUM))"
else
    echo "Failed to start VNC server"
    exit 1
fi
VNCSTARTEOF
    execute chmod +x "${HOME}/.local/bin/vnc-start"

    # Stop VNC server
    execute cat > "${HOME}/.local/bin/vnc-stop" << 'VNCSTOPEOF'
#!/data/data/com.termux/files/usr/bin/bash
# Stop VNC server

DISPLAY_NUM="${1:-1}"

echo "Stopping VNC server on display :${DISPLAY_NUM}..."
vncserver -kill :"${DISPLAY_NUM}"

if [[ $? -eq 0 ]]; then
    echo "VNC server stopped"
else
    echo "Failed to stop VNC server (may not be running)"
fi
VNCSTOPEOF
    execute chmod +x "${HOME}/.local/bin/vnc-stop"

    # VNC status
    execute cat > "${HOME}/.local/bin/vnc-status" << 'VNCSTATUSEOF'
#!/data/data/com.termux/files/usr/bin/bash
# Show VNC server status

echo "VNC Server Status:"
echo "=================="

for display in /tmp/.X*-lock; do
    [[ -f "$display" ]] || continue
    disp_num=$(basename "$display" .lock | sed 's/.X//')
    port=$((5900 + disp_num))
    pid=$(cat "$display" 2>/dev/null)
    echo "Display :${disp_num} (port ${port}) - PID: ${pid}"
done

echo ""
echo "Active connections:"
netstat -tn 2>/dev/null | grep ":590[0-9]" | grep ESTABLISHED
VNCSTATUSEOF
    execute chmod +x "${HOME}/.local/bin/vnc-status"

    # VNC password change
    execute cat > "${HOME}/.local/bin/vnc-passwd" << 'VNCPASSWDEOF'
#!/data/data/com.termux/files/usr/bin/bash
# Change VNC password

echo "Enter new VNC password:"
vncpasswd

echo "Password changed. Restart VNC server to apply:"
echo "  vnc-stop && vnc-start"
VNCPASSWDEOF
    execute chmod +x "${HOME}/.local/bin/vnc-passwd"
}

configure_wayvnc() {
    # wayvnc for native Wayland VNC (better performance)
    if ! command -v wayvnc &>/dev/null; then
        log_info "wayvnc not installed, attempting to install..."
        execute install_pkg "wayvnc" "wayvnc" || log_warn "wayvnc not available"
    fi

    if command -v wayvnc &>/dev/null; then
        execute mkdir -p "${HOME}/.config/wayvnc"

        execute cat > "${HOME}/.config/wayvnc/config" << 'WAYVNCEOF'
# wayvnc configuration for Hyprland
address=0.0.0.0
port=5900
username=
password=
tls=false
certificate=
private_key=
enable_auth=true
max_fps=30
damage_tracking=true
cursor=true
output=
WAYVNCEOF

        # Add password if set
        if [[ -n "${VNC_PASSWORD}" ]]; then
            sed -i "s/password=/password=${VNC_PASSWORD}/" "${HOME}/.config/wayvnc/config"
        fi

        # wayvnc launcher
        execute cat > "${HOME}/.local/bin/wayvnc-start" << 'WAYVNCSTARTEOF'
#!/data/data/com.termux/files/usr/bin/bash
# Start wayvnc (native Wayland VNC)

echo "Starting wayvnc on port 5900..."
echo "Connect with: vncviewer <device-ip>:5900"
echo "Press Ctrl+C to stop"
exec wayvnc 0.0.0.0 5900
WAYVNCSTARTEOF
        execute chmod +x "${HOME}/.local/bin/wayvnc-start"

        log_success "wayvnc configured"
    fi
}

export -f step_vnc configure_vnc_server create_vnc_scripts configure_wayvnc