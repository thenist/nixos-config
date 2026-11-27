# oh-my-zsh + powerlevel10k. oh-my-zsh resolves custom themes from
# $ZSH_CUSTOM/themes/$ZSH_THEME.zsh-theme, and the nixpkgs powerlevel10k
# package ships exactly share/zsh/themes/powerlevel10k/powerlevel10k.zsh-theme,
# so its share/zsh doubles as ZSH_CUSTOM. Completion/compinit is left to
# oh-my-zsh (programs/system/zsh.nix disables the global /etc/zshrc compinit
# so it does not run twice per shell).
#
# ~/.zshrc is a read-only store symlink, so the p10k wizard refuses to
# append its two fragments to it ("readonly and not owned by the user").
# They live here instead; mkBefore lands at the top of .zshrc, mkAfter at
# the bottom, exactly where the wizard would have put them. The prompt
# config itself is the wizard's output, copied verbatim to p10k.zsh: after
# a fresh `p10k configure` run, copy ~/.p10k.zsh over users/thenist/p10k.zsh
# to persist.

{ lib, pkgs, ... }:

{
  programs.zsh = {
    enable = true;

    oh-my-zsh = {
      enable = true;
      theme = "powerlevel10k/powerlevel10k";
      custom = "${pkgs.zsh-powerlevel10k}/share/zsh";
    };

    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    initContent = lib.mkMerge [
      (lib.mkBefore ''
        # Enable Powerlevel10k instant prompt. Should stay close to the top of .zshrc.
        # Initialization code that may require console input (password prompts, [y/n]
        # confirmations, etc.) must go above this block; everything else may go below.
        if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
          source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
        fi
      '')
      (lib.mkAfter ''
        # To customize prompt, run `p10k configure` or edit p10k.zsh in nixos-config.
        source ${../../users/thenist/p10k.zsh}
      '')
    ];
  };
}
