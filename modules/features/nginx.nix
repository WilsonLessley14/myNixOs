{ self, inputs, ... }: {
  flake.nixosModules.nginx = { pkgs, config, ... }: {
    services.nginx = {
      enable = false;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;

    };
    security.acme = {
      acceptTerms = true;
      defaults.email = "wilsonlessley14@gmail.com";
      certs = {
        "wilsonlessley.com" = {
          group = config.services.nginx.group;
          domain = "*.wilsonlessley.com";
          dnsProvider = "cloudflare";
          environmentFile = "/etc/secrets/cloudflare";
        };
      };
    };

  };
}
