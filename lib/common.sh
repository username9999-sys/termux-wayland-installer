#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
# termux-wayland-installer - Shared Library
# Common functions for all installer modules
# ============================================================

# ---- Strict Mode ----
set -euo pipefail
IFS=$'\n\t'

# ---- Global Constants ----
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly LIB_DIR="${SCRIPT_DIR}/lib"
readonly CONFIG_DIR="${SCRIPT_DIR}/config"
readonly MODULES_DIR="${SCRIPT_DIR}/modules"
readonly HEALTH_DIR="${SCRIPT_DIR}/health"
readonly LOG_DIR="${TMPDIR:-/data/data/com.termux/files/usr/tmp}/termux-wayland-installer"
readonly LOG_FILE="${LOG_DIR}/install-$(date +%Y%m%d-%H%M%S).log"

# ---- Colors ----
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly GRAY='\033[0;90m'
readonly NC='\033[0m'
readonly BOLD='\033[1m'

# Catppuccin Mocha
readonly ROSEWATER="#f5e0dc"
readonly FLAMINGO="#f2cdcd"
readonly PINK="#f5c2e7"
readonly MAUVE="#cba6f7"
readonly RED_C="#f38ba8"
readonly MAROON="#eba0ac"
readonly PEACH="#fab387"
readonly YELLOW_C="#f9e2af"
readonly GREEN_C="#a6e3a1"
readonly TEAL="#94e2d5"
readonly SKY="#89dceb"
readonly SAPPHIRE="#74c7ec"
readonly BLUE_C="#89b4fa"
readonly LAVENDER="#b4befe"
readonly TEXT="#cdd6f4"
readonly SUBTEXT1="#bac2de"
readonly SUBTEXT0="#a6adc8"
readonly OVERLAY2="#9399b2"
readonly OVERLAY1="#7f849c"
readonly OVERLAY0="#6c7086"
readonly SURFACE2="#585b70"
readonly SURFACE1="#45475a"
readonly SURFACE0="#313244"
readonly BASE="#1e1e2e"
readonly MANTLE="#181825"
readonly CRUST="#11111b"

# ---- Logging ----
mkdir -p "${LOG_DIR}"

log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local output="[${timestamp}] [${level}] ${message}"
    echo -e "${output}"
    echo -e "${output}" >> "${LOG_FILE}" 2>/dev/null || true
}

log_info() { log "INFO" "$@"; }
log_warn() { log "WARN" "${YELLOW}$*${NC}"; }
log_error() { log "ERROR" "${RED}$*${NC}"; }
log_debug() { [[ "${VERBOSE:-false}" == "true" ]] && log "DEBUG" "${GRAY}$*${NC}" || true; }
log_success() { log "SUCCESS" "${GREEN}$*${NC}"; }

# ---- User-facing output (not logged) ----
# ---- User-facing output (not logged) ----
print_banner() {
    local title="$1"
    local subtitle="${2:-}"
    clear
    echo -e "${MAUVE}"
    cat << 'EOF'
    ████████╗███████╗██████╗ ███████╗
    ╚══██╔══╝██╔════╝██╔══██╗██╔════╝
       ██║   █████╗  ██████╔╝███████╗
       ██║   ██╔══╝  ██╔══██╗╚════██║
       ██║   ███████╗██║  ██║███████║
       ╚══════╝╚══════╝╚══════╝╚══════╝

EOF
    echo -e "${NC}"
    echo -e "${TEXT}${title}${NC}"
    [[ -n "${subtitle}" ]] && echo -e "${SUBTEXT1}${subtitle}${NC}"
    echo ""
}

print_step() {
    local current="$1"
    local total="$2"
    local title="$3"
    local percent=$((current * 100 / total))
    local filled=$((percent / 5))
    local empty=$((20 - filled))
    local bar="${MAUVE}"
    for ((i=0; i<filled; i++)); do bar+="▰"; done
    bar+="${SURFACE1}"
    for ((i=0; i<empty; i++)); do bar+="▱"; done
    bar+="${NC}"
    echo ""
    echo -e "${TEXT}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${MAUVE}  PROGRESS: ${TEXT}Step ${current}/${total}${NC} ${bar} ${TEXT}${percent}%${NC}"
    echo -e "${TEXT}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${PURPLE}[Step ${current}/${total}] ${title}${NC}"
    echo ""
}

spinner() {
    local pid=$1
    local message=$2
    local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0
    while kill -0 "${pid}" 2>/dev/null; do
        i=$(( (i+1) % 10 ))
        printf "\r  ${SKY}[${spin:$i:1}]${NC} ${message}  "
        sleep 0.08
    done
    wait "${pid}"
    local exit_code=$?
    if [[ ${exit_code} -eq 0 ]]; then
        printf "\r  ${GREEN_C}[✓]${NC} ${message}                    \n"
    else
        printf "\r  ${RED_C}[✗]${NC} ${message} ${RED_C}(failed, exit=${exit_code})${NC}     \n"
        log_error "${message} failed with exit code ${exit_code}"
    fi
    return ${exit_code}
}

