{self, inputs, ... }: {
flake.nixosModules.p330Configuration = { config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      self.nixosModules.p330Hardware
      self.nixosModules.neovim
      self.nixosModules.keyboard
      inputs.nvf.nixosModules.default
      self.nixosModules.jellyfin
    ];
  
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "wilsons-thinkstation"; # Define your hostname.

  networking = {

    interfaces.wlp3s0.ipv4.addresses = [{
      address = "10.67.77.253";
      prefixLength = 20;
    }];
    defaultGateway = {
      address = "10.67.64.1";
      interface = "wlp3s0";
    };
    nameservers = [ "8.8.8.8" ];
  };

  # Enable networking
  networking.networkmanager = {
      enable = true;
      wifi.macAddress = "permanent";
  };



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

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "colemak";
    options = "caps:ctrl_modifier";
  };

  environment.variables = with config.services.xserver; {
    XKB_DEFAULT_LAYOUT = xkb.layout;
    XKB_DEFAULT_VARIANT = xkb.variant;
    XKB_DEFAULT_OPTIONS = xkb.options;
  };

  console.useXkbConfig = true;

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
  #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
  #  wget
     git
     neovim
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
  services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?

};
}
