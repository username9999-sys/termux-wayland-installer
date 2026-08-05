#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
# termux-wayland-installer - Step: Proot Container
# ============================================================

step_proot() {
    print_step $((++CURRENT_STEP)) "${TOTAL_STEPS}" "Setting Up Proot Container (${PROOT_LABEL})"
    echo ""

    # Install proot-distro
    local packages_str=$(cfg_get_array "packages.proot")
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
        log_error "Failed to install proot packages: ${failed[*]}"
        return 1
    fi

    # Install distro
    execute run_with_spinner "Installing ${PROOT_LABEL} rootfs" \
        bash -c "proot-distro list 2>&1 | grep -q \"^  \* ${PROOT_DISTRO}$\" && proot-distro reset ${PROOT_DISTRO} || proot-distro install ${PROOT_DISTRO}"

    # Bootstrap with essential packages
    log_info "Bootstrapping ${PROOT_LABEL} with essential packages..."

    local distro_packages=""

    case "${PROOT_DISTRO}" in
        archlinux|arch)
            distro_packages="mesa vulkan-radeon vulkan-intel vulkan-tools libglvnd libva libvdpau xorg-server-xwayland pipewire wireplumber dbus polkit sudo git base-devel python python-pip nodejs npm clang llvm lld cmake ninja meson"
            [[ "${INSTALL_GAMEDEV}" == "true" ]] && distro_packages="${distro_packages} godot steam lutris bottles mangohud gamemode"
            [[ "${DE}" == "hyprland" ]] && distro_packages="${distro_packages} hyprland hyprpaper hyprlock hypridle hyprcursor hyprutils hyprwayland-scanner aquamarine xdg-desktop-portal-hyprland xdg-desktop-portal-gtk xdg-desktop-portal-wlr polkit waybar wofi swaync swaybg grim slurp swappy wl-clipboard cliphist brightnessctl pavucontrol network-manager-applet blueman thunar thunar-volman thunar-archive-plugin gvfs gvfs-mtp file-roller mousepad foot kitty neovim"
            [[ "${DE}" == "kde" ]] && distro_packages="${distro_packages} plasma-desktop plasma-workspace plasma-workspace-wayland kwin kwin-wayland sddm breeze breeze-gtk kde-cli-tools konsole dolphin kate kcalc spectacle kwalletmanager systemsettings plasma-nm bluedevil powerdevil kdeconnect"
            ;;
        debian|ubuntu)
            distro_packages="mesa-vulkan-drivers libglx-mesa0 libva2 libvdpau1 xwayland pipewire wireplumber dbus polkit sudo git build-essential python3 python3-pip nodejs npm clang llvm lld cmake ninja-build meson"
            [[ "${INSTALL_GAMEDEV}" == "true" ]] && distro_packages="${distro_packages} steam lutris bottles mangohud gamemode"
            [[ "${DE}" == "hyprland" ]] && distro_packages="${distro_packages} hyprland hyprpaper hyprlock hypridle hyprcursor hyprutils hyprwayland-scanner aquamarine xdg-desktop-portal-hyprland xdg-desktop-portal-gtk xdg-desktop-portal-wlr polkit waybar wofi swaync swaybg grim slurp swappy wl-clipboard cliphist brightnessctl pavucontrol network-manager-applet blueman thunar thunar-volman thunar-archive-plugin gvfs gvfs-mtp file-roller mousepad foot kitty neovim"
            [[ "${DE}" == "kde" ]] && distro_packages="${distro_packages} kde-plasma-desktop konsole dolphin kate"
            ;;
        fedora)
            distro_packages="mesa-vulkan-drivers libglvnd libva libvdpau xorg-x11-server-Xwayland pipewire wireplumber dbus polkit sudo git gcc gcc-c++ make cmake ninja-build meson python3 python3-pip nodejs npm clang llvm lld"
            [[ "${INSTALL_GAMEDEV}" == "true" ]] && distro_packages="${distro_packages} steam lutris bottles mangohud gamemode"
            [[ "${DE}" == "hyprland" ]] && distro_packages="${distro_packages} hyprland hyprpaper hyprlock hypridle hyprcursor hyprutils hyprwayland-scanner aquamarine xdg-desktop-portal-hyprland xdg-desktop-portal-gtk xdg-desktop-portal-wlr polkit waybar wofi swaync swaybg grim slurp swappy wl-clipboard cliphist brightnessctl pavucontrol network-manager-applet blueman thunar thunar-volman thunar-archive-plugin gvfs gvfs-mtp file-roller mousepad foot kitty neovim"
            [[ "${DE}" == "kde" ]] && distro_packages="${distro_packages} @kde-desktop konsole dolphin kate"
            ;;
        alpine)
            distro_packages="mesa-vulkan-drivers libglvnd libva libvdpau xwayland pipewire wireplumber dbus polkit sudo git build-base python3 py3-pip nodejs npm clang llvm lld cmake ninja meson"
            [[ "${INSTALL_GAMEDEV}" == "true" ]] && distro_packages="${distro_packages} steam lutris bottles mangohud gamemode"
            [[ "${DE}" == "hyprland" ]] && distro_packages="${distro_packages} hyprland hyprpaper hyprlock hypridle hyprcursor hyprutils hyprwayland-scanner aquamarine xdg-desktop-portal-hyprland xdg-desktop-portal-gtk xdg-desktop-portal-wlr polkit waybar wofi swaync swaybg grim slurp swappy wl-clipboard cliphist brightnessctl pavucontrol network-manager-applet blueman thunar thunar-volman thunar-archive-plugin gvfs gvfs-mtp file-roller mousepad foot kitty neovim"
            [[ "${DE}" == "kde" ]] && distro_packages="${distro_packages} plasma-desktop konsole dolphin kate"
            ;;
        *)
            log_warn "Unknown distro ${PROOT_DISTRO}, using minimal bootstrap"
            distro_packages="mesa pipewire wireplumber dbus polkit sudo git"
            ;;
    esac

    # Add extra packages from config
    [[ -n "${PROOT_EXTRA_PACKAGES}" ]] && distro_packages="${distro_packages} ${PROOT_EXTRA_PACKAGES}"

    execute proot-distro login "${PROOT_DISTRO}" -- bash -c "
        export DEBIAN_FRONTEND=noninteractive
        case '${PROOT_DISTRO}' in
            archlinux|arch) pacman -Sy --noconfirm && pacman -S --noconfirm --needed ${distro_packages} ;;
            debian|ubuntu) apt-get update && apt-get install -y ${distro_packages} ;;
            fedora) dnf install -y ${distro_packages} ;;
            alpine) apk update && apk add ${distro_packages} ;;
        esac
    " 2>/dev/null || log_warn "Some proot packages may have failed to install"

    # Create non-root user with limited sudo
    log_info "Creating proot user: ${PROOT_USERNAME} (non-root)..."
    execute proot-distro login "${PROOT_DISTRO}" -- bash -c "
        id '${PROOT_USERNAME}' > /dev/null 2>&1 || useradd -m -s '${PROOT_SHELL}' '${PROOT_USERNAME}'
        usermod -aG ${PROOT_EXTRA_GROUPS} '${PROOT_USERNAME}' 2>/dev/null || true

        # Limited sudo - only specific commands, no password
        cat > /etc/sudoers.d/${PROOT_USERNAME} << 'SUDOEOF'
