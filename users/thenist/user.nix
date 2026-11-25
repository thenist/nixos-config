{ config, pkgs, ... }:

{
  users.users.thenist = {
    isNormalUser = true;
    description = "thenist";
    shell = pkgs.zsh;
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
      codex
      prismlauncher
      freecad
      kicad
      solidcraft # parametric 3D CAD (flaked in from github:tangency-labs/solidcraft)
      orca-slicer
      discord
      slack
      qbittorrent
      parsec-bin
      norminette
      omp
      dsview
      deepseek-harness
    ];
  };
}
