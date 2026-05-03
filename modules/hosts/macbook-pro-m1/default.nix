{ self, inputs, config, ... }: {
  flake.darwinConfigurations.macbookProM1 = inputs.nix-darwin.lib.darwinSystem {
    system = "aarch64-darwin";
    modules = [ 
      config.flake.modules.darwin.macbookProM1Configuration
    ];
  };
}
