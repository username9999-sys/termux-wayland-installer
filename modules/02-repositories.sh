#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
# termux-wayland-installer - Step: Repositories
# ============================================================

step_repositories() {
    print_step $((++CURRENT_STEP)) "${TOTAL_STEPS}" "Adding Termux Repositories"
    echo ""

    local repos_str=$(cfg_get_array "repositories.enabled")
    local failed=()

    # Temporarily restore IFS to include space for word splitting
    # Note: $'\t\n' needed for escape sequences to be interpreted
    local old_ifs="$IFS"
    IFS=$' \t\n'
    for repo in ${repos_str}; do
        if ! execute install_pkg "${repo}" "${repo}"; then
            failed+=("${repo}")
        fi
    done
    IFS="$old_ifs"

    if [[ ${#failed[@]} -gt 0 ]]; then
        log_error "Failed to add repositories: ${failed[*]}"
        return 1
    fi

    # Update after adding repos
    execute run_with_spinner "Updating package lists after repo addition" \
        bash -c 'DEBIAN_FRONTEND=noninteractive apt-get update -y'
}