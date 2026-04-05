{ self, inputs, ... }: {
  
  flake.nixosModules.pi-agent = { pkgs, ... }: {
    environment.systemPackages = with inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}; [
      pi
      claude-code
    ];

  };

}
