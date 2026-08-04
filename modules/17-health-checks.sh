#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
# termux-wayland-installer - Step: Health Checks
# ============================================================

step_health_checks() {
    print_step $((++CURRENT_STEP)) "${TOTAL_STEPS}" "Running Health Checks"
    echo ""

    local failed_checks=()
    local warnings=()

    # Run all health checks
    check_termux_environment || failed_checks+=("termux_environment")
    check_storage || warnings+=("storage")

    # Skip GPU and proot checks in dry-run mode (not actually installed)
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log_info "Skipping GPU/proot/audio checks (dry-run mode)"
    else
        check_gpu_vulkan || failed_checks+=("gpu_vulkan")
        check_audio_pipewire || warnings+=("audio_pipewire")
        check_proot_container || failed_checks+=("proot_container")
    fi

    check_wayland_session || warnings+=("wayland_session")
    check_config_files || warnings+=("config_files")
    check_helper_scripts || warnings+=("helper_scripts")
    check_network || warnings+=("network")

    # Summary
    echo ""
    echo "====================================================="
    echo "  Health Check Summary"
    echo "====================================================="

    if [[ ${#failed_checks[@]} -eq 0 ]] && [[ ${#warnings[@]} -eq 0 ]]; then
        log_success "All checks passed!"
        return 0
    elif [[ ${#failed_checks[@]} -eq 0 ]]; then
        log_warn "Checks passed with warnings: ${warnings[*]}"
        return 0
    else
        log_error "Failed checks: ${failed_checks[*]}"
        log_warn "Warnings: ${warnings[*]}"
        return 1
    fi
}

check_termux_environment() {
    log_info "Checking Termux environment..."

    # Termux version
    local termux_ver=$(pkg --version 2>/dev/null | head -1)
    [[ -n "$termux_ver" ]] && log_info "  Termux: $termux_ver" || { log_error "  Termux not found"; return 1; }

    # Android version
    local android_ver=$(getprop ro.build.version.release 2>/dev/null)
    [[ -n "$android_ver" ]] && log_info "  Android: $android_ver"

    # Architecture
    local arch=$(uname -m)
    log_info "  Architecture: $arch"
    [[ "$arch" == "aarch64" ]] || log_warn "  Non-ARM64 device, GPU acceleration may not work"

    # Kernel
    log_info "  Kernel: $(uname -r)"

    return 0
}

check_storage() {
    log_info "Checking storage..."

    # Termux storage
    local termux_free=$(df -h /data/data/com.termux/files 2>/dev/null | tail -1 | awk '{print $4}')
    local termux_total=$(df -h /data/data/com.termux/files 2>/dev/null | tail -1 | awk '{print $2}')
    log_info "  Termux: $termux_free free of $termux_total"

    # Shared storage
    local shared_free=$(df -h /sdcard 2>/dev/null | tail -1 | awk '{print $4}')
    local shared_total=$(df -h /sdcard 2>/dev/null | tail -1 | awk '{print $2}')
    log_info "  Shared: $shared_free free of $shared_total"

    # Check if low space
    local termux_avail_kb=$(df /data/data/com.termux/files 2>/dev/null | tail -1 | awk '{print $4}')
    if [[ "$termux_avail_kb" -lt 1048576 ]]; then # < 1GB
        log_warn "  Low Termux storage (< 1GB)"
        return 1
    fi

    return 0
}

check_gpu_vulkan() {
    log_info "Checking GPU / Vulkan..."

    # Vulkan
    if command -v vulkaninfo &>/dev/null; then
        local device_name=$(vulkaninfo --summary 2>/dev/null | grep deviceName | head -1 | sed 's/.*= //')
        local driver_ver=$(vulkaninfo --summary 2>/dev/null | grep driverVersion | head -1 | sed 's/.*= //')
        log_info "  Vulkan Device: ${device_name:-unknown}"
        log_info "  Driver Version: ${driver_ver:-unknown}"
    else
        log_warn "  vulkaninfo not installed"
    fi

    # DRI
    if [[ -d /dev/dri ]]; then
        local dri_devices=$(ls /dev/dri/ | tr '\n' ' ')
        log_info "  DRI Devices: $dri_devices"
    else
        log_warn "  No DRI devices found"
    fi

    # KGSL (Adreno)
    if [[ -e /dev/kgsl-3d0 ]]; then
        log_info "  KGSL (Adreno): Available"
    else
        log_warn "  KGSL not available"
    fi

    # Environment variables
    local env_ok=true
    for var in MESA_LOADER_DRIVER_OVERRIDE GALLIUM_DRIVER VK_ICD_FILENAMES; do
        local var_val="${!var:-}"
        if [[ -n "${var_val}" ]]; then
            log_info "  $var: ${var_val}"
        else
            log_warn "  $var not set"
            env_ok=false
        fi
    done

    $env_ok || return 1
    return 0
}

check_audio_pipewire() {
    log_info "Checking PipeWire audio..."

    local failed=false

    systemctl --user is-active pipewire >/dev/null 2>&1 \
        && log_info "  pipewire: running" \
        || { log_warn "  pipewire: not running"; failed=true; }

    systemctl --user is-active wireplumber >/dev/null 2>&1 \
        && log_info "  wireplumber: running" \
        || { log_warn "  wireplumber: not running"; failed=true; }

    systemctl --user is-active pipewire-pulse >/dev/null 2>&1 \
        && log_info "  pipewire-pulse: running" \
        || log_warn "  pipewire-pulse: not running"

    # Check PipeWire socket
    if [[ -S "${XDG_RUNTIME_DIR:-/tmp}/pipewire-0" ]]; then
        log_info "  PipeWire socket: OK"
    else
        log_warn "  PipeWire socket not found"
    fi

    $failed && return 1 || return 0
}

check_proot_container() {
    log_info "Checking proot container..."

    if ! command -v proot-distro &>/dev/null; then
        log_error "  proot-distro not installed"
        return 1
    fi

    log_info "  proot-distro: installed"

    if proot-distro list 2>/dev/null | grep -q "archlinux"; then
        log_info "  archlinux: installed"

        # Check essential packages in proot
        local pkgs_output=$(proot-distro login archlinux -- bash -c "pacman -Q hyprland wayland mesa libglvnd pipewire wireplumber 2>/dev/null" 2>/dev/null)
        local pkg_count=$(echo "$pkgs_output" | grep -c "^" || echo 0)
        log_info "  Essential packages: $pkg_count installed"

        # Check user
        local user_exists=$(proot-distro login archlinux -- bash -c "id user 2>/dev/null" 2>/dev/null)
        [[ -n "$user_exists" ]] && log_info "  User 'user': exists" || log_warn "  User 'user': not found"

    else
        log_warn "  archlinux: not installed"
        return 1
    fi

    return 0
}

check_wayland_session() {
    log_info "Checking Wayland session..."

    if [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
        log_info "  WAYLAND_DISPLAY: $WAYLAND_DISPLAY"
        log_info "  XDG_SESSION_TYPE: ${XDG_SESSION_TYPE:-not set}"
        log_info "  XDG_CURRENT_DESKTOP: ${XDG_CURRENT_DESKTOP:-not set}"
    else
        log_warn "  Not in a Wayland session (WAYLAND_DISPLAY not set)"
        # Don't fail in dry-run or when not in session
        if [[ "${DRY_RUN:-false}" == "true" ]]; then
            return 0
        fi
    fi

    # Check if compositor is running
    if pgrep -x "Hyprland" >/dev/null; then
        log_info "  Compositor: Hyprland running"
    elif pgrep -x "plasmashell" >/dev/null; then
        log_info "  Compositor: KDE Plasma running"
    else
        log_warn "  No Wayland compositor detected"
    fi

    return 0
}

check_config_files() {
    log_info "Checking configuration files..."

    local missing=()

    # Hyprland configs
    [[ -f "${HOME}/.config/hypr/hyprland.conf" ]] || missing+=("hyprland.conf")
    [[ -f "${HOME}/.config/waybar/config.jsonc" ]] || missing+=("waybar config")
    [[ -f "${HOME}/.config/wofi/config" ]] || missing+=("wofi config")
    [[ -f "${HOME}/.config/swaync/config.json" ]] || missing+=("swaync config")
    [[ -f "${HOME}/.config/foot/foot.ini" ]] || missing+=("foot config")

    # Theme configs
    [[ -f "${HOME}/.config/gtk-3.0/settings.ini" ]] || missing+=("gtk-3 settings")
    [[ -f "${HOME}/.config/gtk-4.0/settings.ini" ]] || missing+=("gtk-4 settings")
    [[ -f "${HOME}/.config/qt6ct/qt6ct.conf" ]] || missing+=("qt6ct config")
    [[ -f "${HOME}/.config/starship.toml" ]] || missing+=("starship config")

    if [[ ${#missing[@]} -eq 0 ]]; then
        log_info "  All config files present"
    else
        log_warn "  Missing configs: ${missing[*]}"
        return 1
    fi

    return 0
}

check_helper_scripts() {
    log_info "Checking helper scripts..."

    local missing=()

    [[ -f "${HOME}/start-proot.sh" && -x "${HOME}/start-proot.sh" ]] || missing+=("start-proot.sh")
    [[ -f "${HOME}/proot-menu-sync.sh" && -x "${HOME}/proot-menu-sync.sh" ]] || missing+=("proot-menu-sync.sh")
    [[ -f "${HOME}/health-check.sh" && -x "${HOME}/health-check.sh" ]] || missing+=("health-check.sh")

    [[ -f "${HOME}/.local/bin/proot-run" && -x "${HOME}/.local/bin/proot-run" ]] || missing+=("proot-run")
    [[ -f "${HOME}/.local/bin/proot-install" && -x "${HOME}/.local/bin/proot-install" ]] || missing+=("proot-install")
    [[ -f "${HOME}/.local/bin/wayland-start" && -x "${HOME}/.local/bin/wayland-start" ]] || missing+=("wayland-start")
    [[ -f "${HOME}/.local/bin/theme-switch" && -x "${HOME}/.local/bin/theme-switch" ]] || missing+=("theme-switch")

    # Only check VNC scripts if VNC is enabled
    if cfg_is_true "features.install_vnc"; then
        [[ -f "${HOME}/.local/bin/vnc-start" && -x "${HOME}/.local/bin/vnc-start" ]] || missing+=("vnc-start")
        [[ -f "${HOME}/.local/bin/vnc-stop" && -x "${HOME}/.local/bin/vnc-stop" ]] || missing+=("vnc-stop")
    fi

    if [[ ${#missing[@]} -eq 0 ]]; then
        log_info "  All helper scripts present and executable"
    else
        log_warn "  Missing scripts: ${missing[*]}"
        return 1
    fi

    return 0
}

check_network() {
    log_info "Checking network..."

    # Default route
    if ip route get 1.1.1.1 >/dev/null 2>&1; then
        local route_info=$(ip route get 1.1.1.1 | head -1)
        log_info "  Default route: OK"
        echo "    $route_info" | sed 's/^/    /'
    else
        log_warn "  No default route"
    fi

    # DNS
    if getent hosts google.com >/dev/null 2>&1; then
        log_info "  DNS resolution: OK"
    else
        log_warn "  DNS resolution failed"
    fi

    # Internet connectivity (quick check)
    if ping -c 1 -W 2 1.1.1.1 >/dev/null 2>&1; then
        log_info "  Internet: reachable"
    else
        log_warn "  Internet: unreachable"
    fi

    return 0
}

# Export individual check functions for standalone use
export -f check_termux_environment check_storage check_gpu_vulkan
export -f check_audio_pipewire check_proot_container check_wayland_session
export -f check_config_files check_helper_scripts check_network

export -f step_health_checks