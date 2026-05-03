{ self, inputs, config, ... }: let
  nvfConfig = { pkgs, ... }: {
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

          telescope.enable = true;
          autocomplete.nvim-cmp.enable = true;
          
          lsp.enable = true;
          languages = {
            enableTreesitter = true;

            nix.enable = true;
            rust.enable = true;
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

          opts = {
            tabstop = 2;
            shiftwidth = 2;
          };

          keymaps = [
            {
              key = "<leader>f";
              mode = "n";
              action = ":Telescope find_files<CR>";
            }
            {
              key = "<leader>/";
              mode = "n";
              action = ":Telescope live_grep<CR>";
            }
            {
              key = "<leader>b";
              mode = "n";
              action = ":Telescope buffers<CR>";
            }
          ];
        };
      };
    };
  };

in {
  flake.modules.nixos.neovim = nvfConfig;
  flake.modules.darwin.neovim = nvfConfig;
}
