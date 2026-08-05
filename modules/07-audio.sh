#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
# termux-wayland-installer - Step: PipeWire Audio
# ============================================================

step_audio() {
    print_step $((++CURRENT_STEP)) "${TOTAL_STEPS}" "PipeWire Audio (will be installed in proot container)"
    echo ""

    # Audio packages are installed inside the proot container, not in Termux
    # This step just logs the packages that will be installed in the proot container
    local packages_str=$(cfg_get_array "packages.audio.modules")
    log_info "The following audio packages will be installed in the proot container:"
    local old_ifs="$IFS"
    IFS=$' \t\n'
    for pkg_spec in ${packages_str}; do
        IFS='|' read -r pkg name <<< "${pkg_spec}"
        name="${name:-$pkg}"
        log_info "  - ${name} (${pkg})"
    done
    IFS="$old_ifs"

    log_success "Audio packages will be installed in proot container during step_proot"
}