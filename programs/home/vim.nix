# vim with the 42 header plugin, which stamps the 42 school header into new
# files. The identity it writes is not the GitHub one above: 42 wants the
# student login and campus mail address.

{ pkgs, ... }:

{
  programs.vim = {
    enable = true;
    plugins = [
      (pkgs.vimUtils.buildVimPlugin {
        pname = "42header";
        version = "unstable-2026-05-13";
        src = pkgs.fetchFromGitHub {
          owner = "42Paris";
          repo = "42header";
          rev = "0b5698ad1c7cc6d43783419d97c8e6cf97088e64";
          hash = "sha256-xdH/SeGv1bfKMmJ9cHYd5V+ynFohzprnUC8eVer1VcI=";
        };
      })
    ];
    extraConfig = ''
      let g:user42 = 'sumpark'
      let g:mail42 = 'sumpark@student.42gyeongsan.kr'
    '';
  };
}