run_with_spinner() {
    local message="$1"
    shift
    ( "$@" ) &
    spinner $! "${message}"
}

# ---- Configuration ----
load_config() {
    local config_file="${1:-${CONFIG_DIR}/install.yaml}"
    if [[ ! -f "${config_file}" ]]; then
        log_error "Config file not found: ${config_file}"
        return 1
    fi

    # Parse YAML with minimal bash (for simple key: value)
    while IFS=':' read -r key value; do
        key=$(echo "${key}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        value=$(echo "${value}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//;s/^"//;s/"$//;s/^'"'"'//;s/'"'"'$//')
        [[ -z "${key}" || "${key}" =~ ^# ]] && continue
        [[ "${key}" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]] && export "CFG_${key^^}=${value}"
    done < <(grep -E '^[[:space:]]*[a-zA-Z_][a-zA-Z0-9_]*:' "${config_file}" | head -100)

    log_debug "Loaded config from ${config_file}"
}

# ---- Device Detection ----
detect_device() {
    export DEVICE_MODEL=$(getprop ro.product.model 2>/dev/null || echo "Unknown")
    export DEVICE_BRAND=$(getprop ro.product.brand 2>/dev/null || echo "Unknown")
    export ANDROID_VERSION=$(getprop ro.build.version.release 2>/dev/null || echo "Unknown")
    export CPU_ABI=$(getprop ro.product.cpu.abi 2>/dev/null || echo "arm64-v8a")
    export GPU_VENDOR=$(getprop ro.hardware.egl 2>/dev/null || echo "")
    export TOTAL_RAM_KB=$(grep MemTotal /proc/meminfo 2>/dev/null | awk '{print $2}' || echo "0")
    export TOTAL_RAM_GB=$((TOTAL_RAM_KB / 1024 / 1024))

    if [[ "${GPU_VENDOR}" == *"adreno"* ]] || \
       [[ "${DEVICE_BRAND}" =~ [Ss]amsung|[Oo]ne[Pp]lus|[Xx]iaomi|[Rr]edmi|[Pp]oco|[Mm]oto|motorola ]]; then
        export GPU_DRIVER="freedreno"
        export GPU_TYPE="adreno"
    else
        export GPU_DRIVER="zink"
        export GPU_TYPE="non-adreno"
    fi

    log_info "Device: ${DEVICE_BRAND} ${DEVICE_MODEL} (Android ${ANDROID_VERSION}, ${CPU_ABI})"
    log_info "GPU: ${GPU_TYPE} (${GPU_DRIVER}), RAM: ${TOTAL_RAM_GB}GB"
}

# ---- Package Management ----
install_pkg() {
    local pkg="$1"
    local name="${2:-$pkg}"
    local max_retries="${3:-2}"
    local version="${4:-}"  # Optional version parameter

    # Check for pinned version if not explicitly provided
    if [[ -z "${version}" ]]; then
        version=$(get_pinned_version "${pkg}")
    fi

    local install_target="${pkg}"
    [[ -n "${version}" ]] && install_target="${pkg}=${version}"

    log_info "Installing ${name} (${install_target})"

    for attempt in $(seq 1 "${max_retries}"); do
        if (DEBIAN_FRONTEND=noninteractive apt-get install -y \
            -o Dpkg::Options::="--force-confold" "${install_target}" > /dev/null 2>&1); then
            log_success "Installed ${name} ${version:+(${version})}"
            return 0
        fi
        log_warn "Attempt ${attempt}/${max_retries} failed for ${name}, retrying..."
        apt-get update -y > /dev/null 2>&1 || true
        sleep 2
    done

    log_error "Failed to install ${name} (${install_target}) after ${max_retries} attempts"
    return 1
}

install_pkgs() {
    local pkgs=("$@")
    local failed=()

    for pkg_spec in "${pkgs[@]}"; do
        IFS='|' read -r pkg name <<< "${pkg_spec}"
        name="${name:-$pkg}"
        # Check for pinned version
        local version=$(get_pinned_version "${pkg}")
        if ! install_pkg "${pkg}" "${name}" 2 "${version}"; then
            failed+=("${name}")
        fi
    done

    if [[ ${#failed[@]} -gt 0 ]]; then
        log_error "Failed to install: ${failed[*]}"
        return 1
    fi
    return 0
}

pkg_installed() {
    dpkg -l "$1" 2>/dev/null | grep -q '^ii'
}

# ---- GPU Environment ----
setup_gpu_env() {
    local target_file="$1"
    cat > "${target_file}" << 'EOF'
# Hyprland/KDE GPU Environment
export MESA_NO_ERROR=1
export MESA_GL_VERSION_OVERRIDE=4.6
export MESA_GLES_VERSION_OVERRIDE=3.2
export GALLIUM_DRIVER=zink
export MESA_LOADER_DRIVER_OVERRIDE=zink
export TU_DEBUG=noconform
export ZINK_DESCRIPTORS=lazy
export MESA_VK_WSI_PRESENT_MODE=immediate
export XDG_SESSION_TYPE=wayland
export XDG_CURRENT_DESKTOP=Hyprland
export XDG_DATA_DIRS=/data/data/com.termux/files/usr/share:${XDG_DATA_DIRS:-}
export XDG_CONFIG_DIRS=/data/data/com.termux/files/usr/etc/xdg:${XDG_CONFIG_DIRS:-}
export QT_QPA_PLATFORM=wayland
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
export SDL_VIDEODRIVER=wayland
export CLUTTER_BACKEND=wayland
export GBM_BACKEND=nvidia-drm
export __GL_GSYNC_ALLOWED=0
export __GL_VRR_ALLOWED=0
export WLR_NO_HARDWARE_CURSORS=1
export WLR_RENDERER_ALLOW_SOFTWARE=1
EOF

    # Adreno-specific
    if [[ "${GPU_DRIVER}" == "freedreno" ]]; then
        cat >> "${target_file}" << 'EOF'
export VK_ICD_FILENAMES=/data/data/com.termux/files/usr/share/vulkan/icd.d/freedreno_icd.aarch64.json
EOF
    fi
}

# ---- Proot Helpers ----
proot_bind_mounts() {
    local binds=""
    local termux_tmp="${TMPDIR:-/data/data/com.termux/files/usr/tmp}"

    [[ -d "${termux_tmp}/.X11-unix" ]] && binds="${binds} --bind ${termux_tmp}/.X11-unix:/tmp/.X11-unix"
    [[ -d "/dev/dri" ]] && binds="${binds} --bind /dev/dri:/dev/dri"
    [[ -e "/dev/kgsl-3d0" ]] && binds="${binds} --bind /dev/kgsl-3d0:/dev/kgsl-3d0"
    [[ -d "/data/data/com.termux/files/usr/share/vulkan/icd.d" ]] && \
        binds="${binds} --bind /data/data/com.termux/files/usr/share/vulkan/icd.d:/usr/share/vulkan/icd.d.termux"
    [[ -f "/data/data/com.termux/files/usr/lib/libvulkan.so" ]] && \
        binds="${binds} --bind /data/data/com.termux/files/usr/lib/libvulkan.so:/usr/lib/libvulkan_termux.so"

    echo "${binds}"
}

proot_create_rc() {
    local rc_file="$1"
    local desktop="${2:-Hyprland}"
    local username="${3:-user}"

    cat > "${rc_file}" << EOF
export DISPLAY=:0
export WAYLAND_DISPLAY=wayland-0
export XDG_SESSION_TYPE=wayland
export XDG_CURRENT_DESKTOP=${desktop}
export MESA_NO_ERROR=1
export MESA_GL_VERSION_OVERRIDE=4.6
export MESA_GLES_VERSION_OVERRIDE=3.2
export GALLIUM_DRIVER=zink
export MESA_LOADER_DRIVER_OVERRIDE=zink
export TU_DEBUG=noconform
export ZINK_DESCRIPTORS=lazy
export MESA_VK_WSI_PRESENT_MODE=immediate
[ -f /usr/share/vulkan/icd.d.termux/freedreno_icd.aarch64.json ] && \\
    export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d.termux/freedreno_icd.aarch64.json
export XDG_DATA_DIRS=/usr/share:/usr/local/share:\${XDG_DATA_DIRS}
export XDG_CONFIG_DIRS=/etc/xdg:\${XDG_CONFIG_DIRS}
export XDG_RUNTIME_DIR=/tmp
export PS1="\[\033[01;32m\]${username}@linux\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ "
echo ""
echo " User: ${username} | Session: Wayland | WM: ${desktop}"
echo " Type 'exit' to leave proot."
echo ""
EOF
}

# ---- Verification ----
verify_checksum() {
    local file="$1"
    local expected_sha256="$2"
    local actual
    actual=$(sha256sum "${file}" 2>/dev/null | awk '{print $1}')
    [[ "${actual}" == "${expected_sha256}" ]]
}

download_verified() {
    local url="$1"
    local output="$2"
    local expected_sha256="${3:-}"
    local max_tries="${4:-3}"
    local timeout="${5:-30}"

    for attempt in $(seq 1 "${max_tries}"); do
        if wget -L -q --timeout="${timeout}" -O "${output}" "${url}" 2>/dev/null; then
            if [[ -n "${expected_sha256}" ]]; then
                if verify_checksum "${output}" "${expected_sha256}"; then
                    log_success "Downloaded and verified: ${output}"
                    return 0
                else
                    log_warn "Checksum mismatch for ${output}, retrying..."
                    rm -f "${output}"
                fi
            else
                log_success "Downloaded: ${output}"
                return 0
            fi
        fi
        sleep 2
    done
    log_error "Failed to download ${url} after ${max_tries} attempts"
    return 1
}

# ---- Cleanup ----
cleanup_on_exit() {
    local exit_code=$?
    if [[ ${exit_code} -ne 0 ]]; then
        log_error "Installation failed with exit code ${exit_code}"
        log_error "Check log: ${LOG_FILE}"
    fi
    # Kill any background jobs
    jobs -p | xargs -r kill 2>/dev/null || true
}
trap cleanup_on_exit EXIT

# ---- Argument Parsing ----
parse_args() {
    DRY_RUN=false
    UNINSTALL=false
    UPDATE_MODE=false
    VERBOSE=false
    CONFIG_FILE=""
    THEME_OVERRIDE=""
    DISTRO_OVERRIDE=""
    USER_OVERRIDE=""
    VARIANT_OVERRIDE=""
    DESKTOP_OVERRIDE=""

    while [[ $# -gt 0 ]]; do
        case $1 in
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --uninstall)
                UNINSTALL=true
                shift
                ;;
            --update)
                UPDATE_MODE=true
                shift
                ;;
            --verbose|-v)
                VERBOSE=true
                shift
                ;;
            --config)
                CONFIG_FILE="$2"
                shift 2
                ;;
            --theme)
                THEME_OVERRIDE="$2"
                shift 2
                ;;
            --variant)
                VARIANT_OVERRIDE="$2"
                shift 2
                ;;
            --distro)
                DISTRO_OVERRIDE="$2"
                shift 2
                ;;
            --desktop)
                DESKTOP_OVERRIDE="$2"
                shift 2
                ;;
            --input-method)
                INPUT_METHOD_OVERRIDE="$2"
                shift 2
                ;;
            --autostart)
                AUTOSTART_OVERRIDE="true"
                shift
                ;;
            --user)
                USER_OVERRIDE="$2"
                shift 2
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done

    export DRY_RUN UNINSTALL UPDATE_MODE VERBOSE
    export CONFIG_FILE THEME_OVERRIDE DISTRO_OVERRIDE USER_OVERRIDE VARIANT_OVERRIDE DESKTOP_OVERRIDE INPUT_METHOD_OVERRIDE AUTOSTART_OVERRIDE
}

