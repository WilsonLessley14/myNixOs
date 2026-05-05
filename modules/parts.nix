{ inputs, lib, config, ... }: {
  imports = [
    inputs.flake-parts.flakeModules.modules
  ];

  options.perLinux = lib.mkOption {
    type = lib.types.deferredModule;
    default = {};
    description = "Like perSystem, but only evaluated for Linux systems.";
  };

  options.perDarwin = lib.mkOption {
    type = lib.types.deferredModule;
    default = {};
    description = "Like perSystem, but only evaluated for Darwin systems.";
  };

  config = {
    systems = [
      "x86_64-linux"
      "x86_64-darwin"
      "aarch64-linux"
      "aarch64-darwin"
    ];

    perSystem = { system, ... }: {
      imports =
        (lib.optional (lib.hasSuffix "-linux" system) config.perLinux) ++
        (lib.optional (lib.hasSuffix "-darwin" system) config.perDarwin);
    };
  };
}
