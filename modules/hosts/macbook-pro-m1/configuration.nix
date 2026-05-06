{ self, inputs, config, ... }: {
  flake.modules.darwin.macbookProM1Configuration = { pkgs, ... }: {
    imports = [
      self.modules.darwin.ghostty
      self.modules.darwin.neovim
      inputs.nvf.darwinModules.default # import module that provides nvf options
    ];

    # Necessary for using flakes on this system.
    nix.settings.experimental-features = "nix-command flakes";

    # Set Git commit hash for darwin-version.
    system.configurationRevision = self.rev or self.dirtyRev or null;

    # Used for backwards compatibility, please read the changelog before changing.
    # $ darwin-rebuild changelog
    system.stateVersion = 6;

    nixpkgs.hostPlatform = "aarch64-darwin";
  };
}
