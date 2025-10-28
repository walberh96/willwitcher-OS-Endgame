{ config, pkgs, lib, ... }:

let
  inherit (lib) mkEnableOption mkIf;
in
{
  options.willwitcher.starship.enable =
    mkEnableOption "Enable WillWitcher Starship prompt (Stylix owns palette)";

  config = mkIf config.willwitcher.starship.enable {
    # Let Home Manager manage Starship and integrate with zsh
    programs.starship = {
      enable = true;
      enableZshIntegration = true;

      # We avoid explicit colors so the terminal theme (Stylix -> Kitty) leads the look.
      settings = {
        #######################################################################
        # Top-level behavior
        #######################################################################
        add_newline = false;         # don't put a blank line between prompts
        scan_timeout = 30;           # ms to scan for VCS / toolchain files

        #######################################################################
        # Layout: simple left prompt + a right-side clock
        #######################################################################
        format = "$directory$git_branch$git_status$package$nix_shell$nodejs$python$rust$dotnet$cmd_duration$line_break$character"
        right_format = "$time"

        #######################################################################
        # Prompt character (kept neutral; no explicit color)
        #######################################################################
        character = {
          success_symbol = "❯";
          error_symbol   = "❯";
          vicmd_symbol   = "❮";
          # No style/color here; terminal theme handles it.
        };

        #######################################################################
        # Directory: short and clean
        #######################################################################
        directory = {
          truncation_length = 3;        # keep 3 segments: ~/…/project/dir
          truncate_to_repo  = false;    # don't reset at repo root
          read_only = " ";
          # No color settings.
        };

        #######################################################################
        # Git modules
        #######################################################################
        git_branch = {
          symbol = " ";
          truncation_length = 20;
          only_attached = false;
        };
        git_status = {
          conflicted = " ";
          ahead      = " ⇡${count}";
          behind     = " ⇣${count}";
          diverged   = " ⇕";
          untracked  = " ";
          stashed    = " ";
          modified   = " ";
          staged     = " ";
          renamed    = " ";
          deleted    = " ";
          format     = "[$all_status$ahead_behind]($style)";
          # Leave $style to defaults; we don't force colors.
        };

        #######################################################################
        # Package/version (shows version if package.json / etc. present)
        #######################################################################
        package = {
          symbol = "📦 ";
          display_private = true;
        };

        #######################################################################
        # Nix shell indicator
        #######################################################################
        nix_shell = {
          symbol = "❄️ ";
          format = "via [$symbol$name]($style) ";
        };

        #######################################################################
        # Runtimes (auto-show when relevant files are present)
        #######################################################################
        nodejs = { format = "via [$symbol$version]($style) "; };
        python = { format = "via [${symbol}${pyenv_prefix}${version}]($style) "; };
        rust   = { format = "via [$symbol$version]($style) "; };
        dotnet = { format = "via [$symbol$version]($style) "; };

        #######################################################################
        # Command duration: show when over 500ms
        #######################################################################
        cmd_duration = {
          min_time = 500;
          format = "[ $duration]($style) ";
        };

        #######################################################################
        # Right prompt: time (style only = bold; no color)
        ##############################################
