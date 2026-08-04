#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
# termux-wayland-installer - Theme Definitions
# Color palettes and theme-specific configs
# ============================================================

# Theme metadata
declare -A THEME_NAMES=(
    ["catppuccin"]="Catppuccin"
    ["everforest"]="Everforest"
    ["tokyonight"]="Tokyo Night"
    ["dracula"]="Dracula"
    ["nord"]="Nord"
    ["rose-pine"]="Rose Pine"
    ["gruvbox"]="Gruvbox"
)

declare -A THEME_VARIANTS=(
    ["catppuccin"]="mocha macchiato frappe latte"
    ["everforest"]="dark light"
    ["tokyonight"]="storm night day"
    ["dracula"]="default"
    ["nord"]="default"
    ["rose-pine"]="main dawn moon"
    ["gruvbox"]="dark light"
)

# Color definitions for each theme (base16 format)
# Format: base00 base01 base02 base03 base04 base05 base06 base07 base08 base09 base0A base0B base0C base0D base0E base0F

declare -A THEME_CATPPUCCIN_MOCHA=(
    [base00]="#1e1e2e"  [base01]="#181825"  [base02]="#313244"  [base03]="#45475a"
    [base04]="#585b70"  [base05]="#cdd6f4"  [base06]="#bac2de"  [base07]="#a6adc8"
    [base08]="#f38ba8"  [base09]="#fab387"  [base0A]="#f9e2af"  [base0B]="#a6e3a1"
    [base0C]="#94e2d5"  [base0D]="#89b4fa"  [base0E]="#cba6f7"  [base0F]="#f5e0dc"
    [accent]="#cba6f7"  [red]="#f38ba8"     [green]="#a6e3a1"   [yellow]="#f9e2af"
    [blue]="#89b4fa"    [magenta]="#cba6f7" [cyan]="#94e2d5"    [orange]="#fab387"
)

declare -A THEME_CATPPUCCIN_MACCHIATO=(
    [base00]="#24273a"  [base01]="#1e2030"  [base02]="#363a4f"  [base03]="#494d64"
    [base04]="#5b6078"  [base05]="#cad3f5"  [base06]="#b7bdf8"  [base07]="#a5adcb"
    [base08]="#ed8796"  [base09]="#f5a97f"  [base0A]="#eed49f"  [base0B]="#a6da95"
    [base0C]="#8bd5ca"  [base0D]="#8aadf4"  [base0E]="#c6a0f6"  [base0F]="#f4dbd6"
    [accent]="#c6a0f6"  [red]="#ed8796"     [green]="#a6da95"   [yellow]="#eed49f"
    [blue]="#8aadf4"    [magenta]="#c6a0f6" [cyan]="#8bd5ca"    [orange]="#f5a97f"
)

declare -A THEME_EVERFOREST_DARK=(
    [base00]="#2d353b"  [base01]="#272e33"  [base02]="#3a464c"  [base03]="#42504d"
    [base04]="#4f585e"  [base05]="#d3c6aa"  [base06]="#e6d8b4"  [base07]="#fdf6e3"
    [base08]="#e67e80"  [base09]="#e69875"  [base0A]="#dbbc7f"  [base0B]="#a7c080"
    [base0C]="#83c092"  [base0D]="#7fbbb3"  [base0E]="#d699b6"  [base0F]="#a7c080"
    [accent]="#a7c080"  [red]="#e67e80"     [green]="#a7c080"   [yellow]="#dbbc7f"
    [blue]="#7fbbb3"    [magenta]="#d699b6" [cyan]="#83c092"    [orange]="#e69875"
)

declare -A THEME_EVERFOREST_LIGHT=(
    [base00]="#fdf6e3"  [base01]="#e6d8b4"  [base02]="#d3c6aa"  [base03]="#859289"
    [base04]="#7a8478"  [base05]="#5c6a72"  [base06]="#42504d"  [base07]="#272e33"
    [base08]="#f85552"  [base09]="#f57d26"  [base0A]="#dfa000"  [base0B]="#8da101"
    [base0C]="#35a77c"  [base0D]="#3a94c5"  [base0E]="#df69ba"  [base0F]="#8da101"
    [accent]="#8da101"  [red]="#f85552"     [green]="#8da101"   [yellow]="#dfa000"
    [blue]="#3a94c5"    [magenta]="#df69ba" [cyan]="#35a77c"    [orange]="#f57d26"
)

