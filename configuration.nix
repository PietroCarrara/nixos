# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, lib, pkgs, ... }:

let
  env = import ./env.nix;
  aagl-gtk-on-nix = import (builtins.fetchTarball
    "https://github.com/ezKEa/aagl-gtk-on-nix/archive/main.tar.gz");
in {
  imports = [ ./hardware-configuration.nix aagl-gtk-on-nix.module ];

  boot = {
    kernelParams = [ "quiet" "splash" ]
      ++ (lib.optionals env.intel [ "i915.enable_dc=0" "i915.enable_psr=0" ]);
    consoleLogLevel = 0;
    initrd.verbose = false;
    plymouth.enable = true;
    loader = {
      timeout = 1;
      efi.canTouchEfiVariables = true;
      systemd-boot.enable = true;
    };
    swraid.enable = false;
  };

  nix.settings = aagl-gtk-on-nix.nixConfig; # Set up Cachix for aagl

  nix.gc = {
    automatic = true;
    randomizedDelaySec = "14m";
    options = "--delete-older-than 7d";
  };

  networking = {
    hostName = "hope";
    networkmanager.enable = true;
    firewall.enable = false;
    # extraHosts = ''
    #   15.228.191.142 api.mobiltracker.com.br
    # '';
  };

  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  hardware.enableAllFirmware = true;

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
  services.xserver = {
    enable = true;
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;
    displayManager.gdm.wayland = false;

    # digimend.enable = true;

    xkb.layout = "br";
    xkb.variant = "";
  };

  console.keyMap = "br-abnt2";

  services.printing.enable = true;

  services.transmission = {
    enable = !env.work;
    package = pkgs.transmission_4;
    user = "pietro";
    home = "/home/pietro";

    settings = {
      utp-enabled = true;
      incomplete-dir = "/home/pietro/Downloads/torrents/incomplete";
      download-dir =
        "/home/pietro/Downloads/torrents/incomplete"; # Legacy compat
      download-queue-enabled = false;
      rpc-whitelist-enabled = false;
      rpc-bind-address = "0.0.0.0";
    };
  };

  services.sunshine = { enable = !env.work; };

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };

  virtualisation.docker.enable = true;

  nixpkgs.config = {
    allowUnfree = true;
    permittedInsecurePackages = [
      "dotnet-sdk-wrapped-6.0.428"
      "dotnet-sdk-6.0.428"
      # These packages are not insecure by themselves, but we put dotnet 6 inside of them
      "dotnet-combined"
      "dotnet-wrapped-combined"
    ];

    packageOverrides = pkgs:
      {
        # https://github.com/ibus/ibus/issues/2656
        # https://github.com/ibus/ibus/issues/2618
        # ibus = pkgs.ibus.overrideAttrs
        #   (old: rec {
        #     version = "1.5.29";
        #     src = pkgs.fetchFromGitHub {
        #       owner = "ibus";
        #       repo = "ibus";
        #       rev = version;
        #       sha256 = "sha256-d4EUIg0v8rfHdvzG5USc6GLY6QHtQpIJp1PrPaaBxxE=";
        #     };
        #   });
      };
  };

  users.users.pietro = {
    isNormalUser = true;
    description = "Pietro Benati Carrara";
    extraGroups = [ "networkmanager" "wheel" "audio" "docker" ];

    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCeG3EUJYQanCRC5bffvsUyCQc35PbBPBc1Yvq8yyW/Sh9E4DoryM8xeGufcO8L/cshjvzPK51s4+7AiDz9Cw2YygV/jxKCGtcTnWUUDOc36kuvVi+zusRwNPCV4HvE3EaPVdF3R9Kv5JE3N9uZywTA7k1In2naIUURZvWsfKX+LjBWvkCMYMIn+wQrm9eGjhOY3+wAsOqanLCkZEb7ltn4UlY+kz5v1OHOGZkeqznk0JQ4qk/71mUxDc9v9STwmvNf4+s2oIQykqNizyFnsBWJ2dFhg+K65sruZVzAdb1HNYgj/TWsibqFICqpmiqmrWZ6/+r2PGH3oCPNXQF0CXDv Redmi"
    ];

    packages = with pkgs;
      [
        firefox
        zoom-us
        scribus
        nixfmt-classic
        pavucontrol
        git
        ffmpeg
        (python3.withPackages (pip: [
          pip.pandas
          pip.requests
          pip.cloudscraper
          pip.lxml
          pip.beautifulsoup4
        ]))
        clang
        go
        nodejs
        yarn
        imagemagickBig
        p7zip
        libreoffice
        krita
        foliate
        eartag
        geary
        discord
        fusee-launcher
        ns-usbloader

        # PDF manipulation
        pdftk
        texliveMedium

        gnome-online-accounts
        gnome-tweaks
        adwaita-icon-theme
        gnome-sound-recorder
        gnomeExtensions.unite
        gnomeExtensions.appindicator
        gnomeExtensions.gsconnect

        gst_all_1.gstreamer
        gst_all_1.gstreamer.dev
        gst_all_1.gst-plugins-base
        gst_all_1.gst-plugins-good
        gst_all_1.gst-plugins-bad
        gst_all_1.gst-plugins-ugly
        gst_all_1.gst-libav

        (pkgs.writeShellScriptBin "flac2mp3"
          (builtins.readFile ./scripts/flac2mp3.sh))
        (pkgs.writeShellScriptBin "cue2flac"
          ((import ./scripts/cue2flac.sh.nix) { inherit cuetools; }))

        (mpv.override {
          scripts = [ mpvScripts.mpris ];
          extraMakeWrapperArgs = [ "--add-flags" "--cache=yes" ];
        })

        (lollypop.override {
          lastFMSupport = false;
          youtubeSupport = false;
          kid3Support = false;
        })
      ] ++ (lib.optionals (!env.work) [
        osu-lazer-bin
        lutris
        wine
        winetricks
        cartridges
        vscode
        transmission-remote-gtk
      ]) ++ (lib.optionals env.work [
        rustup
        vscode-fhs
        slack
        awscli2
        terraform
        packer
        jdk17
        android-tools
        android-studio
        dbeaver-bin
        (with dotnetCorePackages; combinePackages [ sdk_6_0 sdk_8_0_3xx ])
      ]);
  };

  i18n.inputMethod = {
    enable = true;
    type = "ibus";
    ibus.engines = with pkgs.ibus-engines; [ libpinyin ];
  };

  programs = {
    steam.enable = !env.work;
    wireshark = {
      enable = true;
      package = pkgs.wireshark;
    };
    xwayland.enable = true;
    neovim = {
      enable = true;
      defaultEditor = true;
    };
    honkers-railway-launcher.enable = !env.work;
  };

  fonts = {
    fontconfig = { subpixel.rgba = "rgb"; };
    packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-emoji
      liberation_ttf
    ];
  };

  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "pietro";

  # Tell Xorg to use the nvidia driver (also valid for Wayland)
  services.xserver.videoDrivers = lib.optional env.nvidia "nvidia";
  hardware.graphics = {
    enable = true;
    extraPackages = lib.optionals env.intel
      (with pkgs; [ intel-media-driver intel-ocl intel-vaapi-driver ]);
  };
  hardware.nvidia = lib.optionalAttrs env.nvidia {
    open = false;
    modesetting.enable = true;
    package = config.boot.kernelPackages.nvidiaPackages.latest;
    prime = {
      offload.enableOffloadCmd = true;
      reverseSync.enable = true;
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:4:0:0";
    };
  };

  # Workaround for GNOME autologin: https://github.com/NixOS/nixpkgs/issues/103746#issuecomment-945091229
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;
  services.logind.lidSwitch = "ignore"; # Don't suspend on laptop lid closed

  environment.sessionVariables = {
    NIX_AUTO_RUN = "ENABLE";
    # You'll have to install the SDK via android studio to this folder, I'm too busy to make this with a nix file
    ANDROID_HOME = lib.optional env.work "/home/pietro/Android/Sdk";
    LIBVA_DRIVER_NAME = lib.optional env.intel "iHD";
  };

  environment.sessionVariables.GST_PLUGIN_SYSTEM_PATH_1_0 =
    lib.makeSearchPathOutput "lib" "lib/gstreamer-1.0" (with pkgs.gst_all_1; [
      gst-plugins-good
      gst-plugins-bad
      gst-plugins-ugly
      gst-libav
    ]);

  environment.interactiveShellInit = ''
    alias v=nvim
    alias q=exit
    alias open=xdg-open
    alias xq="python -c 'import sys, xml.dom.minidom; print(xml.dom.minidom.parseString(sys.stdin.read()).toprettyxml())'"

    mkcd() {
      mkdir -p "$1" && cd "$1"
    }
  '';

  environment.sessionVariables = {
    TZ = config.time.timeZone; # Workarround for timezones
  };

  services = {
    udev.packages = with pkgs; [ gnome-settings-daemon ns-usbloader ];
    openssh = {
      enable = true;
      settings.PasswordAuthentication = false;
      settings.KbdInteractiveAuthentication = false;
    };
    fstrim.enable = lib.mkDefault true; # nix-hardware for ssd
  };

  system.stateVersion = env.stateVersion;
}
