# System-wide git registration. The GitHub identity and preferences live in
# programs/home/git.nix, which home-manager writes to ~/.config/git/config.

{ ... }:

{
  programs.git.enable = true;
}