show_help() {
    cat << 'EOF'
Usage: termux-wayland-installer [OPTIONS]

Options:
  --dry-run          Preview changes without executing
  --uninstall        Remove installed components
  --update           Update existing installation
  --verbose, -v      Enable debug logging
  --config FILE      Use custom config file
  --theme THEME      Override theme (catppuccin, everforest, tokyonight, dracula, nord, rose-pine, gruvbox)
  --variant VARIANT  Override theme variant (e.g., dark, light, mocha, night, storm)
  --distro DISTRO    Override proot distro (archlinux, debian, ubuntu, fedora, alpine)
  --desktop DE       Desktop environment (hyprland, kde)
  --user USERNAME    Set non-root username for proot
  --help, -h         Show this help

Config file: ./config/install.yaml (or specify with --config)

Examples:
  termux-wayland-installer                              # Interactive install
  termux-wayland-installer --dry-run                    # Preview
  termux-wayland-installer --theme everforest --variant dark  # Custom theme
  termux-wayland-installer --distro debian              # Use Debian proot
  termux-wayland-installer --desktop kde --theme nord   # KDE with Nord theme
  termux-wayland-installer --uninstall                  # Remove everything
EOF
}

# ---- Dry-run wrapper ----
execute() {
    # In DRY_RUN mode, still allow safe operations (mkdir, etc.) but log everything
    if [[ "${DRY_RUN}" == "true" ]]; then
        log_info "[DRY-RUN] $*"
        # Allow safe operations to actually run in dry-run
        case "$1" in
            mkdir|cat|chmod|touch|cp|ln|sed)
                # Actually run safe commands even in dry-run
                "$@"
                ;;
            *)
                # Just log other commands
                return 0
                ;;
        esac
    else
        "$@"
    fi
}

# ---- Export all functions ----
export -f log log_info log_warn log_error log_debug log_success
export -f print_banner print_step spinner run_with_spinner
export -f load_config detect_device install_pkg install_pkgs pkg_installed
export -f setup_gpu_env proot_bind_mounts proot_create_rc
export -f verify_checksum download_verified cleanup_on_exit
export -f parse_args show_help execute