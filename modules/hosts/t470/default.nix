{ self, inputs, ... }: {
  flake.nixosConfigurations.t470 = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      self.nixosModules.t470Configuration
    ];
  };
}
