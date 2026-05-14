{self, inputs, ... }: {
  flake.nixosModules.p330Configuration = { config, pkgs, ... }: {
    imports =
      [ # Include the results of the hardware scan.
        self.nixosModules.p330Hardware
        self.nixosModules.neovim
        self.nixosModules.ghostty
        self.nixosModules.keyboard
        inputs.nvf.nixosModules.default
        self.nixosModules.jellyfin
      ];
    
    nix.settings.experimental-features = [ "nix-command" "flakes" ];

    # Bootloader.
    boot.loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };

    networking = {

      hostName = "wilsons-thinkstation"; # Define your hostname.

      interfaces.wlp3s0.ipv4.addresses = [{
        address = "10.67.77.253";
        prefixLength = 20;
      }];

      defaultGateway = {
        address = "10.67.64.1";
        interface = "wlp3s0";
      };

      nameservers = [ "8.8.8.8" ];

      # Enable networking
      networkmanager = {
        enable = true;
        wifi.macAddress = "permanent";
      };

      wireguard.interfaces.wg1 = {
        ips = [ "10.0.1.2/24" ];
        privateKeyFile = "/etc/wireguard/private.key";
        peers = [{
          publicKey = "37xR0foIbAyLGna9/dfpvWIpJxQ5wno3RhQj9ZkjAEM=";
          allowedIPs = [ "10.0.1.0/24" ];
          endpoint = "5.78.208.9:51821";
          persistentKeepalive = 25;
        }];
      };
    };

    # Set your time zone.
    time.timeZone = "America/New_York";

    # Select internationalisation properties.
    i18n = {
      defaultLocale = "en_US.UTF-8";

      extraLocaleSettings = {
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
    };

    # Define a user account. Don't forget to set a password with ‘passwd’.
    users.users.wilson = {
      isNormalUser = true;
      description = "wilson";
      extraGroups = [ "networkmanager" "wheel" "video" "input" ];
      packages = with pkgs; [];
      openssh.authorizedKeys.keys = [
        #m1 mac
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIeLEdYfYIu54pjyFta39azix0QHg3YgzsYiVJDf+fug wilsonlessley14@gmail.com"
        #t470
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILImCZrZJXzU3RkmuUNaq4Jo2nTE2oj0lfL8dAItP6aE wilsonlessley14@gmail.com"
      ];
    };

    # Allow unfree packages
    nixpkgs.config.allowUnfree = true;

    environment.systemPackages = with pkgs; [
       git
    ];

    # Enable the OpenSSH daemon.
    services = {
      openssh = {
        enable = true;
        settings = {
          PasswordAuthentication = false;
          PermitRootLogin = "no";
          KbdInteractiveAuthentication = false;
        };
      };
    };

    system.stateVersion = "25.11"; # Did you read the comment?
  };
}
