#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
# termux-wayland-installer - Step: KDE Plasma
# ============================================================

step_kde() {
    print_step $((++CURRENT_STEP)) "${TOTAL_STEPS}" "Installing KDE Plasma 6"
    echo ""

    local packages_str=$(cfg_get_array "packages.kde")
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
        log_error "Failed to install KDE packages: ${failed[*]}"
        return 1
    fi
}