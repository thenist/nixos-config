# GitHub identity (github.com/thenist, owner of this repo's origin).
# Home-manager writes this to $XDG_CONFIG_HOME/git/config, which git reads
# (XDG_CONFIG_HOME is unset in the session, so it resolves to
# ~/.config/git/config). The imperative ~/.gitconfig that lived at the
# classic path has been moved to ~/.gitconfig.backup: git gives that file
# priority over the XDG one, so leaving it would silently shadow any later
# edit here.

{ ... }:

{
  programs.git = {
    enable = true;
    settings = {
      user.name = "thenist";
      user.email = "p717394@gmail.com";
    };
  };
}
