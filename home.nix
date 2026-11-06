{ config, lib, pkgs, ... }:

let
  cfg = config.dotfiles;

  # The repo's nvim/ and zsh/ files: linked straight to a local clone
  # when dotfiles.checkout is set (edits apply without a switch), else
  # copied into the store with the rest of the configuration.
  source = path:
    if cfg.checkout == null
    then ./. + "/${path}"
    else config.lib.file.mkOutOfStoreSymlink "${cfg.checkout}/${path}";
in
{
  options.dotfiles.checkout = lib.mkOption {
    type = lib.types.nullOr lib.types.str;
    default = null;
    example = "/home/jules/dotfiles";
    description = ''
      Absolute path to a local clone of this repo. When set, ~/.config/nvim
      and the zsh config link to the files there instead of a store copy.
      Leave unset on machines without a clone (servers).
    '';
  };

  config = {
    home.username = lib.mkDefault "jules";
    home.homeDirectory = lib.mkDefault (
      if pkgs.stdenv.isDarwin then "/Users/jules" else "/home/jules"
    );
    home.stateVersion = "26.05";

    # Language servers tied to a language (gopls, clangd, tinymist) come
    # from each project's devShell, loaded by direnv, so they match the
    # project's toolchain. Only editor-wide tools live here.
    home.packages = with pkgs; [
      bat
      delta
      fd
      fzf
      glab
      jq
      neovim
      ripgrep
      tree
      zoxide
    ];

    # Installers and other tools that drop binaries here (install.sh, claude).
    home.sessionPath = [ "$HOME/.local/bin" ];

    xdg.dataFile = {
      "nvim/site/pack/dotfiles/start/fzf-lua".source = pkgs.vimPlugins.fzf-lua;
      "nvim/site/pack/dotfiles/start/nvim-tree".source = pkgs.vimPlugins.nvim-tree-lua;

      "zsh/zsh-autosuggestions".source = "${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions";
      "zsh/zsh-syntax-highlighting".source = "${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting";
      "zsh/zsh-completions/src".source = "${pkgs.zsh-completions}/share/zsh/site-functions";
      "zsh/omz-git/git.zsh".source = "${pkgs.oh-my-zsh}/share/oh-my-zsh/lib/git.zsh";
      "zsh/omz-git/git.plugin.zsh".source = "${pkgs.oh-my-zsh}/share/oh-my-zsh/plugins/git/git.plugin.zsh";
    };

    xdg.configFile."nvim".source = source "nvim";

    programs.zsh = {
      enable = true;
      initContent =
        if cfg.checkout == null
        then "source ${./zsh/dotfiles.zsh}"
        else ''source "${cfg.checkout}/zsh/dotfiles.zsh"'';
    };

    # cd into a project with an .envrc (`use flake`) loads its devShell
    # into this shell: its tools and language servers on PATH, your own
    # zsh and prompt kept. nix-direnv caches the shell between visits.
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
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
  };
}
