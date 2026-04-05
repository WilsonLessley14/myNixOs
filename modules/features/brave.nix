{ self, ... }: {

  flake.nixosModules.brave = { pkgs, ... }: {
    programs.chromium = {
      enable = true;
    };
    environment.systemPackages = [
      pkgs.brave
    ];
  };
}
