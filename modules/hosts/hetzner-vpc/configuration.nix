{ self, inputs, ... }: {
  flake.nixosModules.vpcConfiguration = { config, pkgs, ... }: {
    imports = [
      self.nixosModules.vpcHardware
      self.nixosModules.ghostty
      self.nixosModules.neovim
      self.nixosModules.nginx
      inputs.nvf.nixosModules.default
    ];

    nix.settings.experimental-features = [ "flakes" "nix-command" ];

    environment.systemPackages = with pkgs; [
      git
    ];
    
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

    networking.wireguard.interfaces.wg1 = {
      ips = [ "10.0.1.1/24" ];
      listenPort = 51821;
      privateKeyFile = "/etc/wireguard/private.key";
      peers = [{
        publicKey = "urVgKnvbWGnyrAihi2IROiK88BX/4YG2vFIGXGa1WSc=";
        allowedIPs = [ "10.0.1.2/32" ];
      }];
    };
    networking = {
      firewall = {
        allowedUDPPorts = [ 51821 ];
        allowedTCPPorts = [ 80 ];
      };
      hostName = "vps-1";
      domain = "";
    };

    # Workaround for https://github.com/NixOS/nix/issues/8502
    services.logrotate.checkConfig = false;

    boot.tmp.cleanOnBoot = true;
    zramSwap.enable = true;
    services.openssh.enable = true;
    users.users.root.openssh.authorizedKeys.keys = [''ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIeLEdYfYIu54pjyFta39azix0QHg3YgzsYiVJDf+fug'' ''ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILImCZrZJXzU3RkmuUNaq4Jo2nTE2oj0lfL8dAItP6aE'' ];
    system.stateVersion = "23.11";
    
  };
}
