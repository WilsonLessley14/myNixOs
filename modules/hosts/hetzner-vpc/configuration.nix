{ self, inputs, ... }: {
flake.nixosModules.vpcConfiguration = { config, pkgs, ... }: {
  imports = [
    self.nixosModules.vpcHardware
    self.nixosModules.ghostty

  ];

  nix.settings.experimental-features = [ "flakes" "nix-command" ];

  environment.systemPackages = with pkgs; [
    git
    neovim
  ];

  networking.wireguard.interfaces.wg0 = {
    ips = [ "10.0.0.1/24" ];
    listenPort = 51820;
    privateKeyFile = "/etc/wireguard/private.key";
    peers = [{
      publicKey = "urVgKnvbWGnyrAihi2IROiK88BX/4YG2vFIGXGa1WSc=";
      allowedIPs = [ "10.0.0.2/32" ];
    }];
  };
  networking.firewall.allowedUDPPorts = [ 51820 ];

  # Workaround for https://github.com/NixOS/nix/issues/8502
  services.logrotate.checkConfig = false;

  boot.tmp.cleanOnBoot = true;
  zramSwap.enable = true;
  networking.hostName = "ubuntu-2gb-hil-1";
  networking.domain = "";
  services.openssh.enable = true;
  users.users.root.openssh.authorizedKeys.keys = [''ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIeLEdYfYIu54pjyFta39azix0QHg3YgzsYiVJDf+fug'' ''ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILImCZrZJXzU3RkmuUNaq4Jo2nTE2oj0lfL8dAItP6aE'' ];
  system.stateVersion = "23.11";
  
};
}
