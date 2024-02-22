# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, lib, pkgs, ... }:

let
  env = import ./env.nix;
in
{
  imports =
    [
      ./hardware-configuration.nix
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

  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

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
      desktopManager.gnome.enable = true;
      displayManager.gdm.wayland = !env.nvidia; # FUCK YOU NVIDIA

      digimend.enable = true;

      xkb.layout = "br";
      xkb.variant = "";
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
    "wireplumber/bluetooth.lua.d/50-bluez-config.lua".text = ''
      		bluez_monitor.properties = {
      			["bluez5.enable-sbc-xq"] = true,
      			["bluez5.enable-msbc"] = true,
      			["bluez5.enable-hw-volume"] = true,
      			["bluez5.headset-roles"] = "[ hsp_hs hsp_ag hfp_hf hfp_ag ]"
      		}
      	'';
  };

  virtualisation.docker.enable = true;

  nixpkgs.config.allowUnfree = true;

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
        vscode
        nixpkgs-fmt
        pavucontrol
        git
        ffmpeg
        python3
        go
        nodejs
        yarn
        imagemagick
        p7zip
        libreoffice
        krita
        fragments
        lollypop
        foliate
        tagger
        discord
        fusee-launcher
        ns-usbloader


        gnome-online-accounts
        gnome.geary
        gnome.gnome-sound-recorder
        gnome3.gnome-tweaks
        gnome3.adwaita-icon-theme
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
      ]
      ++
      (lib.optionals (!env.work) [
        osu-lazer-bin
        lutris
        wine
        winetricks
        cartridges
      ])
      ++
      (lib.optionals env.work [
        dotnet-sdk
        slack
        awscli
        terraform
      ]);
  };

  i18n.inputMethod = {
    enabled = "ibus";
    ibus.engines = with pkgs.ibus-engines; [ libpinyin ];
  };

  programs = {
    steam.enable = !env.work;
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
  services.xserver.videoDrivers = lib.optional env.nvidia "nvidia";
  hardware.nvidia = lib.optionalAttrs env.nvidia {
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

    mkcd() {
      mkdir -p "$1" && cd "$1"
    }
  '';

  environment.sessionVariables = {
    TZ = config.time.timeZone; # Workarround for timezones
  };

  services = {
    udev.packages = with pkgs; [ gnome.gnome-settings-daemon ns-usbloader ];
    openssh = {
      enable = true;
      settings.PasswordAuthentication = false;
      settings.KbdInteractiveAuthentication = false;
    };
  };

  networking.firewall.enable = false;

  system.stateVersion = env.stateVersion;
}