${PROOT_USERNAME} ALL=(ALL) NOPASSWD: /usr/bin/pacman, /usr/bin/apt, /usr/bin/dnf, /usr/bin/apk, /usr/bin/systemctl, /usr/bin/mount, /usr/bin/umount
SUDOEOF
        chmod 0440 /etc/sudoers.d/${PROOT_USERNAME}

        # Set up shell
        echo 'export PS1=\"\[\033[01;32m\]${PROOT_USERNAME}@linux\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ \"' >> /home/'${PROOT_USERNAME}'/.bashrc
        echo 'alias ll=\"ls -la\"' >> /home/'${PROOT_USERNAME}'/.bashrc
        echo 'alias update=\"sudo pacman -Syu\"' >> /home/'${PROOT_USERNAME}'/.bashrc

        # Set password if provided
        if [[ -n '${PROOT_PASSWORD}' ]]; then
            echo '${PROOT_USERNAME}:${PROOT_PASSWORD}' | chpasswd
        else
            # Lock password, use key/sudo only
            passwd -l '${PROOT_USERNAME}' 2>/dev/null || true
        fi
    " 2>/dev/null || log_warn "User creation had issues"

    log_success "Proot user '${PROOT_USERNAME}' created with limited sudo"

    # Create start-proot.sh
    create_start_proot_script

    # Create proot-menu-sync.sh
    create_proot_menu_sync

    log_success "Proot container (${PROOT_LABEL}) setup complete"
}

