{ config, lib, pkgs, ... }:
let
  inherit (lib) mkEnableOption mkIf mkOption types optionals optionalString;
  cfg = config.willwitcher.tmux;
  p = pkgs.tmuxPlugins;
  # Helper: try to get tmux-which-key if present in this nixpkgs
  whichKeyPkg = p.tmux-which-key or null;
in
{
  options.willwitcher.tmux = {
    enable = mkEnableOption "Enable tmux with helpful plugins and a clean status line";

    # Stylix should own colors; keep this switch in case you want to experiment later
    useStylixColors = mkOption {
      type = types.bool;
      default = true;
      description = "If true, Stylix manages tmux colors (recommended). If false, you may theme via a plugin.";
    };

    whichKey = {
      enable = mkOption {
        type = types.bool;
        default = true; # you can set to false if your nixpkgs lacks tmux-which-key
        description = "Enable tmux-which-key plugin if available in pkgs.tmuxPlugins.";
      };
    };
  };

  config = mkIf cfg.enable {
    # Let Stylix paint tmux
    stylix.targets.tmux.enable = cfg.useStylixColors;

    programs.tmux = {
      enable = true;
      # terminal/terminfo
      terminal = "tmux-256color"; # fallback works fine; stylix provides colors
      # quality of life
      mouse = true;
      keyMode = "vi";
      baseIndex = 1;
      historyLimit = 100000;
      clock24 = true;

      plugins = [
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

        # Resurrect: better handling for Neovim
        set -g @resurrect-strategy-nvim 'session'

        # Respect XDG layout for which-key if present
        ${optionalString (cfg.whichKey.enable && whichKeyPkg != null) ''
          set -g @tmux-which-key-xdg-enable 1
        ''}

        ##### Status line (no hardcoded colors; Stylix themes it) #####
        set -g status-interval 2
        set -g status-left  " #S "
        set -g status-right " #(date '+%H:%M') "
        set -g window-status-current-format " #I:#W* "
        set -g window-status-format         " #I:#W  "

        ##### QoL binds #####
        bind r source-file ~/.config/tmux/tmux.conf \; display-message "tmux reloaded"
        bind | split-window -h
        bind - split-window -v
        bind z resize-pane -Z

        # Lightweight which-key-like quick menu using built-in display-menu (safe fallback)
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

    # Optional: tmux-which-key YAML skeleton (only if plugin exists + enabled)
    ${optionalString (cfg.whichKey.enable && whichKeyPkg != null) ''
      xdg.configFile."tmux/plugins/tmux-which-key/config.yaml".text = ''
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
    ''}
  };
}

