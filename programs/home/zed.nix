# Zed. As with VS Code, only the package is declared; settings, keymaps and
# extensions stay in the editor's GUI-managed configuration. Home-manager
# writes ~/.config/zed/settings.json only when userSettings is non-empty, so
# the defaults leave that file, and the GUI that owns it, alone.

{ ... }:

{
  programs.zed-editor.enable = true;
}
