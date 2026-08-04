#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
# termux-wayland-installer - Step: System Update
# ============================================================

step_system_update() {
    [[ "${SKIP_SYSTEM_UPDATE}" == "true" ]] && { print_step $((++CURRENT_STEP)) "${TOTAL_STEPS}" "System Update (SKIPPED)"; return; }

    print_step $((++CURRENT_STEP)) "${TOTAL_STEPS}" "Updating System Packages"
    echo ""

    execute run_with_spinner "Updating package lists" \
        DEBIAN_FRONTEND=noninteractive apt-get update -y

    execute run_with_spinner "Upgrading packages" \
        DEBIAN_FRONTEND=noninteractive apt-get upgrade -y -q \
        -o Dpkg::Options::="--force-confold"
}