declare -A THEME_TOKYONIGHT_STORM=(
    [base00]="#24283b"  [base01]="#1f2335"  [base02]="#414868"  [base03]="#565f89"
    [base04]="#737aa2"  [base05]="#c0caf5"  [base06]="#a9b1d6"  [base07]="#9aa5ce"
    [base08]="#f7768e"  [base09]="#ff9e64"  [base0A]="#e0af68"  [base0B]="#9ece6a"
    [base0C]="#73daca"  [base0D]="#7aa2f7"  [base0E]="#bb9af7"  [base0F]="#9d7cd8"
    [accent]="#7aa2f7"  [red]="#f7768e"     [green]="#9ece6a"   [yellow]="#e0af68"
    [blue]="#7aa2f7"    [magenta]="#bb9af7" [cyan]="#73daca"    [orange]="#ff9e64"
)

declare -A THEME_TOKYONIGHT_NIGHT=(
    [base00]="#1a1b26"  [base01]="#16161e"  [base02]="#2f354d"  [base03]="#444b6a"
    [base04]="#565f89"  [base05]="#c0caf5"  [base06]="#a9b1d6"  [base07]="#9aa5ce"
    [base08]="#f7768e"  [base09]="#ff9e64"  [base0A]="#e0af68"  [base0B]="#9ece6a"
    [base0C]="#73daca"  [base0D]="#7aa2f7"  [base0E]="#bb9af7"  [base0F]="#9d7cd8"
    [accent]="#7aa2f7"  [red]="#f7768e"     [green]="#9ece6a"   [yellow]="#e0af68"
    [blue]="#7aa2f7"    [magenta]="#bb9af7" [cyan]="#73daca"    [orange]="#ff9e64"
)

declare -A THEME_DRACULA=(
    [base00]="#282a36"  [base01]="#191a21"  [base02]="#3a3c4e"  [base03]="#4d4f68"
    [base04]="#626483"  [base05]="#f8f8f2"  [base06]="#e9e9e4"  [base07]="#dcdcd8"
    [base08]="#ff5555"  [base09]="#ffb86c"  [base0A]="#f1fa8c"  [base0B]="#50fa7b"
    [base0C]="#8be9fd"  [base0D]="#bd93f9"  [base0E]="#ff79c6"  [base0F]="#ff79c6"
    [accent]="#bd93f9"  [red]="#ff5555"     [green]="#50fa7b"   [yellow]="#f1fa8c"
    [blue]="#bd93f9"    [magenta]="#ff79c6" [cyan]="#8be9fd"    [orange]="#ffb86c"
)

declare -A THEME_NORD=(
    [base00]="#2e3440"  [base01]="#3b4252"  [base02]="#434c5e"  [base03]="#4c566a"
    [base04]="#d8dee9"  [base05]="#e5e9f0"  [base06]="#eceff4"  [base07]="#8fbcbb"
    [base08]="#bf616a"  [base09]="#d08770"  [base0A]="#ebcb8b"  [base0B]="#a3be8c"
    [base0C]="#88c0d0"  [base0D]="#81a1c1"  [base0E]="#b48ead"  [base0F]="#d08770"
    [accent]="#88c0d0"  [red]="#bf616a"     [green]="#a3be8c"   [yellow]="#ebcb8b"
    [blue]="#81a1c1"    [magenta]="#b48ead" [cyan]="#88c0d0"    [orange]="#d08770"
)

declare -A THEME_ROSE_PINE_MAIN=(
    [base00]="#191724"  [base01]="#1f1d2e"  [base02]="#26233a"  [base03]="#6e6a86"
    [base04]="#908caa"  [base05]="#e0def4"  [base06]="#e0def4"  [base07]="#524f67"
    [base08]="#eb6f92"  [base09]="#f6c177"  [base0A]="#ebbcba"  [base0B]="#31748f"
    [base0C]="#9ccfd8"  [base0D]="#c4a7e7"  [base0E]="#e0def4"  [base0F]="#524f67"
    [accent]="#c4a7e7"  [red]="#eb6f92"     [green]="#31748f"   [yellow]="#f6c177"
    [blue]="#c4a7e7"    [magenta]="#e0def4" [cyan]="#9ccfd8"    [orange]="#f6c177"
)

declare -A THEME_GRUVBOX_DARK=(
    [base00]="#282828"  [base01]="#3c3836"  [base02]="#504945"  [base03]="#665c54"
    [base04]="#bdae93"  [base05]="#d5c4a1"  [base06]="#ebdbb2"  [base07]="#fbf1c7"
    [base08]="#fb4934"  [base09]="#fe8019"  [base0A]="#fabd2f"  [base0B]="#b8bb26"
    [base0C]="#8ec07c"  [base0D]="#83a598"  [base0E]="#d3869b"  [base0F]="#d65d0e"
    [accent]="#fabd2f"  [red]="#fb4934"     [green]="#b8bb26"   [yellow]="#fabd2f"
    [blue]="#83a598"    [magenta]="#d3869b" [cyan]="#8ec07c"    [orange]="#fe8019"
)