create_start_proot_script() {
    local desktop_type="${DE}"
    [[ "${desktop_type}" == "kde" ]] && desktop_type="KDE" || desktop_type="Hyprland"

    execute cat > ~/start-proot.sh << 'PROOTEOF'
#!/data/data/com.termux/files/usr/bin/bash
# Auto-generated by termux-wayland-installer
PROOT_DISTRO="__PROOT_DISTRO__"
PROOT_LABEL="__PROOT_LABEL__"
PROOT_USERNAME="__PROOT_USERNAME__"
TERMUX_TMP="${TMPDIR:-/data/data/com.termux/files/usr/tmp}"

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  [*] Starting ${PROOT_LABEL} (Wayland-ready, user: ${PROOT_USERNAME})"
echo "═══════════════════════════════════════════════════════════"
echo ""

BINDS=""
[ -d "${TERMUX_TMP}/.X11-unix" ] && BINDS="${BINDS} --bind ${TERMUX_TMP}/.X11-unix:/tmp/.X11-unix"
[ -d "/dev/dri" ]               && BINDS="${BINDS} --bind /dev/dri:/dev/dri"
[ -e "/dev/kgsl-3d0" ]          && BINDS="${BINDS} --bind /dev/kgsl-3d0:/dev/kgsl-3d0"
[ -d "/data/data/com.termux/files/usr/share/vulkan/icd.d" ] && \
    BINDS="${BINDS} --bind /data/data/com.termux/files/usr/share/vulkan/icd.d:/usr/share/vulkan/icd.d.termux"
[ -f "/data/data/com.termux/files/usr/lib/libvulkan.so" ] && \
    BINDS="${BINDS} --bind /data/data/com.termux/files/usr/lib/libvulkan.so:/usr/lib/libvulkan_termux.so"

# Extra binds from config
__EXTRA_BINDS__

_RC=$(mktemp /data/data/com.termux/files/usr/tmp/proot_rc.XXXX)
cat > "${_RC}" << 'RCEOF'
export DISPLAY=:0
export WAYLAND_DISPLAY=wayland-0
export XDG_SESSION_TYPE=wayland
export XDG_CURRENT_DESKTOP=__DESKTOP__
export MESA_NO_ERROR=1
export MESA_GL_VERSION_OVERRIDE=4.6
export MESA_GLES_VERSION_OVERRIDE=3.2
export GALLIUM_DRIVER=zink
export MESA_LOADER_DRIVER_OVERRIDE=zink
export TU_DEBUG=noconform
export ZINK_DESCRIPTORS=lazy
export MESA_VK_WSI_PRESENT_MODE=immediate
[ -f /usr/share/vulkan/icd.d.termux/freedreno_icd.aarch64.json ] && \
    export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d.termux/freedreno_icd.aarch64.json
export XDG_DATA_DIRS=/usr/share:/usr/local/share:${XDG_DATA_DIRS}
export XDG_CONFIG_DIRS=/etc/xdg:${XDG_CONFIG_DIRS}
export XDG_RUNTIME_DIR=/tmp
export PS1="\[\033[01;32m\]__USERNAME__@linux\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ "
echo ""
echo " User: __USERNAME__ | Session: Wayland | WM: __DESKTOP__"
echo " Type 'exit' to leave proot."
echo ""
RCEOF

# Replace placeholders in RC file
sed -i "s/__DESKTOP__/${DESKTOP}/g; s/__USERNAME__/${PROOT_USERNAME}/g" "${_RC}"

proot-distro login "${PROOT_DISTRO}" ${BINDS} --user "${PROOT_USERNAME}" -- bash --rcfile "${_RC}"
rm -f "${_RC}"
PROOTEOF

    # Replace placeholders
    sed -i "s/__PROOT_DISTRO__/${PROOT_DISTRO}/g" ~/start-proot.sh
    sed -i "s/__PROOT_LABEL__/${PROOT_LABEL}/g" ~/start-proot.sh
    sed -i "s/__PROOT_USERNAME__/${PROOT_USERNAME}/g" ~/start-proot.sh
    sed -i "s/__DESKTOP__/${desktop_type}/g" ~/start-proot.sh
    sed -i "s/__USERNAME__/${PROOT_USERNAME}/g" ~/start-proot.sh

    # Handle extra binds
    local extra_binds=""
    if [[ -n "${PROOT_EXTRA_BINDS}" ]]; then
        # Parse array from config
        local i=0
        while true; do
            local var="CFG_PROOT_EXTRA_BINDS[${i}]"
            local bind="${!var:-}"
            [[ -z "${bind}" ]] && break
            IFS=':' read -r host container <<< "${bind}"
            extra_binds="${extra_binds} --bind ${host}:${container}"
            i=$((i + 1))
        done
    fi
    sed -i "s|__EXTRA_BINDS__|${extra_binds}|g" ~/start-proot.sh

    execute chmod +x ~/start-proot.sh
    log_success "Created ~/start-proot.sh"
}

