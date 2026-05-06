{ self, inputs, ... }: let
  configFile = ./ghostty-config;

  ghosttyNixOS = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.ghostty ];
    systemd.tmpfiles.rules = [
      "L+ /home/wilson/.config/ghostty/config - - - - ${configFile}"
    ];
  };

  ghosttyDarwin = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.ghostty-bin ];
    system.activationScripts.postActivation = {
      enable = true;
      text = ''
          mkdir -p /Users/wlessley/.config/ghostty
          ln -sf ${configFile} /Users/wlessley/.config/ghostty/config
        '';
    };
  };

in {

  flake.nixosModules.ghostty = ghosttyNixOS;
  flake.modules.darwin.ghostty = ghosttyDarwin;
}
