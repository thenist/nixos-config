# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports = [
    ./greeter.nix
    ./zapret2.nix
  ];

  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
  };

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Tailscale VPN.
  services.tailscale.enable = true;

  # Allow incoming connections on the tailnet interface.
  networking.firewall.trustedInterfaces = [ "tailscale0" ];

  # Set your time zone.
  time.timeZone = "Asia/Seoul";

  # Select internationalisation properties.
  i18n.defaultLocale = "ko_KR.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "ko_KR.UTF-8";
    LC_IDENTIFICATION = "ko_KR.UTF-8";
    LC_MEASUREMENT = "ko_KR.UTF-8";
    LC_MONETARY = "ko_KR.UTF-8";
    LC_NAME = "ko_KR.UTF-8";
    LC_NUMERIC = "ko_KR.UTF-8";
    LC_PAPER = "ko_KR.UTF-8";
    LC_TELEPHONE = "ko_KR.UTF-8";
    LC_TIME = "ko_KR.UTF-8";
  };

  services.dbus.enable = true;
  security.polkit.enable = true;
  security.pam.services.quickshell-lock = {};
  programs.dconf.enable = true;

  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-wlr
    ];
  };

  services.gvfs.enable = true;
  services.udisks2.enable = true;
  services.tumbler.enable = true;
  services.upower.enable = true;

  # USB device nodes default to root:root 0664, so non-root users cannot
  # open vendor 2a0e devices read-write.
  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTRS{idVendor}=="2a0e", MODE="0666"
  '';

  # Compressed RAM swap (zstd, capped at 50% of RAM). No host has disk swap.
  zramSwap.enable = true;

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Korean input: fcitx5 with the libhangul-based hangul engine (the same
  # engine ibus-hangul wraps, so composition behaviour is unchanged). fcitx5
  # implements both input-method-v1 and -v2, so it drives niri's text-input-v3
  # clients directly, and it re-injects unhandled keys through the compositor's
  # virtual keyboard instead of relying on forward_key_event, which is what the
  # old ibus setup could not do on Wayland.
  #
  # waylandFrontend leaves GTK_IM_MODULE/QT_IM_MODULE unset so GTK 3/4 and
  # Qt >= 6.8.2 use text-input-v3; XMODIFIERS is set for X11/XWayland apps.
  # The niri keymap makes right Alt the Hangul key, so keep it as the toggle,
  # as before, with Ctrl+Space as the fallback.
  i18n.inputMethod = {
    type = "fcitx5";
    enable = true;
    fcitx5 = {
      waylandFrontend = true;
      # fcitx5 dumps its own copy of the config into ~/.config/fcitx5 when it
      # exits, and that copy shadows /etc/xdg/fcitx5 (it is what turned the
      # toggle key into an empty value). Ignore the user copy so the settings
      # below stay authoritative.
      ignoreUserConfig = true;
      addons = with pkgs; [
        fcitx5-hangul
        qt6Packages.fcitx5-configtool
      ];
      settings = {
        # fcitx5 stores hotkey *lists* as indexed sub-keys, not as a
        # comma-separated string, so this has to render as
        #   [Hotkey/TriggerKeys]
        #   0=Hangul
        #   1=Control+space
        # to match fcitx5's own on-disk format.
        globalOptions."Hotkey/TriggerKeys" = {
          "0" = "Hangul";
          "1" = "Control+space";
        };
        # No popup on Korean/English switches. fcitx5's overlay message is
        # the "Show Input Method Information when switch input method" option;
        # ShowFirstInputMethodInformation only affects the inactive (English)
        # half and is moot while this is off.
        globalOptions.Behavior.ShowInputMethodInformation = false;
        # Default group: US layout plus the Hangul engine. Starting on
        # keyboard-us keeps a fresh session English until the toggle is hit.
        inputMethod = {
          "Groups/0" = {
            Name = "Default";
            "Default Layout" = "us";
            DefaultIM = "keyboard-us";
          };
          "Groups/0/Items/0".Name = "keyboard-us";
          "Groups/0/Items/1".Name = "hangul";
          "GroupOrder"."0" = "Default";
        };
      };
    };
  };

  # Install firefox. Its light/dark theme follows the system color scheme,
  # which users/thenist/home.nix sets to dark via gtk.colorScheme.
  programs.firefox = {
    enable = true;
    languagePacks = [ "ko" "en-US" ];
  };

  # Install git.
  programs.git.enable = true;

  # zsh as the login shell (set for thenist in users/thenist/user.nix).
  # Enabling it registers zsh in /etc/shells and creates /etc/zshrc; the
  # interactive configuration (oh-my-zsh + powerlevel10k) lives in
  # users/thenist/home.nix, which runs its own compinit, so the global
  # compinit here would only duplicate that scan on every shell start.
  programs.zsh = {
    enable = true;
    enableGlobalCompInit = false;
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Install fonts.
  fonts.packages = with pkgs; [
    nanum
    noto-fonts-cjk-sans
    adwaita-fonts
    nerd-fonts.jetbrains-mono
  ];

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
      vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
      wget
     btop
     unzip
     exfat
     ffmpeg
     python315
     gcc
     unrar
      gnumake
      quickshell
      cage
      xwayland-satellite
      xdg-desktop-portal
      xdg-desktop-portal-gtk
      xdg-desktop-portal-wlr
      foot
      mako
      swayidle
      grim
      slurp
      wl-clipboard
      brightnessctl
      pavucontrol
      networkmanagerapplet
      polkit_gnome
      wlr-randr
      wdisplays
      thunar
      adwaita-fonts
      libnotify
      playerctl
      cargo
      rustc
      cifs-utils
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Auto optimise store on every rebuild.
  nix.settings.auto-optimise-store = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "26.11"; # Did you read the comment?

}
