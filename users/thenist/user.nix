{ config, pkgs, ... }:

{
  users.users.thenist = {
    isNormalUser = true;
    description = "thenist";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
      prismlauncher
    ];
  };
}
