{ self, inputs, ... }: {
  flake.nixosModules.neovim = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      neovim
    ];

    programs.nvf = {

      enable = true;

      settings = {
        vim = {
          viAlias = true;
	  vimAlias = true;

          statusline.lualine = {
            enable = true;

          };

          highlight = {
            Normal = {
              bg = "NONE";
              ctermbg = "NONE";
            };
            NoText = {
              bg = "NONE";
              ctermbg = "NONE";
            };

          };
        };
      };
    };
  };

}
