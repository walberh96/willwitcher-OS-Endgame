{ config, pkgs, lib, ... }:

let
  inherit (lib) mkEnableOption mkIf;
in
{
  options.willwitcher.starship.enable =
    mkEnableOption "Enable WillWitcher Starship prompt (Stylix owns palette)";

  config = mkIf config.willwitcher.starship.enable {
    programs.starship = {
      enable = true;
      enableZshIntegration = true;

      settings = {
        add_newline = false;
        scan_timeout = 30;

        format = "$directory$git_branch$git_status$package$nix_shell$nodejs$python$rust$dotnet$cmd_duration$line_break$character";
        right_format = "$time";

        character = {
          success_symbol = "❯";
          error_symbol   = "❯";
          vicmd_symbol   = "❮";
        };

        directory = {
          truncation_length = 3;
          truncate_to_repo  = false;
          read_only = " ";
        };

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
        };

        package = {
          symbol = "📦 ";
          display_private = true;
        };

        nix_shell = {
          symbol = "❄️ ";
          format = "via [$symbol$name]($style) ";
        };

        nodejs = { format = "via [$symbol$version]($style) "; };
        python = {
          # Emit literal: ${symbol}${pyenv_prefix}${version}
          format =
            "via ["
            + "$" + "{symbol}"
            + "$" + "{pyenv_prefix}"
            + "$" + "{version}"
            + "]($style) ";
        };
        rust   = { format = "via [$symbol$version]($style) "; };
        dotnet = { format = "via [$symbol$version]($style) "; };

        cmd_duration = {
          min_time = 500;
          format = "[ $duration]($style) ";
        };

        time = {
          disabled = false;
          format = "[$time]($style)";
          time_format = "%H:%M";
          use_12hr = false;
          style = "bold";
        };

        sudo = { disabled = false; format = "[sudo]($style) "; };
        jobs = { disabled = false; symbol = " "; };
      };
    };
  };
}