# Apply theme colors to global variables
apply_theme() {
    local theme="${1:-${CFG_GENERAL_THEME:-catppuccin}}"
    local variant="${2:-${CFG_GENERAL_THEME_VARIANT:-mocha}}"
    local theme_key="THEME_${theme^^//-/_}_${variant^^}"

    log_info "Applying theme: ${theme} (${variant})"

    # Check if theme exists
    if ! declare -p "${theme_key}" &>/dev/null; then
        log_warn "Theme ${theme} variant ${variant} not found, falling back to catppuccin mocha"
        theme_key="THEME_CATPPUCCIN_MOCHA"
    fi

    # Export all colors
    local -n theme_ref="${theme_key}"
    for color in "${!theme_ref[@]}"; do
        export "THEME_${color^^}"="${theme_ref[$color]}"
    done

    # Export common aliases
    export THEME_BASE00="${theme_ref[base00]}"
    export THEME_BASE01="${theme_ref[base01]}"
    export THEME_BASE02="${theme_ref[base02]}"
    export THEME_BASE03="${theme_ref[base03]}"
    export THEME_BASE04="${theme_ref[base04]}"
    export THEME_BASE05="${theme_ref[base05]}"
    export THEME_BASE06="${theme_ref[base06]}"
    export THEME_BASE07="${theme_ref[base07]}"
    export THEME_BASE08="${theme_ref[base08]}"
    export THEME_BASE09="${theme_ref[base09]}"
    export THEME_BASE0A="${theme_ref[base0A]}"
    export THEME_BASE0B="${theme_ref[base0B]}"
    export THEME_BASE0C="${theme_ref[base0C]}"
    export THEME_BASE0D="${theme_ref[base0D]}"
    export THEME_BASE0E="${theme_ref[base0E]}"
    export THEME_BASE0F="${theme_ref[base0F]}"
    export THEME_ACCENT="${theme_ref[accent]}"
    export THEME_RED="${theme_ref[red]}"
    export THEME_GREEN="${theme_ref[green]}"
    export THEME_YELLOW="${theme_ref[yellow]}"
    export THEME_BLUE="${theme_ref[blue]}"
    export THEME_MAGENTA="${theme_ref[magenta]}"
    export THEME_CYAN="${theme_ref[cyan]}"
    export THEME_ORANGE="${theme_ref[orange]}"

    log_success "Theme applied: ${THEME_NAMES[$theme]:-$theme} ${variant}"
}

# Get theme color
theme_color() {
    local color="$1"
    local var="THEME_${color^^}"
    echo "${!var:-}"
}

# Validate theme
validate_theme() {
    local theme="$1"
    local variant="${2:-}"

    if [[ -z "${THEME_NAMES[$theme]:-}" ]]; then
        log_error "Unknown theme: ${theme}"
        log_info "Available themes: ${!THEME_NAMES[*]}"
        return 1
    fi

    if [[ -n "${variant}" ]]; then
        local variants="${THEME_VARIANTS[$theme]}"
        if [[ ! " ${variants} " =~ " ${variant} " ]]; then
            log_error "Unknown variant for ${theme}: ${variant}"
            log_info "Available variants: ${variants}"
            return 1
        fi
    fi

    return 0
}

# List available themes
list_themes() {
    for theme in "${!THEME_NAMES[@]}"; do
        echo "${theme}: ${THEME_NAMES[$theme]} (variants: ${THEME_VARIANTS[$theme]})"
    done
}

# Get theme colors as export statements
theme_get() {
    local theme="${1:-${CFG_GENERAL_THEME:-catppuccin}}"
    local variant="${2:-${CFG_GENERAL_THEME_VARIANT:-mocha}}"
    local theme_key="THEME_${theme^^//-/_}_${variant^^}"

    if ! declare -p "${theme_key}" &>/dev/null; then
        theme_key="THEME_CATPPUCCIN_MOCHA"
    fi

    local -n theme_ref="${theme_key}"
    local output=""
    for color in "${!theme_ref[@]}"; do
        output="${output}export BASE16_${color^^}=\"${theme_ref[$color]}\"; "
    done
    echo "${output}"
}

export -f apply_theme theme_color validate_theme list_themes theme_get