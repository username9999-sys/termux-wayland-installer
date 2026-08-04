#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
# termux-wayland-installer - Step: Theme Configurations
# ============================================================

step_theme_configs() {
    print_step $((++CURRENT_STEP)) "${TOTAL_STEPS}" "Applying Theme Configurations"
    echo ""

    local theme="${THEME}"
    local variant="${THEME_VARIANT:-default}"

    # Apply theme to GTK apps (for proot apps)
    configure_gtk_theme

    # Apply theme to Qt apps (for KDE)
    configure_qt_theme

    # Create theme switcher script
    create_theme_switcher

    # Apply theme to shell
    configure_shell_theme

    log_success "Theme '${theme}' (${variant}) applied"
}

configure_gtk_theme() {
    execute mkdir -p "${HOME}/.config/gtk-3.0"
    execute mkdir -p "${HOME}/.config/gtk-4.0"

    local theme_colors
    theme_colors=$(theme_get "${THEME}" "${variant}")
    eval "${theme_colors}"

    local bg="${BASE16_BASE00}"
    local fg="${BASE16_BASE05}"
    local sel_bg="${BASE16_BASE0D}"
    local sel_fg="${BASE16_BASE00}"
    local toolbar_bg="${BASE16_BASE01}"
    local button_bg="${BASE16_BASE02}"
    local button_fg="${BASE16_BASE05}"

    # GTK 3 settings.ini
    execute cat > "${HOME}/.config/gtk-3.0/settings.ini" << GTK3EOF
[Settings]
gtk-theme-name = ${THEME}-${variant}
gtk-icon-theme-name = Papirus-Dark
gtk-font-name = Noto Sans 11
gtk-cursor-theme-name = Adwaita
gtk-cursor-theme-size = 24
gtk-toolbar-style = GTK_TOOLBAR_BOTH
gtk-toolbar-icon-size = GTK_ICON_SIZE_LARGE_TOOLBAR
gtk-button-images = 1
gtk-menu-images = 1
gtk-enable-event-sounds = 1
gtk-enable-input-feedback-sounds = 1
gtk-xft-antialias = 1
gtk-xft-hinting = 1
gtk-xft-hintstyle = hintslight
gtk-xft-rgba = rgb
gtk-application-prefer-dark-theme = 1
GTK3EOF

    # GTK 3 colors.css
    execute cat > "${HOME}/.config/gtk-3.0/colors.css" << GTK3CSSEOF
@define-color bg_color ${bg};
@define-color fg_color ${fg};
@define-color base_color ${BASE16_BASE01};
@define-color text_color ${fg};
@define-color selected_bg_color ${sel_bg};
@define-color selected_fg_color ${sel_fg};
@define-color tooltip_bg_color ${BASE16_BASE01};
@define-color tooltip_fg_color ${fg};
@define-color toolbar_bg_color ${toolbar_bg};
@define-color toolbar_fg_color ${fg};
@define-color button_bg_color ${button_bg};
@define-color button_fg_color ${button_fg};
@define-color link_color ${BASE16_BASE0D};
@define-color success_color ${BASE16_BASE0B};
@define-color warning_color ${BASE16_BASE0A};
@define-color error_color ${BASE16_BASE08};
GTK3CSSEOF

    # GTK 4 settings.ini (similar to GTK 3)
    execute cp "${HOME}/.config/gtk-3.0/settings.ini" "${HOME}/.config/gtk-4.0/settings.ini"
    execute cp "${HOME}/.config/gtk-3.0/colors.css" "${HOME}/.config/gtk-4.0/colors.css"

    # Also create gtk.css for GTK 4
    execute cat > "${HOME}/.config/gtk-4.0/gtk.css" << GTK4CSSEOF
@import "colors.css";

* {
    background-color: @bg_color;
    color: @fg_color;
}

button {
    background-color: @button_bg_color;
    color: @button_fg_color;
    border: 1px solid @base_color;
    border-radius: 4px;
    padding: 6px 12px;
}

button:hover {
    background-color: @selected_bg_color;
    color: @selected_fg_color;
}

entry, spinbutton, combobox {
    background-color: @base_color;
    color: @text_color;
    border: 1px solid @base_color;
    border-radius: 4px;
}

entry:focus, spinbutton:focus, combobox:focus {
    border-color: @selected_bg_color;
}

scrollbar {
    background-color: @bg_color;
}

scrollbar slider {
    background-color: @button_bg_color;
    border-radius: 4px;
    min-width: 8px;
    min-height: 8px;
}

scrollbar slider:hover {
    background-color: @selected_bg_color;
}
GTK4CSSEOF
}

