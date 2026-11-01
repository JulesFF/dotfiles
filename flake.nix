{
  description = "My dotfiles as a Home Manager module ";

  outputs = { self, ... }: {
    homeModules.default = ./home.nix;
  };
}
