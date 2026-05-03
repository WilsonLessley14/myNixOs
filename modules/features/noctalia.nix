{ self, inputs, nixpkgs, ... }: {
  flake.packages.myNoctalia = 
    let pkgs = nixpkgs.legacyPackages."x86_64";
  in {
    inputs.wrapper-modules.wrappers.noctalia-shell.wrap = {
      inherit pkgs;
      settings = 
        (builtins.fromJSON
        (builtins.readFile ./noctalia.json)).settings;
    };
  };
}
