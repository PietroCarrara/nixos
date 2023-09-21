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
      # Include the results of the hardware scan.
      ./hardware-configuration.nix
      (import "${home-manager}/nixos")
    ];

  # Bootloader.
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


  networking.hostName = "hope"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/Sao_Paulo";

  # Select internationalisation properties.
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
      # Enable the GNOME Desktop Environment.
      displayManager.gdm.enable = true;
      displayManager.gdm.wayland = false; # FUCK YOU NVIDIA
      desktopManager.gnome.enable = true;

      digimend.enable = true;

      # Configure keymap in X11
      layout = "br";
      xkbVariant = "";
    };

  # Configure console keymap
  console.keyMap = "br-abnt2";

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
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

  # Define a user account. Don't forget to set a password with ‘passwd’.
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

  # Enable automatic login for the user.
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

  # Allow unfree packages
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

  home-manager.useGlobalPkgs = true;
  home-manager.users.pietro = { lib, pkgs, ... }: {
    home.stateVersion = stateVersion;

    programs.mpv = {
      enable = true;
      config = {
        cache = "yes";
      };
    };

    xdg.desktopEntries = {
      fragments = {
        name = "Fragments";
        exec = "fragments %U";
        terminal = false;
        type = "Application";
        startupNotify = true;
        mimeType = [ "x-scheme-handler/magnet" "application/x-bittorrent" ];
        categories = [ "GNOME" "GTK" "Utility" ];
        settings = {
          Keywords = "bittorrent;torrent;magnet;download;p2p;";
          "X-Purism-FormFactor" = "Workstation;Mobile;";
        };
      };
    };
  };

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
  networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = stateVersion; # Did you read the comment?
  system.autoUpgrade.channel = "https://nixos.org/channels/nixos-${stateVersion}/";
}
