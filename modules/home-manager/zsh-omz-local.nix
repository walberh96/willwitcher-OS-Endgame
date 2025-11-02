{ config, lib, pkgs, inputs, ... }:

let
  cfg = config.willwitcher.zsh;
  omzCustom = "${config.xdg.configHome}/zsh/omz-custom";
in
with lib; {
  options.willwitcher.zsh = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable WillWitcher Zsh with Oh My Zsh and local plugins.";
    };

    # Carpeta en tu flake donde viven tus plugins (cada plugin en una subcarpeta).
    pluginsRoot = mkOption {
      type = types.path;
      default = inputs.self + /configs/zsh/plugins;
      description = "Root path (in the flake repo) for local Zsh plugins.";
    };

    # Lista de nombres de carpeta (orden = orden de carga).
    pluginNames = mkOption {
      type = with types; listOf str;
      default = [];
      description = "Local plugin folder names under pluginsRoot (load order = list order).";
    };

    # Plugins nativos de OMZ que quieras además de los locales.
    extraOmzPlugins = mkOption {
      type = with types; listOf str;
      default = [ "git" "sudo" "z" "colored-man-pages" ];
      description = "Built-in Oh My Zsh plugins.";
    };

    # OMZ theme: lo dejamos vacío para no usar tema (prompt lo maneja Starship).
    theme = mkOption {
      type = types.str;
      default = "";
      description = "If empty, OMZ won't load a theme; Starship handles the prompt.";
    };

    # Usa Starship por defecto (prompt).
    useStarship = mkOption {
      type = types.bool;
      default = true;
      description = "Enable Starship prompt with Zsh integration.";
    };

    # Hooks opcionales.
    extraInitBeforeCompInit = mkOption {
      type = types.lines;
      default = "";
      description = "Extra init before compinit.";
    };

    extraInit = mkOption {
      type = types.lines;
      default = "";
      description = "Extra init after OMZ is set.";
    };

    extraOhMyZshConfig = mkOption {
      type = types.lines;
      default = "";
      description = "Appended to oh-my-zsh.extraConfig.";
    };
  };

  config = mkIf cfg.enable {
    programs.zsh = {
      enable = true;
      enableCompletion = true;

      # Usamos tu plugin local de highlighting, así que no el de HM.
      syntaxHighlighting.enable = false;

      oh-my-zsh = {
        enable  = true;
        package = pkgs.oh-my-zsh;
        custom  = omzCustom;
        theme   = cfg.theme;                       # "" => sin tema OMZ
        plugins = cfg.extraOmzPlugins ++ cfg.pluginNames;
        extraConfig = ''
          ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE=fg=8
          ${cfg.extraOhMyZshConfig}
        '';
      };

      # Antes de compinit, añade rutas de completions detectadas por plugin.
      initExtraBeforeCompInit = ''
        _ww_custom="${omzCustom}/plugins"
        for p in ${lib.concatStringsSep " " cfg.pluginNames}; do
          for d in src completions completion _completions functions; do
            if [ -d "${omzCustom}/plugins/$p/$d" ]; then
              fpath=("${omzCustom}/plugins/$p/$d" $fpath)
            fi
          done
        done
        ${cfg.extraInitBeforeCompInit}
      '';

      # Hook extra del usuario (después de OMZ).
      initExtra = cfg.extraInit;
    };

    # Starship (prompt); Stylix puede dar los colores.
    programs.starship = mkIf cfg.useStarship {
      enable = true;
      enableZshIntegration = true;
    };

    # 1) Symlink de cada plugin local a $ZSH_CUSTOM/plugins/<name>
    # 2) Wrapper genérico __ww-autoload.plugin.zsh por plugin:
    #    - Si el plugin ya trae *.plugin.zsh (además del nuestro), no hace nada.
    #    - Si no, hace source de todos los *.zsh (excepto *.plugin.zsh).
    home.file =
      let
        links = lib.listToAttrs (map (p: {
          name = ".config/zsh/omz-custom/plugins/${p}";
          value = {
            source = cfg.pluginsRoot + "/${p}";
            recursive = true;
            optional = true;  # permite que no exista aún sin romper la build
          };
        }) cfg.pluginNames);

        wrappers = lib.listToAttrs (map (p: {
          name = ".config/zsh/omz-custom/plugins/${p}/__ww-autoload.plugin.zsh";
          value = {
            text = ''
              # Autoload seguro: si hay otro *.plugin.zsh (además de este), no hagas nada.
              local _dir="${omzCustom}/plugins/${p}"
              local -a _others
              _others=("${_dir}"/*.plugin.zsh(N))
              if (( ${#_others} > 1 )); then
                return
              fi

              setopt localoptions no_aliases no_sh_wordsplit
              for _f in "$_dir"/*.zsh; do
                [[ -e "$_f" ]] || continue
                case "$_f" in (*.plugin.zsh) ;; (*) source "$_f" ;; esac
              done
              unset _dir _others _f
            '';
            optional = true;
          };
        }) cfg.pluginNames);
      in
      links // wrappers;
  };
}
