{ config, lib, pkgs, ... }:

{
  home.username = lib.mkDefault "jules";
  home.homeDirectory = lib.mkDefault "/home/jules";
  home.stateVersion = "26.05";

  home.packages = with pkgs; [
    bat
    clang-tools
    delta
    fd
    fzf
    glab
    gopls
    jq
    neovim
    ripgrep
    tree
    zoxide
  ];

  xdg.dataFile = {
    "nvim/site/pack/dotfiles/start/fzf-lua".source = pkgs.vimPlugins.fzf-lua;
    "nvim/site/pack/dotfiles/start/nvim-tree".source = pkgs.vimPlugins.nvim-tree-lua;

    "zsh/zsh-autosuggestions".source = "${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions";
    "zsh/zsh-syntax-highlighting".source = "${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting";
    "zsh/zsh-completions/src".source = "${pkgs.zsh-completions}/share/zsh/site-functions";
    "zsh/omz-git/git.zsh".source = "${pkgs.oh-my-zsh}/share/oh-my-zsh/lib/git.zsh";
    "zsh/omz-git/git.plugin.zsh".source = "${pkgs.oh-my-zsh}/share/oh-my-zsh/plugins/git/git.plugin.zsh";
  };

  xdg.configFile."nvim".source = ./nvim;

  programs.zsh = {
    enable = true;
    initContent = "source ${./zsh/dotfiles.zsh}";
  };

  programs.git = {
    enable = true;
    settings = {
      core.pager = "delta";
      interactive.diffFilter = "delta --color-only";
      delta.navigate = true;
    };
  };

  programs.home-manager.enable = true;
}
