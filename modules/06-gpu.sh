#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
# termux-wayland-installer - Step: GPU Acceleration
# ============================================================

step_gpu() {
    print_step $((++CURRENT_STEP)) "${TOTAL_STEPS}" "Installing GPU Acceleration (Mesa, Vulkan, VirGL)"
    echo ""

    # Detect GPU if auto
    if [[ "${GPU_DRIVER}" == "auto" ]]; then
        if [[ "${GPU_TYPE}" == "adreno" ]]; then
            GPU_DRIVER="freedreno"
        else
            GPU_DRIVER="zink"
        fi
        log_info "Auto-detected GPU driver: ${GPU_DRIVER}"
    fi

    local packages=($(cfg_get_array "packages.gpu_packages"))
    local failed=()

    for pkg_spec in "${packages[@]}"; do
        IFS='|' read -r pkg name <<< "${pkg_spec}"
        name="${name:-$pkg}"
        if ! execute install_pkg "${pkg}" "${name}"; then
            failed+=("${name}")
        fi
    done

    if [[ ${#failed[@]} -gt 0 ]]; then
        log_error "Failed to install GPU packages: ${failed[*]}"
        return 1
    fi

    # Setup GPU environment file
    execute setup_gpu_env "${HOME}/.config/gpu.env"
    log_success "GPU environment saved to ~/.config/gpu.env"
}