{ lib, pkgs, ... }:

{
  imports = [
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

  gtk = {
    enable = true;

    # Sets gtk-application-prefer-dark-theme in the GTK 3/4 settings.ini and
    # org.gnome.desktop.interface color-scheme in dconf. Everything that reads
    # the XDG settings portal gets this too (libadwaita, Qt, Chromium/Electron),
    # which is why apps that ignore gtk-theme-name still render dark.
    colorScheme = "dark";

    # Noctalia's GTK templates (theme.templates above) layer its palette over
    # the adw-gtk3 base theme, which the Noctalia docs require for GTK 3.
    # GTK 4 keeps libadwaita's default theme (gtk.gtk4.theme is null at this
    # stateVersion), so only the noctalia.css import colours GTK 4 apps.
    theme = {
      name = "adw-gtk3-dark";
      package = pkgs.adw-gtk3;
    };

    iconTheme = {
      name = "WhiteSur-dark";
      package = pkgs.whitesur-icon-theme;
    };
  };

  # Qt apps ignore the settings portal unless a platform theme is selected;
  # the GTK3 platform theme makes them take the palette/fonts from the GTK
  # theme (adw-gtk3-dark + Noctalia's noctalia.css) and follow the colour
  # scheme. Sets QT_QPA_PLATFORMTHEME for the session (systemd user
  # environment) and for login shells.
  qt = {
    enable = true;
    platformTheme.name = "gtk3";
  };

  home.pointerCursor = {
    enable = true;
    name = "WhiteSur-cursors";
    size = 24;
    package = pkgs.whitesur-cursors;
    gtk.enable = true;
  };
}
