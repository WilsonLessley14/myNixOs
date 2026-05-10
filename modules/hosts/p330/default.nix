{ self, inputs, ... }: {
  flake.nixosConfigurations.p330 = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      self.nixosModules.p330Configuration
    ];
  };
}
