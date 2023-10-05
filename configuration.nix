# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, lib, pkgs, ... }:

let
  stateVersion = "23.05";
  home-manager = builtins.fetchTarball "https://github.com/nix-community/home-manager/archive/master.tar.gz";
in
{
  imports =
    [
      ./hardware-configuration.nix
      (import "${home-manager}/nixos")
    ];

  boot = {
    kernelParams = [ "quiet" "splash" ];
    consoleLogLevel = 0;
    initrd.verbose = false;
    plymouth.enable = true;
    loader = {
      timeout = 1;
      efi.canTouchEfiVariables = true;
      systemd-boot.enable = true;
    };
    initrd.kernelModules = [ "i915" ];
    swraid.enable = false;
  };

  nix.gc = {
    automatic = true;
    randomizedDelaySec = "14m";
    options = "--delete-older-than 7d";
  };

  networking.hostName = "hope";
  networking.networkmanager.enable = true;

  time.timeZone = "America/Sao_Paulo";

  i18n.defaultLocale = "pt_BR.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "pt_BR.UTF-8";
    LC_IDENTIFICATION = "pt_BR.UTF-8";
    LC_MEASUREMENT = "pt_BR.UTF-8";
    LC_MONETARY = "pt_BR.UTF-8";
    LC_NAME = "pt_BR.UTF-8";
    LC_NUMERIC = "pt_BR.UTF-8";
    LC_PAPER = "pt_BR.UTF-8";
    LC_TELEPHONE = "pt_BR.UTF-8";
    LC_TIME = "pt_BR.UTF-8";
  };

  # Enable a windowing system (not necessarily xorg).
  services.xserver =
    {
      enable = true;
      displayManager.gdm.enable = true;
      displayManager.gdm.wayland = false; # FUCK YOU NVIDIA
      desktopManager.gnome.enable = true;

      digimend.enable = true;

      layout = "br";
      xkbVariant = "";
    };

  console.keyMap = "br-abnt2";

  services.printing.enable = true;

  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };
  environment.etc = {
    "pipewire/pipewire.conf.d/91-echo-cancel.conf" = {
      text = ''
        context.modules = [
          {
            name = "libpipewire-module-echo-cancel"
          }
        ]
      '';
    };
  };

  fileSystems."/mnt/data" = {
    device = "/dev/disk/by-uuid/7824aa78-c76c-4a2a-b1f3-a5aaff888406";
    fsType = "ext4";
  };

  virtualisation.docker.enable = true;
  users.extraGroups.docker.members = [ "pietro" ];

  users.users.pietro = {
    isNormalUser = true;
    description = "Pietro Benati Carrara";
    extraGroups = [ "networkmanager" "wheel" ];

    packages = with pkgs;
      [
        firefox
        vscode
        nixpkgs-fmt
        deluged
        deluge-gtk
        pavucontrol
        git
        pipewire
        ffmpeg
        python3
        nodejs
        yarn
        imagemagick
        p7zip
        fusee-launcher
        osu-lazer-bin
        lutris
        wine
        winetricks
        obsidian
        libreoffice
        krita
        fragments
        lollypop
        cartridges
        ns-usbloader
        discord

        gnome-online-accounts
        gnome.geary
        gnome.gnome-sound-recorder
        gnome3.gnome-tweaks
        gnome3.adwaita-icon-theme
        gnomeExtensions.unite
        gnomeExtensions.appindicator
        gnomeExtensions.gsconnect
        gnomeExtensions.geary-tray-icon

        gst_all_1.gstreamer
        gst_all_1.gstreamer.dev
        gst_all_1.gst-plugins-base
        gst_all_1.gst-plugins-good
        gst_all_1.gst-plugins-bad
        gst_all_1.gst-plugins-ugly
        gst_all_1.gst-libav

        (pkgs.writeShellScriptBin "flac2mp3" (builtins.readFile ./scripts/flac2mp3.sh))

        (mpv.override {
          scripts = [
            mpvScripts.mpris
          ];
          extraMakeWrapperArgs = [
            "--add-flags"
            "--cache=yes"
          ];
        })
      ];
  };

  i18n.inputMethod = {
    enabled = "ibus";
    ibus.engines = with pkgs.ibus-engines; [ libpinyin ];
  };

  programs = {
    steam.enable = true;
    xwayland.enable = true;
    neovim = { enable = true; defaultEditor = true; };
  };

  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    liberation_ttf
  ];

  services.xserver.displayManager.autoLogin.enable = true;
  services.xserver.displayManager.autoLogin.user = "pietro";

  # Make sure opengl is enabled
  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
  };

  # Tell Xorg to use the nvidia driver (also valid for Wayland (might not work on wayland actually, FUCK YOU NVIDIA))
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    open = false;
    modesetting.enable = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    prime = {
      sync.enable = true;
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:4:0:0";
    };
  };

  # Workaround for GNOME autologin: https://github.com/NixOS/nixpkgs/issues/103746#issuecomment-945091229
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;

  nixpkgs.config.allowUnfree = true;

  environment.sessionVariables.GST_PLUGIN_SYSTEM_PATH_1_0 = lib.makeSearchPathOutput
    "lib"
    "lib/gstreamer-1.0"
    (with pkgs.gst_all_1;
    [
      gst-plugins-good
      gst-plugins-bad
      gst-plugins-ugly
      gst-libav
    ]);

  environment.interactiveShellInit = ''
    alias v=nvim
    alias q=exit
    alias open=xdg-open

    prompt()
    {
      if [[ $? == 0 ]]; then
        echo "$(tput setaf 5)λ$(tput sgr0) "
      else
        echo "$(tput setaf 1)λ$(tput sgr0) "
      fi
    }
    export PS1='$(prompt)'

    mkcd() {
      mkdir -p "$1" && cd "$1"
    }
  '';

  environment.sessionVariables = {
    TZ = config.time.timeZone; # Workarround for timezones
  };

  services.udev.packages = with pkgs; [ gnome.gnome-settings-daemon ns-usbloader ];

  networking.firewall.enable = false;

  system.stateVersion = stateVersion; # Did you read the comment?
  system.autoUpgrade.channel = "https://nixos.org/channels/nixos-${stateVersion}/";
}
