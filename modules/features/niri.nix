{ self, inputs, ... }: {

  flake.nixosModules.myNiri = { pkgs, lib, ... }: {
    programs.niri = {
      enable = true;
      package = self.packages.${pkgs.stdenv.hostPlatform.system}.myNiri;
    };
  };

  perSystem = { pkgs, lib, self', ... }: {

    packages.myNiri = inputs.wrapper-modules.wrappers.niri.wrap {
      inherit pkgs;
      settings = {
        spawn-at-startup = [
	  (lib.getExe self'.packages.myNoctalia)
	];

        input.keyboard = {
          xkb = {
            layout = "us";
	    variant = "colemak";
	  };
	};

	layout = {
	  gaps = 5;

	  focus-ring = {

	    width = 1.5;

	  };

	};

	window-rule = {
          geometry-corner-radius = 12;
	  clip-to-geometry = true;
	};

	binds = {
	 "Mod+S".spawn-sh =
	   "${lib.getExe self'.packages.myNoctalia} ipc call launcher toggle";
	 "Mod+Return".spawn-sh = lib.getExe pkgs.ghostty;
	 "Mod+B".spawn-sh = lib.getExe pkgs.brave;
	 "Ctrl+Q".close-window = _: {};

	 "Ctrl+L".focus-column-right-or-first = _: {};
	 "Ctrl+H".focus-column-left-or-last = _: {};
	 "Ctrl+K".focus-workspace-up = _: {};
	 "Ctrl+J".focus-workspace-down = _: {};

         "Ctrl+Shift+L".move-column-right = _: {};
	 "Ctrl+Shift+H".move-column-left = _: {};
	 "Ctrl+Shift+K".move-workspace-up = _: {};
	 "Ctrl+Shift+J".move-workspace-down = _: {};

         "Ctrl+D".toggle-window-floating = _: {};
	 "Ctrl+T".switch-focus-between-floating-and-tiling = _: {};

	 "Ctrl+Left".spawn-sh = "niri msg action move-floating-window -x -5";
	 "Ctrl+Right".spawn-sh = "niri msg action move-floating-window -x +5";
	 "Ctrl+Up".spawn-sh = "niri msg action move-floating-window -y -5";
	 "Ctrl+Down".spawn-sh = "niri msg action move-floating-window -y +5";

	 "Ctrl+Alt+Left".set-window-width = "-5%";
	 "Ctrl+Alt+Right".set-window-width = "+5%";
	 "Ctrl+Alt+Up".set-window-height = "+5%";
	 "Ctrl+Alt+Down".set-window-height = "-5%";
        };
      };
    };
  };

}
