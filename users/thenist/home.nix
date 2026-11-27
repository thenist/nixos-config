# thenist's home-manager entry point. Each program's own settings now live in
# programs/home/ (imported below); this file keeps the home identity, the DSH
# profile linking, and the default applications.

{ lib, pkgs, ... }:

{
  imports = [
    ../../programs/home/appearance.nix
    ../../programs/home/foot.nix
    ../../programs/home/git.nix
    ../../programs/home/luciole.nix
    ../../programs/home/niri.nix
    ../../programs/home/noctalia.nix
    ../../programs/home/vim.nix
    ../../programs/home/vscode.nix
    ../../programs/home/zsh.nix
  ];

  home.username = "thenist";
  home.homeDirectory = "/home/thenist";
  home.stateVersion = "26.11";

  # DSH has no NixOS-level plugin option: a profile is a pnpm project under
  # $DSH_HOME/profiles. The `moe` profile is a scratch layer kept apart from
  # `web` so the experimental moeseek voice can be mounted without touching the
  # daily driver: whatever a profile mounts applies to every session in it, so
  # the voice stays behind `dsh moe`. The Korean locale, the archive manager,
  # and genui, by contrast, belong in both profiles.
  #
  # These plugins are declared as Nix packages (packages/*.nix, pinned
  # revisions) and this activation makes each profile mount the store copy: the
  # `link:` dependency pnpm would record, the symlink pnpm would create under
  # node_modules, and the name in `dsh.profile.bundles` (the launcher mounts
  # nothing but the bundles named there). The merge is idempotent, points only
  # at the store path, and keeps bundles added later with `dsh plugin --profile
  # <name> add`, so a flake update relinks instead of leaving a stale copy.
  #
  # The moe profile is created from the web profile's patch file the first time,
  # so it carries the same model and permission settings; an existing profile's
  # patch and settings are left untouched. A profile that has no manifest yet (a
  # fresh machine's `web`, which dsh creates on first run) is skipped.
  home.activation.dshProfileBundles = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    profiles="$HOME/.dsh/profiles"

    if [ -d "$profiles/web" ] && [ ! -d "$profiles/moe" ]; then
      mkdir -p "$profiles/moe/node_modules"
      cp "$profiles/web/pnpm-workspace.yaml" "$profiles/moe/pnpm-workspace.yaml"
      cp "$profiles/web/cordis.patch.yml" "$profiles/moe/cordis.patch.yml"
      printf '{"name":"dsh-profile-moe","private":true}\n' > "$profiles/moe/package.json"
    fi

    linkBundle() {
      profile="$1"
      name="$2"
      plugin="$3"
      [ -f "$profile/package.json" ] || return 0
      run mkdir -p "$profile/node_modules/$(dirname "$name")"
      run rm -rf "$profile/node_modules/$name"
      run ln -s "$plugin" "$profile/node_modules/$name"

      tmp="$(mktemp)"
      ${pkgs.jq}/bin/jq --arg n "$name" --arg p "link:$plugin" \
        '(.dsh.profile.bundles // ["@deepseek-ai/dsh-base", "@deepseek-ai/dsh-web-app"]) as $b
         | .dsh.profile.bundles = (if ($b | index($n)) then $b else $b + [$n] end)
         | .dsh.profile.patchReload = (.dsh.profile.patchReload // "live")
         | .dependencies = ((.dependencies // {}) + {($n): $p})' \
        "$profile/package.json" > "$tmp"
      if ! cmp -s "$tmp" "$profile/package.json"; then
        run mv "$tmp" "$profile/package.json"
      else
        rm -f "$tmp"
      fi
    }

    linkBundle "$profiles/web" '@nolit/dsh-korean-locale' ${pkgs.dsh-korean-locale}
    linkBundle "$profiles/web" '@michengai/dsh-archive-manager' ${pkgs.dsh-archive-manager}
    linkBundle "$profiles/web" '@changfenhuang/dsh-genui' ${pkgs.dsh-genui}
    linkBundle "$profiles/moe" '@local/moeseek' ${pkgs.moeseek}
    linkBundle "$profiles/moe" '@nolit/dsh-korean-locale' ${pkgs.dsh-korean-locale}
    linkBundle "$profiles/moe" '@michengai/dsh-archive-manager' ${pkgs.dsh-archive-manager}
    linkBundle "$profiles/moe" '@changfenhuang/dsh-genui' ${pkgs.dsh-genui}
  '';

  # Folders opened through xdg-open, FileManager1 or a portal go to Luciole
  # now that Thunar is gone. mimeApps is opt-in in home-manager.
  xdg.mimeApps = {
    enable = true;
    defaultApplications."inode/directory" = "dev.noctalia.luciole.desktop";
  };
}
