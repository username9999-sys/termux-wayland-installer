#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
# termux-wayland-installer - Step: Game Development
# ============================================================

step_gamedev() {
    print_step $((++CURRENT_STEP)) "${TOTAL_STEPS}" "Installing Game Development Stack"
    echo ""

    local packages=($(cfg_get_array "packages.gamedev"))
    local failed=()

    for pkg_spec in "${packages[@]}"; do
        IFS='|' read -r pkg name <<< "${pkg_spec}"
        name="${name:-$pkg}"
        if ! execute install_pkg "${pkg}" "${name}"; then
            failed+=("${name}")
        fi
    done

    if [[ ${#failed[@]} -gt 0 ]]; then
        log_error "Failed to install game dev packages: ${failed[*]}"
        return 1
    fi

    # Setup MangoHud config
    setup_mangohud_config() {
        mkdir -p "${HOME}/.config/MangoHud"
        cat > "${HOME}/.config/MangoHud/MangoHud.conf" << 'EOF'
# MangoHud configuration
gpu_stats
gpu_text
cpu_stats
cpu_text
ram
vram
fps
frame_timing
arch
gpu_color=00FFFF
cpu_color=00FF00
ram_color=FFFF00
vram_color=FF00FF
fps_color=FFFFFF
EOF
    }
    execute setup_mangohud_config

    # Setup gamemode
    execute systemctl --user enable gamemoded 2>/dev/null || true

    log_success "Game development stack installed"
}