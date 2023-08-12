# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, lib, pkgs, nixpkgs-unstable, ... }:

let
  stateVersion = "23.05";
  home-manager = builtins.fetchTarball "https://github.com/nix-community/home-manager/archive/release-${stateVersion}.tar.gz";
  unstableTarball = fetchTarball https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz;
in
{
  imports =
    [
      # Include the results of the hardware scan.
      ./hardware-configuration.nix
      (import "${home-manager}/nixos")
    ];

  nixpkgs.config = {
    packageOverrides = pkgs: {
      unstable = import unstableTarball {
        config = config.nixpkgs.config;
      };
    };
  };

  # Bootloader.
  boot = {
    kernelParams = [ "quiet" "splash" ];
    consoleLogLevel = 0;
    initrd.verbose = false;
    plymouth.enable = true;
    loader = {
      timeout = lib.mkDefault 0;
      efi.canTouchEfiVariables = true;
      systemd-boot.enable = true;
    };
    initrd.kernelModules = [ "i915" ];
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
  services.xserver.enable = true;
  # Enable the GNOME Desktop Environment.
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.displayManager.gdm.wayland = true;
  services.xserver.desktopManager.gnome.enable = true;

  # Configure keymap in X11
  services.xserver = {
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
    "wireplumber/main.lua.d/51-disable-suspension.lua" = {
      text = ''
        table.insert (alsa_monitor.rules, {
          matches = {
            {
              -- Matches all sources.
              { "node.name", "matches", "alsa_input.*" },
            },
            {
              -- Matches all sinks.
              { "node.name", "matches", "alsa_output.*" },
            },
          },
          apply_properties = {
            ["session.suspend-timeout-seconds"] = 0,  -- 0 disables suspend
          },
        })
      '';
    };
  };

  fileSystems."/mnt/data" = {
    device = "/dev/disk/by-uuid/7824aa78-c76c-4a2a-b1f3-a5aaff888406";
    fsType = "ext4";
  };


  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.pietro = {
    isNormalUser = true;
    description = "Pietro Benati Carrara";
    extraGroups = [ "networkmanager" "wheel" ];

    packages = with pkgs; [
      firefox
      vscode
      discord
      nixpkgs-fmt
      deluged
      deluge-gtk
      pavucontrol
      git
      pipewire
      ffmpeg
      nodejs
      yarn
      imagemagick
      lutris
      wine
      winetricks
      obsidian
      libreoffice
      krita
      fragments
      unstable.cartridges

      gnome-online-accounts
      unstable.gnome.geary
      gnome.gnome-sound-recorder
      gnome3.gnome-tweaks
      gnome3.adwaita-icon-theme
      gnomeExtensions.unite
      gnomeExtensions.appindicator
      gnomeExtensions.gsconnect
      gnomeExtensions.geary-tray-icon
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

  fonts.fonts = with pkgs; [
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

  # Tell Xorg to use the nvidia driver (also valid for Wayland)
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    # Modesetting is needed for most Wayland compositors
    # modesetting.enable = false;
    # Use the open source version of the kernel module
    # Only available on driver 515.43.04+
    # open = false;
    # Enable the nvidia settings menu
    nvidiaSettings = true;
    # Optionally, you may need to select the appropriate driver version for your specific GPU.
    package = config.boot.kernelPackages.nvidiaPackages.beta;

    prime = {
      offload.enable = true;

      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:4:0:0";
    };
  };

  # Workaround for GNOME autologin: https://github.com/NixOS/nixpkgs/issues/103746#issuecomment-945091229
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages =
    let
      nvidia-offload = pkgs.writeShellScriptBin "nvidia-offload" ''
        export __NV_PRIME_RENDER_OFFLOAD=1
        export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
        export __GLX_VENDOR_LIBRARY_NAME=nvidia
        export __VK_LAYER_NV_optimus=NVIDIA_only
        exec "$@"
      '';
    in
    [ nvidia-offload ];

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

  environment.sessionVariables = {
    TZ = config.time.timeZone; # Workarround for timezones
  };

  services.udev.packages = with pkgs; [ gnome.gnome-settings-daemon ];

  home-manager.useGlobalPkgs = true;
  home-manager.users.pietro = { lib, pkgs, ... }: {
    home.stateVersion = stateVersion;
    # Overwrite steam.desktop shortcut so that is uses PRIME
    # offloading for Steam and all its games
    home.activation.steam = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      $DRY_RUN_CMD sed 's/^Exec=/&nvidia-offload /' \
        ${pkgs.steam}/share/applications/steam.desktop \
        > ~/.local/share/applications/steam.desktop
      $DRY_RUN_CMD chmod +x ~/.local/share/applications/steam.desktop
    '';

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
}
