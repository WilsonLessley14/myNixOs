{ self, inputs, ... }: let
  agentHarnessConfig = { pkgs, ... }: {
    environment.systemPackages = with inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}; [
      pi
      claude-code
    ];
  };
in {
  
  flake.nixosModules.pi-agent = agentHarnessConfig;
  flake.modules.darwin.neocim = agentHarnessConfig;

}
