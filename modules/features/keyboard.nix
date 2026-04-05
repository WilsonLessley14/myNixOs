{ self, inputs, ... }: {
  flake.nixosModules.keyboard = { pkgs, config, ... }: {
    services.xserver = {
      xkb = {
        layout = "us";
        variant = "colemak";
      };
      xkbOptions = "caps:ctrl_modifier";
    };

    environment.variables = with config.services.xserver; {
      XKB_DEFAULT_LAYOUT = xkb.layout;
      XKB_DEFAULT_VARIANT = xkb.variant;
      XKB_DEFAULT_OPTIONS = xkbOptions;
    };

    console.useXkbConfig = true;
  };
}
