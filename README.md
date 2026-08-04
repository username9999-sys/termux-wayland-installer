# termux-wayland-installer

> Modular bash installer for **Hyprland/KDE Wayland** on **Termux** with **proot-distro** (Ubuntu/Arch).

Run a full Wayland desktop (Hyprland or KDE Plasma) on Android via Termux — no root required.

## ✨ Features

| Category | Modules |
|----------|---------|
| **Base System** | System update, repositories, proot-distro setup |
| **Wayland Core** | Wayland protocols, compositor dependencies |
| **Desktop Environments** | Hyprland (tiling), KDE Plasma (floating) |
| **UI Tools** | Waybar, Rofi, SwayNC, Kitty, foot |
| **GPU/Acceleration** | VirGL, Mesa, Vulkan, OpenGL ES |
| **Audio** | PipeWire, WirePlumber, PulseAudio compat |
| **Fonts** | Noto, JetBrains Mono, CJK, emoji support |
| **Dev Tools** | Git, Neovim, VS Code Server, Docker, Node.js, Rust, Go |
| **Input Method** | fcitx5 (Chinese/Japanese/Korean), ibus |
| **Game Dev** | Godot 4, GDScript LSP, VS Code extensions |
| **Launchers/Configs** | Desktop entries, autostart, shortcuts |
| **Theming** | Catppuccin, GTK/QT themes, cursor, icons |
| **Remote Access** | VNC (TigerVNC), SSH server, health checks |
| **Tablet Support** | Wacom, stylus, touch calibration |

## 📋 Requirements

- **Android 10+** (API 29+)
- **Termux** (from F-Droid/GitHub, NOT Play Store)
- **Termux:X11** or **Termux:Wayland** app
- **Storage permission** for Termux (`termux-setup-storage`)
- **~2-4 GB free space** (depends on modules selected)
- **proot-distro** (auto-installed)

## 🚀 Quick Start

```bash
# 1. Install Termux (F-Droid) + Termux:X11
# 2. Run in Termux:
pkg update && pkg install -y git proot-distro

# 3. Clone & run
git clone https://github.com/username9999-sys/termux-wayland-installer.git
cd termux-wayland-installer
chmod +x install.sh

# 4. Interactive install (choose Hyprland or KDE)
./install.sh

# 5. Start Wayland session
# Option A: Termux:X11 app → start session
# Option B: termux-x11 :1 -ac & (from Termux)
```

## ⚙️ Configuration

Edit `config/install.yaml` before running:

```yaml
# Desktop environment: hyprland | kde | both
desktop: hyprland

# Distro for proot: ubuntu | arch | debian | alpine
distro: ubuntu
distro_version: jammy  # or noble, bookworm, etc.

# Modules to install (comma-separated, or "all")
modules: "all"

# GPU acceleration
gpu:
  virgl: true
  vulkan: true

# Audio
audio:
  pipewire: true

# Input method
input_method: fcitx5  # fcitx5 | ibus | none

# Remote access
vnc:
  enabled: true
  port: 5901
  password: ""  # auto-generated if empty

# Theming
theme: catppuccin-mocha
```

## 📁 Project Structure

```
termux-wayland-installer/
├── install.sh              # Main entry point
├── config/
│   └── install.yaml        # Configuration file
├── lib/                    # Shared libraries
│   ├── common.sh           # Logging, utils, helpers
│   ├── themes.sh           # Theme application
│   └── yaml.sh             # YAML parser (bash-native)
├── modules/                # Install modules (numbered = order)
│   ├── 01-system-update.sh
│   ├── 02-repositories.sh
│   ├── 03-wayland-core.sh
│   ├── 04-hyprland.sh
│   ├── 04-kde.sh
│   ├── 05-ui-tools.sh
│   ├── 06-gpu.sh
│   ├── 07-audio.sh
│   ├── 08-fonts.sh
│   ├── 09-devtools.sh
│   ├── 09-input-method.sh
│   ├── 10-gamedev.sh
│   ├── 11-proot.sh
│   ├── 12-launchers-configs.sh
│   ├── 13-theme-configs.sh
│   ├── 14-shortcuts.sh
│   ├── 15-vnc.sh
│   ├── 16-finalize.sh
│   ├── 17-health-checks.sh
│   ├── 18-autostart.sh
│   ├── 19-wallpaper.sh
│   ├── 20-ssh-setup.sh
│   └── 21-tablet-support.sh
├── patches/                # Version pins, patches
├── scripts/                # Helper scripts
└── health/                 # Health check scripts
```

## 🎮 Game Dev Stack

After install, you get a ready-to-code environment:

| Tool | Version | Notes |
|------|---------|-------|
| **Godot** | 4.3+ | Via Flatpak in proot |
| **GDScript LSP** | `godot-mcp` / `gopeak` | VS Code extension |
| **VS Code Server** | Latest | Port 8080, pass: `freecc` |
| **free-claude-code** | Latest | Port 8082, AI coding agent |
| **Hermes Agent** | Local | CLI AI assistant |
| **Node.js** | 20 LTS | npm, pnpm, bun |
| **Rust** | Stable | cargo, rust-analyzer |

## 🔧 Module System

Each module is independent and idempotent:

```bash
# Run single module
./install.sh --module 04-hyprland

# Skip modules
./install.sh --skip 10-gamedev,15-vnc

# Dry run (show what would run)
./install.sh --dry-run

# Verbose output
./install.sh -v
```

## 🖼️ Screenshots

<!-- Add screenshots here -->
| Hyprland | KDE Plasma |
|----------|------------|
| ![Hyprland](docs/screenshots/hyprland.png) | ![KDE](docs/screenshots/kde.png) |

## 📖 Documentation

- [Configuration Guide](docs/config.md)
- [Module Reference](docs/modules.md)
- [Troubleshooting](docs/troubleshooting.md)
- [Custom Modules](docs/custom-modules.md)
- [Updating](docs/updating.md)

## 🤝 Contributing

1. Fork the repo
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'feat: add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Code Style

- Shell scripts: `shellcheck` clean, POSIX-compatible where possible
- Use functions, avoid global state
- Document module dependencies in header comments

## 📄 License

MIT License — see [LICENSE](LICENSE) for details.

## 🙏 Acknowledgments

- [Termux](https://termux.dev/) — Linux environment on Android
- [proot-distro](https://github.com/termux/proot-distro) — Distro containers without root
- [Hyprland](https://hyprland.org/) — Dynamic tiling Wayland compositor
- [KDE Plasma](https://kde.org/plasma-desktop/) — Feature-rich desktop environment
- [Catppuccin](https://github.com/catppuccin/catppuccin) — Soothing pastel theme

## 💬 Support

- **Issues**: [GitHub Issues](https://github.com/username9999-sys/termux-wayland-installer/issues)
- **Discussions**: [GitHub Discussions](https://github.com/username9999-sys/termux-wayland-installer/discussions)
- **Termux Community**: [r/termux](https://reddit.com/r/termux), [Termux Discord](https://discord.gg/termux)

---

**Made with ❤️ for the Termux community**
