{ self, inputs, ... }: {
  flake.nixosModules.ghostty = { pkgs, ... }: let
    ghosttyConfig = pkgs.writeText "ghostty-config" ''
      font-size = 14
      window-decoration = false
      
      theme = Rose Pine Moon
      
      background-opacity = 0.8
      background-blur = true
    '';
  in {
    environment.systemPackages = [ pkgs.ghostty ];

    systemd.tmpfiles.rules = [
      "L+ /home/wilson/.config/ghostty/config - - - - ${ghosttyConfig}"
    ];
  };
}
