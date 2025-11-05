# Project Overview

This repository contains the NixOS configuration for a desktop system. It uses the experimental flakes feature of Nix to manage the system configuration in a declarative and reproducible way.

The configuration is based on `nixpkgs-unstable` and uses `home-manager` to manage the user's environment. The window manager is `hyprland`, a dynamic tiling Wayland compositor. The overall theme is managed by `stylix`, with the `catppuccin-mocha` theme being used.

## Key Technologies

*   **NixOS:** A Linux distribution that uses a declarative model for system configuration.
*   **Nix Flakes:** An experimental feature of Nix that improves reproducibility and composability.
*   **Home Manager:** A tool to manage a user's environment declaratively.
*   **Hyprland:** A dynamic tiling Wayland compositor.
*   **Stylix:** A theming framework for NixOS.

# Building and Running

To build and apply the configuration, you can use the following command from the root of the repository:

```bash
sudo nixos-rebuild switch --flake .#desktop
```

This will build the system configuration for the `desktop` host and switch to it.

# Development Conventions

The configuration is structured as follows:

*   `flake.nix`: The main entry point for the NixOS configuration. It defines the inputs (e.g., `nixpkgs`, `home-manager`) and the outputs (the NixOS configurations).
*   `hosts/`: Contains the configurations for each host.
    *   `desktop/`: The configuration for the `desktop` host.
        *   `configuration.nix`: The main system-level configuration for the host.
        *   `home.nix`: The user-level configuration for the host, managed by `home-manager`.
*   `modules/`: Contains custom NixOS and home-manager modules.
*   `themes/`: Contains the `stylix` theme files.
*   `wallpapers/`: Contains the wallpaper images.

The user's packages are defined in `hosts/desktop/home.nix` in the `home.packages` attribute.
