{ self, inputs, ... }: {
  flake.nixosModules.obs = { pkgs, config, ... }: {
    programs.obs-studio = {
      enable = true;

      plugins = with pkgs.obs-studio-plugins; [
      ];
      
      enableVirtualCamera = true;
    };
  };
}
