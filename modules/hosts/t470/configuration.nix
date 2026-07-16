{ self, inputs, ... }: {
  flake.nixosModules.t470Configuration = { pkgs, config, lib, ... }: {

    imports =
      [ 
        self.nixosModules.t470Hardware
        self.nixosModules.myNiri
        self.nixosModules.desktop
        self.nixosModules.agent-harness
        self.nixosModules.neovim
        self.nixosModules.keyboard
        self.nixosModules.ghostty
        self.nixosModules.rlc
        inputs.nvf.nixosModules.default # import module that provides nvf options
      ];

    nix.settings.experimental-features = [ "nix-command" "flakes" ];

    # Bootloader.
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    networking = {
      hostName = "nixos"; # Define your hostname.

      # Enable networking
      networkmanager = {
        enable = true;
        wifi.macAddress = "54:e1:ad:9f:d7:54";
      };

      firewall.allowedUDPPorts = [ 51822 ];

      wireguard.interfaces.wg1 = {
        ips = [ "10.0.1.3/32" ];
        privateKeyFile = "/etc/wireguard/private.key";
        listenPort = 51822;
        peers = [
          {
            # remote settings for hetzner vps, the VPN "hub"
            publicKey = "37xR0foIbAyLGna9/dfpvWIpJxQ5wno3RhQj9ZkjAEM=";
            allowedIPs = [ "10.0.1.0/24" ];
            endpoint = "5.78.208.9:51821";
          }
        ];
      };
    };

    # enable bolt, so thunderbolt can connect to usb hub
    services.hardware.bolt.enable = true;

    # Set your time zone.
    time.timeZone = "America/New_York";

    # Select internationalisation properties.
    i18n.defaultLocale = "en_US.UTF-8";

    i18n.extraLocaleSettings = {
      LC_ADDRESS = "en_US.UTF-8";
      LC_IDENTIFICATION = "en_US.UTF-8";
      LC_MEASUREMENT = "en_US.UTF-8";
      LC_MONETARY = "en_US.UTF-8";
      LC_NAME = "en_US.UTF-8";
      LC_NUMERIC = "en_US.UTF-8";
      LC_PAPER = "en_US.UTF-8";
      LC_TELEPHONE = "en_US.UTF-8";
      LC_TIME = "en_US.UTF-8";
    };

    # Define a user account. Don't forget to set a password with ‘passwd’.
    users.users.wilson = {
      isNormalUser = true;
      description = "wilson";
      extraGroups = [ "networkmanager" "wheel" "video" "input" ];
      packages = with pkgs; [];
    };

    # Allow unfree packages
    nixpkgs.config.allowUnfree = true;

    # List packages installed in system profile. To search, run:
    # $ nix search wget
    environment.systemPackages = with pkgs; [
      btop
      git
      fastfetch
    ];

    hardware = {
      enableAllFirmware = true;
      bluetooth = {
        enable = true;
        powerOnBoot = true;
        settings = {
          General = {
            Experimental = true;
            FastConnectable = true;
          };
          Policy = {
            AutoEnable = true;
          };
        };
      };
    };

    # battery conservation settings
    services.tlp = {
      enable = true;
      settings = {
        START_CHARGE_THRESHOLD_BAT0 = 75;
        STOP_CHARGE_THRESHOLD_BAT0 = 80;
      };
    };


    # Enable the OpenSSH daemon.
    services.openssh = {
      enable = true;
      ports = [ 22 ];
      settings = {
        PasswordAuthentication = true;
        PermitRootLogin = "prohibit-password";
      };
    };

    programs.ssh = {
      extraConfig = ''
        Host vps
          HostName 5.78.208.9
          User wilson

        Host thinkstation
          HostName 10.0.1.2
          user wilson
          ProxyJump vps
      '';
    };

    system.stateVersion = "25.11"; # Did you read the comment?
  };
}
