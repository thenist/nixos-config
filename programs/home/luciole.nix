# Noctalia's own file manager, installed by the upstream flake input. The
# built-in `luciole` template in programs/home/noctalia.nix writes
# ~/.config/luciole/colors.toml, which Luciole reads live (its color_scheme
# defaults to "auto"). Layout and behaviour preferences stay in Luciole's
# GUI-managed settings.toml.

{ ... }:

{
  programs.luciole = {
    enable = true;
  };
}
