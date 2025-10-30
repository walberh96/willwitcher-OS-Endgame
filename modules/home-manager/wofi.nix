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
    # Stylix sí, pero sin su CSS para no chocar con el nuestro
    stylix.targets.wofi = {
      enable = true;
      addCss = false;
    };

    programs.wofi = {
      enable = true;
      package = pkgs.wofi;

      # Config "ini" sin colores
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

      # Nuestro CSS, usando la paleta de Stylix (sin hex hardcoded)
      style = mkForce ''
        /* Dejamos la fuente a cargo de Stylix; aquí sólo tamaño si quieres */
        * { font-size: 14px; }

        /* Ventana principal */
        window {
          margin: 0px;
          padding: 10px;
          border: 0.16em solid ${c.base08};   /* acento (rojo/alerta) */
          border-radius: 10px;
          background-color: ${c.base00};      /* fondo */
          animation: slideIn 0.25s ease-out both;
        }

        /* Animación de entrada */
        @keyframes slideIn {
          from { opacity: 0; transform: translateY(-4px); }
          to   { opacity: 1; transform: translateY(0); }
        }

        /* Contenedores */
        #outer-box,
        #inner-box,
        #scroll,
        #entry {
          background-color: ${c.base00};
          border: none;
        }

        #inner-box,
        #text {
          animation: fadeIn 0.2s ease-out both;
        }

        /* Fade suave */
        @keyframes fadeIn {
          from { opacity: 0; }
          to   { opacity: 1; }
        }

        /* Input de búsqueda */
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

        /* Texto de entradas */
        #text {
          margin: 5px;
          border: none;
          color: ${c.base05};
        }

        /* Flechita desplegable (si la quieres ocultar del todo) */
        #entry arrow {
          opacity: 0; min-width: 0; margin: 0; /* quita la flecha */
        }

        /* Estado seleccionado */
        #entry:selected {
          border: 0.11em solid ${c.base0D};   /* acento (azul) */
          background: ${c.base01};            /* leve contraste */
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
