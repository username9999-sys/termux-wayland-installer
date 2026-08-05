#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
# termux-wayland-installer - Step: Development Tools
# ============================================================

step_devtools() {
    print_step $((++CURRENT_STEP)) "${TOTAL_STEPS}" "Installing Development Tools"
    echo ""

    local packages_str=$(cfg_get_array "packages.dev_tools")
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
        log_error "Failed to install dev tools: ${failed[*]}"
        return 1
    fi

    # Configure git (if not already)
    execute git config --global init.defaultBranch main || true
    execute git config --global pull.rebase false || true

    # Configure cargo (if rust installed)
    if command -v cargo &>/dev/null; then
        setup_cargo_config() {
            mkdir -p "${HOME}/.cargo"
            cat > "${HOME}/.cargo/config.toml" << 'EOF'
[build]
jobs = 4

[target.aarch64-linux-android]
linker = "clang"
ar = "llvm-ar"
EOF
        }
        execute setup_cargo_config
    fi

    # Configure npm (if nodejs installed)
    if command -v npm &>/dev/null; then
        setup_npm_config() {
            mkdir -p "${HOME}/.npm-global"
        }
        execute setup_npm_config
    fi

    log_success "Development tools installed and configured"
}