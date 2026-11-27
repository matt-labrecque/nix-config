{ configDir, machine, ... }:
{
  programs.zsh.shellAliases = {
    nrd = "npm run dev";
    cdzk = "cd $HOME/Documents/zettelkasten";
    cdd = "cd $HOME/Development";
    cdh = "cd $HOME/Homework";
    cdnix = "cd ${configDir}";
    nixedit = "nvim ${configDir}";
    rebuild = "sudo darwin-rebuild switch --flake ${configDir}#${machine}";
  };
}
