{ self, inputs, ... }: {
  flake.nixosModules.neovim = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      neovim
    ];
  };

}