configure_qt_theme() {
    execute mkdir -p "${HOME}/.config/qt6ct"
    execute mkdir -p "${HOME}/.config/qt5ct"

    local theme_colors
    theme_colors=$(theme_get "${THEME}" "${variant}")
    eval "${theme_colors}"

    local bg="${BASE16_BASE00}"
    local fg="${BASE16_BASE05}"
    local sel_bg="${BASE16_BASE0D}"
    local sel_fg="${BASE16_BASE00}"
    local window_bg="${BASE16_BASE01}"
    local button_bg="${BASE16_BASE02}"

    # Qt6ct config
    execute cat > "${HOME}/.config/qt6ct/qt6ct.conf" << QT6EOF
[Appearance]
style=fusion
color_scheme_path=${HOME}/.config/qt6ct/colorscheme.conf
icon_theme=Papirus-Dark
font=Noto Sans,11,-1,5,50,0,0,0,0,0
standard_dialogs=gtk3

[Interface]
activate_item_on_single_click=1
dialog_buttons_have_icons=1
double_click_interval=400
cursor_flash_time=1000
wheel_scroll_lines=3
gtk3_icons=1
show_shortcuts_in_context_menus=1
menus_have_icons=1

[Fonts]
general=Noto Sans,11,-1,5,50,0,0,0,0,0
fixed=JetBrains Mono Nerd Font,11,-1,5,50,0,0,0,0,0

[Toolbar]
toolButtonStyle=2
otherToolBars=1
mainToolBars=1
QT6EOF

    # Qt6ct colorscheme
    execute cat > "${HOME}/.config/qt6ct/colorscheme.conf" << QT6COLORSEOF
[ColorScheme]
window=${bg}
windowText=${fg}
base=${window_bg}
alternateBase=${BASE16_BASE02}
toolTipBase=${BASE16_BASE01}
toolTipText=${fg}
text=${fg}
button=${button_bg}
buttonText=${fg}
brightText=${BASE16_BASE08}
link=${BASE16_BASE0D}
highlight=${sel_bg}
highlightedText=${sel_fg}

[ColorScheme:Inactive]
window=${BASE16_BASE01}
windowText=${BASE16_BASE04}
base=${BASE16_BASE01}
alternateBase=${BASE16_BASE02}
toolTipBase=${BASE16_BASE01}
toolTipText=${fg}
text=${BASE16_BASE04}
button=${BASE16_BASE02}
buttonText=${BASE16_BASE04}
brightText=${BASE16_BASE08}
link=${BASE16_BASE0D}
highlight=${BASE16_BASE03}
highlightedText=${fg}

[ColorScheme:Disabled]
window=${BASE16_BASE01}
windowText=${BASE16_BASE03}
base=${BASE16_BASE01}
alternateBase=${BASE16_BASE01}
toolTipBase=${BASE16_BASE01}
toolTipText=${BASE16_BASE03}
text=${BASE16_BASE03}
button=${BASE16_BASE01}
buttonText=${BASE16_BASE03}
brightText=${BASE16_BASE08}
link=${BASE16_BASE0D}
highlight=${BASE16_BASE03}
highlightedText=${BASE16_BASE03}
QT6COLORSEOF

    # Qt5ct config (copy Qt6ct)
    execute cp "${HOME}/.config/qt6ct/qt6ct.conf" "${HOME}/.config/qt5ct/qt5ct.conf"
    execute cp "${HOME}/.config/qt6ct/colorscheme.conf" "${HOME}/.config/qt5ct/colorscheme.conf"

    # Set environment variables for Qt
    execute cat > "${HOME}/.config/qt-environment.sh" << QTENVEOF
#!/data/data/com.termux/files/usr/bin/bash
# Qt Theme Environment - source this file

export QT_QPA_PLATFORMTHEME=qt6ct
export QT_STYLE_OVERRIDE=fusion
export QT_QPA_PLATFORM=wayland
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
export QT_AUTO_SCREEN_SCALE_FACTOR=1
export QT_ENABLE_HIGHDPI_SCALING=1
QTENVEOF
    execute chmod +x "${HOME}/.config/qt-environment.sh"
}

