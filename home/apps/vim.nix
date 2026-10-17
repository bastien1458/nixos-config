# Neovim as a cyberdeck interface: the live OS palette (recoloured the moment
# the OS or the wallpaper changes), a netrunner statusline, a quickhack start
# screen and pickers. The Lua lives in ./nvim, deployed as lua/cyberdeck.
{
  pkgs,
  lib,
  dotfiles,
  ...
}:
let
  theme = import ../../theme { inherit pkgs lib; };

  # grammars this config is written in; missing ones are skipped, not fatal
  grammars = [
    "nix"
    "lua"
    "bash"
    "python"
    "qmljs"
    "javascript"
    "json"
    "kdl"
    "toml"
    "yaml"
    "css"
    "markdown"
    "markdown_inline"
    "vim"
    "vimdoc"
    "regex"
  ];
in
{
  # the colours come from the live palette instead (see nvim/theme.lua)
  stylix.targets.neovim.enable = false;

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    withRuby = false;
    withPython3 = false;

    plugins = with pkgs.vimPlugins; [
      mini-nvim
      (nvim-treesitter.withPlugins (p: map (name: p.${name}) (lib.filter (name: p ? ${name}) grammars)))
    ];

    # language servers and the search tools behind the pickers
    extraPackages = with pkgs; [
      nixd
      nixfmt
      lua-language-server
      kdePackages.qtdeclarative
      ripgrep
      fd
    ];

    initLua = ''
      -- engraved palette, used until cyberdeck-theme has written the live one
      vim.g.cyberdeck_fallback = vim.json.decode([==[${builtins.toJSON theme.palette}]==])
      vim.g.cyberdeck_dotfiles = "${dotfiles}"
      require("cyberdeck")
    '';
  };

  xdg.configFile."nvim/lua/cyberdeck".source = ./nvim;
}
