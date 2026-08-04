#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
# termux-wayland-installer - Step: Fonts
# ============================================================

step_fonts() {
    print_step $((++CURRENT_STEP)) "${TOTAL_STEPS}" "Installing Fonts (Noto, JetBrains Mono, Nerd Fonts, etc.)"
    echo ""

    local packages=($(cfg_get_array "packages.fonts"))
    local failed=()

    for pkg_spec in "${packages[@]}"; do
        IFS='|' read -r pkg name <<< "${pkg_spec}"
        name="${name:-$pkg}"
        if ! execute install_pkg "${pkg}" "${name}"; then
            failed+=("${name}")
        fi
    done

    if [[ ${#failed[@]} -gt 0 ]]; then
        log_error "Failed to install fonts: ${failed[*]}"
        return 1
    fi

    # Rebuild font cache
    execute run_with_spinner "Rebuilding font cache" \
        fc-cache -fv

    log_success "Fonts installed and cache rebuilt"
}