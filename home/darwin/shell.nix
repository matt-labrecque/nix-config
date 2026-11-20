{ configDir, machine, ... }:
{
  programs.zsh.shellAliases = {
    nrd = "npm run dev";
    cdzk = "cd $HOME/Documents/zettelkasten";
    cdd = "cd $HOME/Development";
    cdh = "cd $HOME/Homework";
    cdnix = "cd ${configDir}";
    # Output names don't match the hostnames, so the target is explicit
    rebuild = "sudo darwin-rebuild switch --flake ${configDir}#${machine}";
    vps-sync = "nix run nixpkgs#nixos-rebuild -- switch --flake .#ovh-vps --target-host root@15.204.249.152 --build-host root@15.204.249.152";
  };
}
