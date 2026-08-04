#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
# termux-wayland-installer - Step: KDE Plasma
# ============================================================

step_kde() {
    print_step $((++CURRENT_STEP)) "${TOTAL_STEPS}" "Installing KDE Plasma 6"
    echo ""

    local packages=($(cfg_get_array "packages.kde"))
    local failed=()

    for pkg_spec in "${packages[@]}"; do
        IFS='|' read -r pkg name <<< "${pkg_spec}"
        name="${name:-$pkg}"
        if ! execute install_pkg "${pkg}" "${name}"; then
            failed+=("${name}")
        fi
    done

    if [[ ${#failed[@]} -gt 0 ]]; then
        log_error "Failed to install KDE packages: ${failed[*]}"
        return 1
    fi
}