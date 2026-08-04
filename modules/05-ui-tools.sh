#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
# termux-wayland-installer - Step: UI Tools
# ============================================================

step_ui_tools() {
    print_step $((++CURRENT_STEP)) "${TOTAL_STEPS}" "Installing UI Tools (Waybar, Wofi, SwayNC, etc.)"
    echo ""

    local packages=($(cfg_get_array "packages.ui_tools"))
    local failed=()

    for pkg_spec in "${packages[@]}"; do
        IFS='|' read -r pkg name <<< "${pkg_spec}"
        name="${name:-$pkg}"
        if ! execute install_pkg "${pkg}" "${name}"; then
            failed+=("${name}")
        fi
    done

    if [[ ${#failed[@]} -gt 0 ]]; then
        log_error "Failed to install UI tools: ${failed[*]}"
        return 1
    fi
}