# WillWitcher OS (NixOS + Home Manager)

> **Personal NixOS configuration** with Hyprland on Wayland, themed by **Stylix**, and a curated Home Manager module set (Waybar, Wofi, Firefox, Zathura, Tmux, Vesktop, Starship, and more).  
> Target host: **`ww-desktop`**.

---

## Repo Layout

```
.
├── flake.lock
├── flake.nix
├── hosts
│   └── desktop
│       ├── configuration.nix
│       ├── hardware-configuration.nix
│       └── home.nix
├── modules
│   └── home-manager
│       ├── btop.nix
│       ├── firefox.nix
│       ├── fzf.nix
│       ├── hyprland.nix
│       ├── kitty.nix
│       ├── nvf-willwitcher.nix
│       ├── nvim.nix
│       ├── starship.nix
│       ├── swaync.nix
│       ├── tmux.nix
│       ├── vesktop.nix
│       ├── waybar.nix
│       ├── wofi.nix
│       ├── zathura.nix
│       └── zed.nix
├── themes/           # Base16 YAML schemes for Stylix
└── wallpapers/
    ├── images/      # static wallpapers (e.g. cat.png)
    └── live/        # video wallpapers
```

> **Note:** Only some modules are documented below (those with context files). The others exist in the tree and follow the same “Stylix owns the palette” philosophy.

---

## Quick Start

1. **Install NixOS** and ensure your machine has a valid `hardware-configuration.nix` under `hosts/desktop/`.
2. **Clone** this repo and review `hosts/desktop/configuration.nix` + `home.nix`.
3. Make sure your `flake.nix` includes inputs for **home-manager** and **stylix** (this repo expects them).
4. Switch to this configuration (target host is `ww-desktop`):
   ```bash
   sudo nixos-rebuild switch --flake .#ww-desktop
   ```

### Daily tips

- Update inputs: `nix flake update`
- Check errors: `journalctl -b -p err..alert -g nixos`
- Roll back: pick a previous **generation** from the boot menu or `sudo nixos-rebuild --rollback`

---

## System Configuration (host: `ww-desktop`)

Defined in **`hosts/desktop/configuration.nix`**.

- **Boot**: `systemd-boot` + EFI write enabled
- **Kernel**: latest `linuxPackages_latest`
- **Locale/Time**: `en_US.UTF-8`, `America/Los_Angeles`
- **Networking**: NetworkManager
- **Keyboard (X11/Xwayland)**: `us`
- **Theming (Stylix, system scope)**:
  - `autoEnable = true`
  - Wallpaper: `wallpapers/images/cat.png`
  - Base16 scheme: `themes/catppuccin-mocha.yaml`
  - Fonts: Hack Nerd (serif/sans/mono) + Noto Color Emoji
  - Cursor: Catppuccin Mocha Dark (size 32)
- **Display**: `greetd` + `regreet` → **Hyprland** (Wayland) with XWayland
- **Audio**: PipeWire (ALSA + 32-bit + Pulse layer) with WirePlumber
- **XDG Portals**: Hyprland → GNOME → GTK (ordered for Wayland correctness)
- **User**: `willwitcher` (groups: wheel, networkmanager; shell: zsh)
- **Gaming**: Steam hardware + Steam client, GameMode
- **nix-ld**: enabled with `icu` as a runtime library
- **Nix features**: `nix-command` and `flakes`
- **Home Manager**: integrated at system level, loading `hosts/desktop/home.nix`
- **State version**: `25.05`

Rebuild:
```bash
sudo nixos-rebuild switch --flake .#ww-desktop
```

---

## Home Manager (user: `willwitcher`)

Defined in **`hosts/desktop/home.nix`**. It imports and enables the per-app modules under `modules/home-manager/`. Key highlights:

- **Stylix (user targets)**: icons, GTK, and per-app targets (Firefox, Kitty, Hyprland, Hyprpaper, Waybar, Wofi, Zathura, Vesktop, NVF) while **cursor is owned by system scope**.
- **Vesktop**: tray/minimize-to-tray, HW acceleration, branch `stable`.
- **Kitty**: font size forced with `lib.mkForce 16`.
- **Firefox**: profile `willwitcher` enabled + uBlock Origin by policy; set as default browser.
- **Zsh**: completions on; adds `nix-zsh-completions` to `$fpath`; loads `zsh-autosuggestions` + `zsh-fzf-tab`; fzf-tab group switching.
- **GNOME Keyring**: enabled.
- **User packages**: media, Wayland tools, compression suite, CLI utilities, **Rust toolchain**, AI CLI (`gemini-cli`), screen recording (`wl-screenrec`), markdown tools.
- **Assets**: copies repo `wallpapers/{live,images}` into `$HOME/Wallpapers/...` recursively.
- **Session env**: `EDITOR=nvim`

---

## Modules (documented)

### Firefox — `modules/home-manager/firefox.nix`
- Manages a named profile and writes **privacy/UX** prefs to `user.js`.
- Installs extensions **declaratively via Enterprise Policies** using AMO slugs (e.g., uBlock Origin).
- Optional bookmarks management (flat list or advanced HM structure).
- **Stylix**: can enable Firefox Color toolbar + GNOME theme for a GTK-like look.
- Optional: make Firefox the **default browser** (XDG + `DEFAULT_BROWSER`).

