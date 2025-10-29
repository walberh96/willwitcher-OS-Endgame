{ lib, ... }:

{
  # Solo escribimos el settings.json. Zed lo tienes instalado vía home.packages.
  xdg.configFile."zed/settings.json".text = lib.generators.toJSON {} {
    # Follow system theme
    theme = "System";

    # Fonts
    ui_font_size = 12;
    buffer_font_size = 12;

    # Saving / formatting
    autosave = "on_focus_change";   # antes: auto_save
    format_on_save = "on";          # "on" | "off"

    # Wrapping / width
    preferred_line_length = 100;
    soft_wrap = "preferred_line_length";

    # Indentation
    tab_size = 4;
    hard_tabs = false;              # equivalente a “translate_tabs_to_spaces = true”

    # Git inline diff: se eliminó el viejo show_inline_git_diff.
    # Si quieres indicadores en el scrollbar, Zed ya expone:
    # "scrollbar": { "git_diff": true } por defecto.
  };
}
