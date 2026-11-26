# System settings common to nix-darwin and NixOS. The OS modules import the
# Home Manager and agenix modules and set home-manager.users.
{
  self,
  inputs,
  machine,
  username,
  homeDirectory,
  ...
}:
{
  nixpkgs.config.allowUnfree = true;

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    trusted-users = [ username ];
  };
  nix.optimise.automatic = true;
  nix.gc = {
    automatic = true;
    options = "--delete-older-than 30d";
  };

  programs.zsh.enable = true;

  # Home Manager runs as a system module on every machine
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    # Existing files like ~/.zshrc are moved aside instead of failing activation
    backupFileExtension = "before-nix";
    # The system-level specialArgs. Listed explicitly: passing
    # config._module.specialArgs would override Home Manager's modulesPath.
    extraSpecialArgs = {
      inherit
        self
        inputs
        machine
        username
        homeDirectory
        ;
    };
    # age.* options for user-level secrets
    sharedModules = [ inputs.agenix.homeManagerModules.default ];
  };
}