create_proot_menu_sync() {
    local desktop_type="${DE}"
    [[ "${desktop_type}" == "kde" ]] && local menu_cmd="kbuildsycoca6" || local menu_cmd="true"

    execute cat > ~/proot-menu-sync.sh << 'SYNCEOF'
#!/data/data/com.termux/files/usr/bin/bash
# Proot App Menu Bridge for Hyprland/KDE
# Auto-generated by termux-wayland-installer

PROOT_DISTRO="${1:-__PROOT_DISTRO__}"
PROOT_BIN="/data/data/com.termux/files/usr/bin/proot-distro"
PROOT_ROOTFS="/data/data/com.termux/files/usr/var/lib/proot-distro/installed-rootfs/${PROOT_DISTRO}"
PROOT_APPS="${PROOT_ROOTFS}/usr/share/applications"
BRIDGE_DIR="${HOME}/.local/share/applications/proot-bridge"
WRAPPER_DIR="${HOME}/.local/share/proot-wrappers"
TERMUX_TMP="${TMPDIR:-/data/data/com.termux/files/usr/tmp}"
DESKTOP="__DESKTOP__"
PROOT_USERNAME="__PROOT_USERNAME__"

if [[ ! -f "${PROOT_BIN}" ]]; then
    echo "[!] proot-distro not found"
    exit 1
fi
if [[ ! -d "${PROOT_ROOTFS}" ]]; then
    echo "[!] Proot distro '${PROOT_DISTRO}' not installed"
    exit 0
fi
if [[ ! -d "${PROOT_APPS}" ]]; then
    echo "[!] No proot apps yet"
    exit 0
fi

mkdir -p "${BRIDGE_DIR}" "${WRAPPER_DIR}"

SYNCED=0
REMOVED=0

# Remove stale bridges
for bridge_file in "${BRIDGE_DIR}"/proot-*.desktop; do
    [[ -f "${bridge_file}" ]] || continue
    original_name=$(basename "${bridge_file}" | sed 's/^proot-//')
    if [[ ! -f "${PROOT_APPS}/${original_name}" ]]; then
        rm -f "${bridge_file}" "${WRAPPER_DIR}/proot-${original_name%.desktop}.sh"
        REMOVED=$((REMOVED + 1))
    fi
done

# Sync current apps
for desktop_file in "${PROOT_APPS}"/*.desktop; do
    [[ -f "${desktop_file}" ]] || continue
    filename=$(basename "${desktop_file}")
    appname="${filename%.desktop}"
    output="${BRIDGE_DIR}/proot-${filename}"
    wrapper="${WRAPPER_DIR}/proot-${appname}.sh"

    grep -q "^NoDisplay=true" "${desktop_file}" 2>/dev/null && continue
    grep -q "^Hidden=true"    "${desktop_file}" 2>/dev/null && continue

    ORIGINAL_EXEC=$(grep "^Exec=" "${desktop_file}" | head -1 | sed 's/^Exec=//')
    [[ -z "${ORIGINAL_EXEC}" ]] && continue
    CLEAN_EXEC=$(echo "${ORIGINAL_EXEC}" | sed 's/ %[a-zA-Z]//g; s/%[a-zA-Z]//g')

    APP_CMD="${CLEAN_EXEC}"
    EXTRA_ENV=""

    echo "${appname}" | grep -qi "libreoffice\|soffice" && \
        APP_CMD="${CLEAN_EXEC} --norestore --nofirststartwizard"

    if echo "${appname}" | grep -qi "blender"; then
        if "${PROOT_BIN}" login "${PROOT_DISTRO}" -- ldconfig -p 2>/dev/null | grep -q "libvulkan.so.1"; then
            EXTRA_ENV="export GALLIUM_DRIVER=zink; export MESA_GL_VERSION_OVERRIDE=4.6; export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d.termux/freedreno_icd.aarch64.json;"
        else
            EXTRA_ENV="export LIBGL_ALWAYS_SOFTWARE=1; export GALLIUM_DRIVER=llvmpipe;"
        fi
    fi

    cat > "${wrapper}" << WRAPEOF
#!/data/data/com.termux/files/usr/bin/bash
PROOT_BIN="${PROOT_BIN}"
PROOT_DISTRO="${PROOT_DISTRO}"
PROOT_USERNAME="${PROOT_USERNAME}"
TERMUX_TMP="${TMPDIR:-/data/data/com.termux/files/usr/tmp}"
LOG="${TERMUX_TMP}/proot-${appname}.log"

BINDS=""
X11_DIR="${TERMUX_TMP}/.X11-unix"
[ -d "${X11_DIR}" ]     && BINDS="${BINDS} --bind ${X11_DIR}:/tmp/.X11-unix"
[ -d "/dev/dri" ]      && BINDS="${BINDS} --bind /dev/dri:/dev/dri"
[ -e "/dev/kgsl-3d0" ] && BINDS="${BINDS} --bind /dev/kgsl-3d0:/dev/kgsl-3d0"

{
echo "[+] Launching ${appname} at \$(date)"
${PROOT_BIN} login "${PROOT_DISTRO}" ${BINDS} --user "${PROOT_USERNAME}" -- /bin/bash -c "
export DISPLAY=:0
export WAYLAND_DISPLAY=wayland-0
export XDG_SESSION_TYPE=wayland
export XDG_CURRENT_DESKTOP=${DESKTOP}
export XDG_RUNTIME_DIR=/tmp
export MESA_NO_ERROR=1
${EXTRA_ENV}
dbus-run-session ${APP_CMD}
"
EXIT_CODE=\$?
echo "Exit: \$EXIT_CODE at \$(date)"
} > "${LOG}" 2>&1

[ \$EXIT_CODE -ne 0 ] && \
    __TERMINAL__ --title="${appname} error" \
        -e bash -c "cat ${LOG}; echo; read -p 'Press Enter'" &
WRAPEOF

    # Replace terminal based on DE
    if [[ "${DESKTOP}" == "KDE" ]]; then
        sed -i "s/__TERMINAL__/konsole/g" "${wrapper}"
    else
        sed -i "s/__TERMINAL__/foot/g" "${wrapper}"
    fi

    chmod +x "${wrapper}"

    cp "${desktop_file}" "${output}"
    sed -i \
        -e "s|^Exec=.*|Exec=${wrapper}|" \
        -e "s|^TryExec=.*|TryExec=${wrapper}|" \
        -e '/^NoDisplay=/d' -e '/^Hidden=/d' \
        "${output}"
    echo "NoDisplay=false" >> "${output}"

    APP_NAME=$(grep "^Name=" "${output}" | head -1 | sed 's/^Name=//')
    [[ "${APP_NAME}" != \[P\]* ]] && sed -i "s|^Name=.*|Name=[P] ${APP_NAME}|" "${output}"
    SYNCED=$((SYNCED + 1))
done

echo "[+] ${DESKTOP} Bridge: ${SYNCED} synced, ${REMOVED} removed"
echo "    Logs: \${TERMUX_TMP}/proot-<appname>.log"

# Refresh menu
__MENU_CMD__
SYNCEOF

    sed -i "s/__PROOT_DISTRO__/${PROOT_DISTRO}/g" ~/proot-menu-sync.sh
    sed -i "s/__DESKTOP__/${desktop_type}/g" ~/proot-menu-sync.sh
    sed -i "s/__PROOT_USERNAME__/${PROOT_USERNAME}/g" ~/proot-menu-sync.sh
    sed -i "s/__TERMINAL__/foot/g" ~/proot-menu-sync.sh
    sed -i "s/__MENU_CMD__/${menu_cmd}/g" ~/proot-menu-sync.sh

    execute chmod +x ~/proot-menu-sync.sh
    log_success "Created ~/proot-menu-sync.sh"

    # Initial sync
    execute bash ~/proot-menu-sync.sh "${PROOT_DISTRO}" 2>/dev/null || true
}

export -f create_start_proot_script create_proot_menu_sync