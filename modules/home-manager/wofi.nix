{ config, pkgs, lib, ... }:

let
  inherit (lib) mkEnableOption mkIf mkForce;
  # Stylix palette with '#RRGGBB'
  c = config.lib.stylix.colors.withHashtag;
in
{
  ################################################################################
  # OPTION
  ################################################################################
  options.willwitcher.wofi.enable =
    mkEnableOption "Enable WillWitcher Wofi config (Stylix owns palette)";

  ################################################################################
  # CONFIG
  ################################################################################
  config = mkIf config.willwitcher.wofi.enable {
    # Enable Stylix target for Wofi (no addCss toggle here; palette is owned by Stylix)
    stylix.targets.wofi.enable = true;

    programs.wofi = {
      enable = true;
      package = pkgs.wofi;

      # Basic config without hardcoded colors
      settings = {
        insensitive   = true;
        width         = 500;
        height        = 300;
        prompt        = "Search...";
        allow_images  = true;
        image_size    = 24;
        dynamic_lines = true;
        allow_markup  = true;
        no_actions    = true;
      };

      # Your CSS using the Stylix palette (no fixed hex values)
      style = mkForce ''
        /* Let Stylix set the font-family; optionally keep size here */
        * { font-size: 14px; }

        /* Window */
        window {
          margin: 0px;
          padding: 10px;
          border: 0.16em solid ${c.base0D};   /* accent */
          border-radius: 10px;
          background-color: ${c.base00};      /* background */
          animation: slideIn 0.25s ease-out both;
        }

        /* Slide In */
        @keyframes slideIn {
          from { opacity: 0; transform: translateY(-4px); }
          to   { opacity: 1; transform: translateY(0); }
        }

        /* Containers */
        #outer-box, #inner-box, #scroll, #entry {
          margin: 5px;
          padding: 10px;
          border: none;
          background-color: ${c.base00};
        }

        /* Fade In */
        #inner-box, #text {
          animation: fadeIn 0.2s ease-out both;
        }
        @keyframes fadeIn {
          from { opacity: 0; }
          to   { opacity: 1; }
        }

        /* Input */
        #input {
          margin: 5px 20px;
          padding: 10px;
          border: none;
          border-radius: 0.2em;
          color: ${c.base05};                 /* text */
          background-color: ${c.base00};
          outline: 2px solid ${c.base0E};     /* accent */
        }
        #input image {
          border: none;
          color: ${c.base08};                 /* input icon */
        }

        /* Text */
        #text {
          margin: 5px;
          border: none;
          color: ${c.base05};
        }

        /* Drop arrow — fully hidden */
        #entry arrow {
          opacity: 0; min-width: 0; margin: 0;
        }

        /* Selected entry */
        #entry:selected {
          border: 0.11em solid ${c.base0D};   /* accent */
          background: ${c.base01};            /* subtle contrast */
        }
        #entry:selected #text {
          color: ${c.base0E};                 /* emphasized text */
        }

        /* Drag & drop active (optional) */
        #entry:drop(active) {
          background-color: ${c.base0D};
          color: ${c.base00};
        }
      '';
    };
  };
}

