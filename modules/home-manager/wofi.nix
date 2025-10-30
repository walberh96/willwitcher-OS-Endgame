{ config, pkgs, lib, ... }:

let
  inherit (lib) mkEnableOption mkIf mkForce;
  # Paleta Stylix con '#RRGGBB'
  c = config.lib.stylix.colors.withHashtag;
in
{
  options.willwitcher.wofi.enable =
    mkEnableOption "Enable WillWitcher Wofi config (Stylix owns palette)";

  config = mkIf config.willwitcher.wofi.enable {
    # Activa el target de Wofi en Stylix (sin addCss)
    stylix.targets.wofi.enable = true;

    programs.wofi = {
      enable = true;
      package = pkgs.wofi;

      # Config básica sin colores
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

      # Tu CSS, usando la paleta Stylix (sin hex fijos)
      style = mkForce ''
        /* Deja que Stylix ponga font-family; aquí sólo tamaño si quieres */
        * { font-size: 14px; }

        /* Ventana */
        window {
          margin: 0px;
          padding: 10px;
          border: 0.16em solid ${c.base08};   /* acento (rojo/alerta) */
          border-radius: 10px;
          background-color: ${c.base00};      /* fondo */
          animation: slideIn 0.25s ease-out both;
        }

        /* Slide In */
        @keyframes slideIn {
          from { opacity: 0; transform: translateY(-4px); }
          to   { opacity: 1; transform: translateY(0); }
        }

        /* Contenedores */
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
          color: ${c.base05};                 /* texto */
          background-color: ${c.base00};
          outline: 2px solid ${c.base0E};     /* acento (magenta/morado) */
        }
        #input image {
          border: none;
          color: ${c.base08};                 /* icono del input */
        }

        /* Texto */
        #text {
          margin: 5px;
          border: none;
          color: ${c.base05};
        }

        /* Flechita desplegable (ocúltala por completo) */
        #entry arrow {
          opacity: 0; min-width: 0; margin: 0;
        }

        /* Entrada seleccionada */
        #entry:selected {
          border: 0.11em solid ${c.base0D};   /* acento (azul) */
          background: ${c.base01};            /* contraste leve */
        }
        #entry:selected #text {
          color: ${c.base0E};                 /* texto acentuado */
        }

        /* Drag & drop activo (opcional) */
        #entry:drop(active) {
          background-color: ${c.base0D};
          color: ${c.base00};
        }
      '';
    };
  };
}