configure_shell_theme() {
    # Starship prompt configuration
    execute mkdir -p "${HOME}/.config"

    execute cat > "${HOME}/.config/starship.toml" << STARSHIPEOF
# Starship configuration - Auto-generated by termux-wayland-installer
# Theme: ${THEME}-${variant}

format = """
\$username\
\$hostname\
\$directory\
\$git_branch\
\$git_status\
\$package\
\$nodejs\
\$rust\
\$python\
\$golang\
\$docker_context\
\$cmd_duration\
\$line_break\
\$character"""

[username]
style_user = "${BASE16_BASE0E}"
style_root = "${BASE16_BASE08}"
format = "[\$user](\$style) "
disabled = false
show_always = true

[hostname]
ssh_only = false
format = "@[\$hostname](bold ${BASE16_BASE0C}) "
disabled = false

[directory]
style = "${BASE16_BASE0D}"
format = "[\$path](\$style) "
truncation_length = 3
truncation_symbol = "…/"

[git_branch]
symbol = " "
style = "${BASE16_BASE0A}"
format = "[\$symbol\$branch](\$style) "

[git_status]
style = "${BASE16_BASE08}"
format = '([\$all_status_branches\$all_status](\$style)) '
conflicted = "="
ahead = "↑"
behind = "↓"
diverged = "↕"
untracked = "?"
stashed = "\$"
modified = "!"
deleted = "×"

[package]
symbol = " "
style = "${BASE16_BASE0C}"
format = "[\$symbol\$version](\$style) "

[nodejs]
symbol = " "
style = "${BASE16_BASE0B}"
format = "via [\$symbol\$version](\$style) "

[rust]
symbol = " "
style = "${BASE16_BASE08}"
format = "via [\$symbol\$version](\$style) "

[python]
symbol = " "
style = "${BASE16_BASE0D}"
format = "via [\$symbol\$version](\$style) "
pyenv_version_name = true

[golang]
symbol = " "
style = "${BASE16_BASE0C}"
format = "via [\$symbol\$version](\$style) "

[docker_context]
symbol = " "
style = "${BASE16_BASE0D}"
format = "via [\$symbol\$context](\$style) "

[cmd_duration]
min_time = 2000
format = "took [\$duration](bold ${BASE16_BASE0A}) "
style = "${BASE16_BASE0A}"

[line_break]
disabled = false

[character]
success_symbol = "[❯](bold ${BASE16_BASE0B})"
error_symbol = "[❯](bold ${BASE16_BASE08})"
vicmd_symbol = "[❮](bold ${BASE16_BASE0E})"
STARSHIPEOF

    # Add starship to bashrc if not present
    if ! grep -q "starship init bash" "${HOME}/.bashrc" 2>/dev/null; then
        echo 'eval "$(starship init bash)"' >> "${HOME}/.bashrc"
    fi

    # Also add to .zshrc if zsh is used
    if [[ -f "${HOME}/.zshrc" ]] && ! grep -q "starship init zsh" "${HOME}/.zshrc" 2>/dev/null; then
        echo 'eval "$(starship init zsh)"' >> "${HOME}/.zshrc"
    fi
}

create_theme_switcher() {
    execute cat > "${HOME}/.local/bin/theme-switch" << 'THEMESWITCHEOF'
#!/data/data/com.termux/files/usr/bin/bash
# Theme Switcher for termux-wayland-installer
# Usage: theme-switch [theme] [variant]

CONFIG_DIR="${HOME}/.config/termux-wayland-installer"
THEMES_DIR="${CONFIG_DIR}/themes"
CURRENT_CONFIG="${CONFIG_DIR}/current-theme"

AVAILABLE_THEMES=("catppuccin" "everforest" "tokyonight" "dracula" "nord" "rose-pine" "gruvbox")

show_usage() {
    echo "Usage: theme-switch [theme] [variant]"
    echo ""
    echo "Available themes:"
    for theme in "${AVAILABLE_THEMES[@]}"; do
        echo "  $theme"
    done
    echo ""
    echo "Variants (theme-dependent):"
    echo "  catppuccin: latte, frappe, macchiato, mocha"
    echo "  everforest: light, dark"
    echo "  tokyonight: storm, night, day, moon"
    echo "  dracula: default"
    echo "  nord: default"
    echo "  rose-pine: dawn, moon, main"
    echo "  gruvbox: light, dark, material"
    echo ""
    echo "Current theme: $(cat "${CURRENT_CONFIG}" 2>/dev/null || echo "not set")"
}

if [[ $# -eq 0 ]] || [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    show_usage
    exit 0
fi

THEME="$1"
VARIANT="${2:-default}"

# Validate theme
VALID=0
for t in "${AVAILABLE_THEMES[@]}"; do
    if [[ "$t" == "$THEME" ]]; then
        VALID=1
        break
    fi
done

if [[ $VALID -eq 0 ]]; then
    echo "Error: Unknown theme '$THEME'"
    show_usage
    exit 1
fi

# Save current theme
mkdir -p "${CONFIG_DIR}"
echo "${THEME} ${VARIANT}" > "${CURRENT_CONFIG}"

# Re-run theme configuration
exec "${HOME}/termux-wayland-installer" --theme "${THEME}" --variant "${VARIANT}" --update
THEMESWITCHEOF
    execute chmod +x "${HOME}/.local/bin/theme-switch"

    log_success "Theme switcher created at ~/.local/bin/theme-switch"
}

export -f step_theme_configs configure_gtk_theme configure_qt_theme configure_shell_theme create_theme_switcher