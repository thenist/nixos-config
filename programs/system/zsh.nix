# zsh as the login shell (set for thenist in users/thenist/user.nix).
# Enabling it registers zsh in /etc/shells and creates /etc/zshrc; the
# interactive configuration (oh-my-zsh + powerlevel10k) lives in
# programs/home/zsh.nix, which runs its own compinit, so the global compinit
# here would only duplicate that scan on every shell start.

{ ... }:

{
  programs.zsh = {
    enable = true;
    enableGlobalCompInit = false;
  };
}
