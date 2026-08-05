#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
|# termux-wayland-installer - Step: GPU Acceleration
|# ============================================================

step_gpu() {
    print_step $((++CURRENT_STEP)) "${TOTAL_STEPS}" "GPU Acceleration (will be installed in proot container)"
    echo ""

    # Verify GPU capabilities untuk Android / proot environment
    verify_gpu_capabilities() {
        # Deteksi perangkat GPU Android
        if [[ "$GPU_TYPE" == "adreno" ]]; then
            log_info "Adreno GPU terdeteksi - Vulkan didukung melalui TurnIP"
            log_success "GPU Vulkan siap (TurnIP Android)"
            return 0
        else
            # Logic Vulkan standard untuk non-Android
            if command -v vulkaninfo >/dev/null 2>&1 && vulkaninfo 2>&1 | grep -q "Vulkan"; then
                log_success "Vulkan terinstal dengan benar"
                return 0
            fi
        fi
        
        log_error "Vulkan tidak terdeteksi"
        return 1
    }

    # Jalankan verifikasi GPU
    if [[ "$TERMUX_ENVIRONMENT" == "true" ]]; then
        # Termux: gunakan GPU Android detection
        verify_gpu_capabilities
    else
        # Non-Termux: gunakan Vulkan detection standar
        if command -v vulkaninfo >/dev/null 2>&1 && vulkaninfo 2>&1 | grep -q "Vulkan"; then
            log_success "Vulkan terinstal dengan benar"
        else
            log_error "Vulkan tidak terdeteksi"
            return 1
        fi
    fi

    log_success "Verifikasi GPU selesai"
}

# Execute step
gpu() {
    # Verifikasi GPU
    verify_gpu_capabilities

    # Log packages yang akan diinstal
    print_step $((++CURRENT_STEP)) "${TOTAL_STEPS}" "Logging GPU packages for proot container"
    local packages_str=$(cfg_get_array "packages.gpu_packages")
    log_info "The following GPU packages will be installed in the proot container:"
    local old_ifs="$IFS"
    IFS=$' \t\n'
    for pkg_spec in ${packages_str}; do
        IFS='|' read -r pkg name <<< "${pkg_spec}"
        name="${name:-$pkg}"
        log_info "  - ${name} (${pkg})"
    done
    IFS="$old_ifs"

    log_success "GPU packages will be installed in proot container during step_proot"
}

# Jalankan GPU step
gpu