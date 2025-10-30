{ config, lib, pkgs, ... }:

# fzf (Home Manager) — WillWitcherOS style
#
# What this module does:
# - Habilita y configura fzf vía Home Manager.
# - Integra con Zsh/Fish/Bash (toggle por shell).
# - Define FZF_DEFAULT_COMMAND/OPTS y los widgets (CTRL-T, ALT-C, CTRL-R).
# - (Opcional) Instala deps CLI útiles (fd, ripgrep, bat, tree, ripgrep-all).
# - No fuerza colores/tema; lo deja a tu terminal/tema global (Stylix/GTK).
#
# How to enable in your home.nix:
#   imports = [ (inputs.self + /modules/home-manager/fzf.nix) ];
#   willwitcher.fzf.enable = true;
#
# Optional knobs:
#   willwitcher.fzf.enableZsh  = true;   # integra en Zsh
#   willwitcher.fzf.enableFish = true;   # integra en Fish
#   willwitcher.fzf.enableBash = false;  # integra en Bash
#   willwitcher.fzf.addCliDeps = true;   # instala fd, ripgrep, bat, tree, rga
#   willwitcher.fzf.defaultCommand  = "fd --type f ...";
#   willwitcher.fzf.defaultOptions  = [ "--height 40%" "--layout=reverse" ... ];
#   willwitcher.fzf.fileWidgetCommand        = "fd --type f ...";
#   willwitcher.fzf.fileWidgetOptions        = [ "--preview 'bat … {} | head -500'" ];
#   willwitcher.fzf.changeDirWidgetCommand   = "fd --type d ...";
#   willwitcher.fzf.changeDirWidgetOptions   = [ "--select-1" "--exit-0" ];
#   willwitcher.fzf.historyWidgetOptions     = [ "--sort" "--exact" ];
#   willwitcher.fzf.extraEnv = { FZF_COMPLETION_TRIGGER = "**"; };
#
# Notas:
# - Los “widgets” corresponden a atajos por defecto de fzf:
#     CTRL-T → buscador de archivos
#     ALT-C  → cambio de dir
#     CTRL-R → historial del shell
# - Evitamos setear --color para no pelear con tu tema/terminal.

let
  inherit (lib) mkEnableOption mkIf mkOption types;
  cfg = config.willwitcher.fzf;
in
{
  options.willwitcher.fzf = {
    enable = mkEnableOption "Enable fzf (managed by Home Manager).";

    # ¿Instalar herramientas CLI que potencian fzf?
    addCliDeps = mkOption {
      type = types.bool;
      default = true;
      description = "Install fd, ripgrep, bat, tree, ripgrep-all to power fzf commands/previews.";
    };

    # Integración por shell
    enableZsh = mkOption {
      type = types.bool;
      default = true;
      description = "Enable Zsh integration (keybindings + completion).";
    };
    enableFish = mkOption {
      type = types.bool;
      default = false;
      description = "Enable Fish integration (keybindings + completion).";
    };
    enableBash = mkOption {
      type = types.bool;
      default = false;
      description = "Enable Bash integration (keybindings + completion).";
    };

    # Comando base para poblar fzf (FZF_DEFAULT_COMMAND)
    defaultCommand = mkOption {
      type = types.str;
      default = "fd --type f --hidden --follow --exclude .git";
      description = "Command used to list candidates by default (FZF_DEFAULT_COMMAND).";
    };

    # Opciones globales de fzf (FZF_DEFAULT_OPTS)
    defaultOptions = mkOption {
      type = types.listOf types.str;
      default = [
        "--height 40%"
        "--layout=reverse"
        "--border"
        "--info=inline"
      ];
      description = "List of options appended to FZF_DEFAULT_OPTS.";
    };

    # Widgets (CTRL-T / ALT-C / CTRL-R)
    fileWidgetCommand = mkOption {
      type = types.str;
      default = "fd --type f --hidden --follow --exclude .git";
      description = "Command for the file widget (CTRL-T).";
    };
    fileWidgetOptions = mkOption {
      type = types.listOf types.str;
      default = [
        "--preview 'bat --style=numbers --color=always {} | head -500'"
      ];
      description = "Extra options for the file widget (FZF_CTRL_T_OPTS).";
    };

    changeDirWidgetCommand = mkOption {
      type = types.str;
      default = "fd --type d --hidden --follow --exclude .git";
      description = "Command for the change-dir widget (ALT-C).";
    };
    changeDirWidgetOptions = mkOption {
      type = types.listOf types.str;
      default = [
        "--select-1"
        "--exit-0"
      ];
      description = "Extra options for the change-dir widget (FZF_ALT_C_OPTS).";
    };

    historyWidgetOptions = mkOption {
      type = types.listOf types.str;
      default = [
        "--sort"
        "--exact"
      ];
      description = "Extra options for the history widget (FZF_CTRL_R_OPTS).";
    };

    # Env extra por si quieres tunear algún detalle puntual
    extraEnv = mkOption {
      type = types.attrsOf types.str;
      default = {};
      description = "Additional environment variables to export alongside FZF_* ones.";
    };
  };

  config = mkIf cfg.enable {
    # Paquetes auxiliares (opcionales pero recomendados para los defaults)
    home.packages = lib.optionals cfg.addCliDeps [
      pkgs.fd
      pkgs.ripgrep
      pkgs.bat
      pkgs.tree
      pkgs.ripgrep-all
    ];

    # Configuración nativa de Home Manager para fzf
    programs.fzf = {
      enable = true;

      enableZshIntegration = cfg.enableZsh;
      enableFishIntegration = cfg.enableFish;
      enableBashIntegration = cfg.enableBash;

      defaultCommand = cfg.defaultCommand;
      defaultOptions = cfg.defaultOptions;

      fileWidgetCommand = cfg.fileWidgetCommand;
      fileWidgetOptions = cfg.fileWidgetOptions;

      changeDirWidgetCommand = cfg.changeDirWidgetCommand;
      changeDirWidgetOptions = cfg.changeDirWidgetOptions;

      historyWidgetOptions = cfg.historyWidgetOptions;
    };

    # Env extra (por si quieres tocar triggers/completions, etc.)
    home.sessionVariables = cfg.extraEnv;
  };
}
