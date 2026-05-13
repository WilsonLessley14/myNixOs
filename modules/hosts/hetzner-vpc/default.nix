{ self, inputs, ... }: {
  flake.nixosConfigurations.hetzner-vpc = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      self.nixosModules.vpcConfiguration
    ];
  };
}
