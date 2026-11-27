# VS Code. Only the package is declared; settings and extensions stay in the
# editor's GUI-managed configuration, which home-manager does not own.

{ ... }:

{
  programs.vscode.enable = true;
}
