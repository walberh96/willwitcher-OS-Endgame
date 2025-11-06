{ config, lib, pkgs, ... }:

let
  inherit (lib) mkEnableOption mkIf mkOption types optionals optionalString;
  cfg = config.willwitcher.tmux;
  p = pkgs.tmuxPlugins;
  whichKeyPkg = p.tmux-which-key or null;
in
{
  options.willwitcher.tmux = {
    enable = mkEnableOption "Enable tmux with helpful plugins and a clean status line";

    useStylixColors = mkOption {
      type = types.bool;
      default = true;
      description = "If true, Stylix manages tmux colors (if your Stylix has that target).";
    };

    whichKey.enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable tmux-which-key if available in pkgs.tmuxPlugins.";
    };
  };

  config = mkIf cfg.enable {
    # OJO: si tu Stylix no tiene target tmux, comenta esta línea.
    stylix.targets.tmux.enable = cfg.useStylixColors;

    programs.tmux = {
      enable = true;                # <-- instala tmux
      terminal = "tmux-256color";
      mouse = true;
      keyMode = "vi";
      baseIndex = 1;
      historyLimit = 100000;
      clock24 = true;

      plugins =
        [
          p.sensible
          p.yank
          p.prefix-highlight
          p.resurrect
          p.continuum
        ]
        ++ (optionals (cfg.whichKey.enable && whichKeyPkg != null) [ whichKeyPkg ]);

      extraConfig = ''
        set -g escape-time 0
        set -g pane-base-index 1
        set -g set-clipboard on

        # Continuum autosave/restore
        set -g @continuum-restore 'on'
        set -g @continuum-save-interval '15'

        # Resurrect: mejor con Neovim
        set -g @resurrect-strategy-nvim 'session'

        ${optionalString (cfg.whichKey.enable && whichKeyPkg != null) ''
          set -g @tmux-which-key-xdg-enable 1
        ''}

        # Status minimal (sin colores hardcode: deja a Stylix)
        set -g status-interval 2
        set -g status-left  " #S "
        set -g status-right " #(date '+%H:%M') "
        set -g window-status-current-format " #I:#W* "
        set -g window-status-format         " #I:#W  "

        # Binds
        bind r source-file ~/.config/tmux/tmux.conf \; display-message "tmux reloaded"
        bind | split-window -h
        bind - split-window -v
        bind z resize-pane -Z

        bind Space display-menu -T "Quick actions" \
          "New window"       c  "new-window" \
          "Rename window"    ,  "command-prompt -I '#W' 'rename-window -- %%'" \
          "Next window"      n  "next-window" \
          "Prev window"      p  "previous-window" \
          "" \
          "Split vertical"   '"' "split-window -v" \
          "Split horizontal" %  "split-window -h" \
          "Kill pane"        x  "kill-pane" \
          "Zoom pane"        z  "resize-pane -Z" \
          "" \
          "Sessions"         s  "choose-tree -Zw" \
          "Reload tmux"      r  "source-file ~/.config/tmux/tmux.conf"
      '';
    };

    # ✅ Condicional bien hecho: a nivel de atributos, no con cadenas sueltas
    xdg.configFile = mkIf (cfg.whichKey.enable && whichKeyPkg != null) {
      "tmux/plugins/tmux-which-key/config.yaml".text = ''
        menu:
          - key: "w"
            name: "Windows"
            items:
              - { key: "c", name: "Create window", command: "new-window" }
              - { key: ",", name: "Rename window", command: "command-prompt -I '#W' 'rename-window -- %%'" }
              - { key: "n", name: "Next window", command: "next-window" }
              - { key: "p", name: "Prev window", command: "previous-window" }
              - { key: "&", name: "Kill window", command: "kill-window" }
          - key: "p"
            name: "Panes"
            items:
              - { key: "\"", name: "Split horizontal", command: "split-window -v" }
              - { key: "%",  name: "Split vertical",   command: "split-window -h" }
              - { key: "x",  name: "Kill pane",        command: "kill-pane" }
              - { key: "z",  name: "Zoom",             command: "resize-pane -Z" }
      '';
    };
  };
}

