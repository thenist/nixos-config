# Firefox, installed system-wide. Its light/dark theme follows the system
# colour scheme, which programs/home/appearance.nix sets to dark via
# gtk.colorScheme.

{ ... }:

{
  programs.firefox = {
    enable = true;
    languagePacks = [ "ko" "en-US" ];
  };
}
