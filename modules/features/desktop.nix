{ self, ... }: {
  flake.nixosModules.desktop = { pkgs, lib, ... }: {
    imports = [
      self.nixosModules.brave
    ];

    programs.niri.enable = true;

    services.greetd = {
      enable = true;
      settings = {
        default_session = {
	  command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd niri-session";
	  user = "greeter";
	};
	initial_session = {
          command = "niri-session";
	  user = "wilson";
	};
      };
    };

    xdg.portal = {
      enable = true;
      config.niri.default = lib.mkForce [ "wlr" "gtk" ];
      extraPortals = [
        pkgs.xdg-desktop-portal-gtk
        pkgs.xdg-desktop-portal-wlr
      ];
    };

    environment.sessionVariables = {
      NIXOS_OZONE_WL = "1";
      XDG_SESSION_TYPE = "wayland";
      XDG_CURRENT_DESKTOP = "niri";
    };

    services.dbus.enable = true;

  };
}
