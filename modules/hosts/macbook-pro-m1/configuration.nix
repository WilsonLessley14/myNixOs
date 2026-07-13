{ self, inputs, config, ... }: {
  flake.modules.darwin.macbookProM1Configuration = { pkgs, ... }: {
    imports = [
      self.modules.darwin.ghostty
      self.modules.darwin.neovim
      self.modules.darwin.agent-harness
      inputs.nvf.darwinModules.default # import module that provides nvf options
    ];

    agentHarness = {
      modelPath = "/Users/wlessley/Library/Application Support/llama-cpp/model.gguf";
      modelUrl = "https://huggingface.co/unsloth/gemma-4-31B-it-GGUF/resolve/main/gemma-4-31B-it-Q8_0.gguf";
    };

    # Necessary for using flakes on this system.
    nix.settings.experimental-features = "nix-command flakes";

    # Set Git commit hash for darwin-version.
    system.configurationRevision = self.rev or self.dirtyRev or null;

    # Used for backwards compatibility, please read the changelog before changing.
    # $ darwin-rebuild changelog
    system.stateVersion = 6;

    system.primaryUser = "wlessley";

    nixpkgs.hostPlatform = "aarch64-darwin";
  };
}
