{ config, ... }:
{
  age.identityPaths = [ "${config.home.homeDirectory}/.ssh/id_ed25519" ];

  age.secrets.github-email = {
    file = ../../secrets/github-email.age;
    path = "${config.home.homeDirectory}/.config/git/github-email";
    symlink = false;
  };

  programs.git = {
    enable = true;
    settings.user = {
      name = "Matt Labrecque";
    };
    includes = [ { path = config.age.secrets.github-email.path; } ];
  };
}
