{ config, pkgs, ... }:

{
  programs.steam = {
    enable = true; # Master switch, already covered in installation
    remotePlay.openFirewall = true;  # For Steam Remote Play
    dedicatedServer.openFirewall = true; # For Source Dedicated Server hosting
    # Other general flags if available can be set here.
  };
  users.users.thenist = {
    isNormalUser = true;
    description = "thenist";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
      prismlauncher
    ];
  };
}