Usage example:
```nix
willwitcher.firefox = {
  enable       = true;
  profileName  = "willwitcher";
  makeDefault  = true;
  policyExtensions = [
    { id = "uBlock0@raymondhill.net"; slug = "ublock-origin"; }
  ];
};
```

---

### Waybar — `modules/home-manager/waybar.nix`
- Themed via **Stylix palette** (no Stylix-injected CSS); CSS uses `config.lib.stylix.colors.withHashtag` tokens.
- Ships **`ww-wlrec`** wrapper (bash) that drives `wl-screenrec` and provides a **JSON module** for Waybar:
  - Left click: toggle recording on **focused monitor** (Hyprland integration)
  - Middle click: **region selection** via `slurp`
  - Right click: open recordings folder
  - The module sends `SIGRTMIN+8` to refresh Waybar (`signal = 8`).
- Layout: Workspaces (left), Clock (center), Recorder + Notifications + Pulseaudio + Tray (right).

Environment variables honored by `ww-wlrec` include `WLREC_DIR`, `WLREC_FILENAME`, `WLREC_OUTPUT`, `WLREC_AUDIO`, `WLREC_AUDIO_DEVICE`, `WLREC_CODEC`, `WLREC_MAX_FPS`, `WLREC_BITRATE`.

---

### Wofi — `modules/home-manager/wofi.nix`
- Minimal launcher UI that **keeps colors in Stylix**; CSS uses `c.base**` tokens only.
- Smooth animations (`slideIn` and `fadeIn`), hidden dropdown arrow, highlighted selected entry.
- Case-insensitive search, images enabled, compact default size.

```nix
willwitcher.wofi.enable = true;
```

---

### Zathura — `modules/home-manager/zathura.nix`
- Installs Zathura (assumes backends are bundled in your nixpkgs build).
- Keeps **palette to GTK/Stylix** (no hardcoded colors).
- Options written to `zathurarc`; raw `extraConfig` appended (mappings, tweaks).
- Optional: set as **default PDF viewer** via XDG.

```nix
willwitcher.zathura = {
  enable = true;
  makeDefault = true;
};
```

---

### Starship — `modules/home-manager/starship.nix`
- Clean prompt for Zsh; **Stylix owns colors**.
- Left prompt: directory → git branch/status → package → nix shell → runtimes (node/python/rust/dotnet) → cmd duration → newline → prompt char.
- Right prompt: time (`HH:MM`).
```nix
willwitcher.starship.enable = true;
```

---

### Tmux — `modules/home-manager/tmux.nix`
- Sensible defaults: `tmux-256color`, vi mode, `baseIndex=1`, mouse on, long history, 24h clock.
- Plugins: `sensible`, `yank`, `prefix-highlight`, `resurrect`, `continuum` (+ optional **tmux-which-key** when available).
- Minimal status line (colors by Stylix). Autosave/restore via Continuum; Neovim-friendly Resurrect.

```nix
willwitcher.tmux = {
  enable = true;
  whichKey.enable = true;
  useStylixColors = true;
};
```

---

### Vesktop — `modules/home-manager/vesktop.nix`
- Works whether HM exposes `programs.vesktop` or not:
  - If it does → full declarative config (package, settings, **Vencord** via `useSystem`).
  - If it doesn’t → installs the package as a fallback.
- Optional **Stylix vesktop target** is enabled when present.

```nix
willwitcher.vesktop.enable = true;
```

---

## Themes & Wallpapers

- Base16 schemes live under **`/themes`** — set via Stylix (e.g., `themes/catppuccin-mocha.yaml`).
- Wallpapers live under **`/wallpapers/images`** and **`/wallpapers/live`**.
- System-level Stylix in `configuration.nix` points to:
  - Image: `../../wallpapers/images/cat.png`
  - Scheme: `../../themes/catppuccin-mocha.yaml`

### Changing the theme/wallpaper

Edit `hosts/desktop/configuration.nix`:
```nix
stylix = {
  enable = true;
  autoEnable = true;
  image = ../../wallpapers/images/<your-image>.png;
  base16Scheme = ../../themes/<your-scheme>.yaml;
  polarity = "dark"; # or "light"
};
```

---

## Philosophy & Ownership

- **Stylix owns the palette**. Modules avoid hardcoded hex values and use Stylix color tokens (`c.base**`) whenever CSS is needed.
- **System vs User**: Cursor/theme/wallpaper at **system scope**; app targets and icons usually at **user scope**.
- **Hyprland-first Wayland**: XDG portals prioritize Hyprland for better screencast/portal behavior.

---

## Contributing / Adapting

- Fork and adapt to your host(s). Add a new host under `hosts/<name>/` and reference it via `--flake .#<name>`.
- Prefer adding new apps as modular HM files under `modules/home-manager/` with a small `willwitcher.<app>.enable` toggle.
- Keep colors with Stylix; avoid hardcoding palette values in modules.

---

## License

TBD (personal configuration; choose a license if you intend to share/redistribute as a project template).

---

## Credits

- **NixOS**, **Home Manager**, **Stylix**
- **Hyprland**, **Waybar**, **Wofi**, **Zathura**, **Vesktop**, **Tmux**, **Starship**
- Everyone maintaining the packages and targets used here ❤️
