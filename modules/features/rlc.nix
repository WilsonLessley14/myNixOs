{ inputs, ... }:  {
  flake.nixosModules.rlc = {
    imports = [ inputs.rlc.nixosModules.default ];
    programs.rlc.enable = true;
  };
}
