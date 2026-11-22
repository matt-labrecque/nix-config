# TODO: Update symlink so it doesn't get overwritten
{ config, configDir, ... }:

let
  emailInclude = "${configDir}/secrets/github-email.age";
in
{
  age.identityPaths = [ "${config.home.homeDirectory}/.ssh/id_ed25519" ];

  age.secrets.github-email = {
    file = ../../secrets/github-email.age;
    path = emailInclude; # a symlink into the per-user temp dir
  };

  programs.git = {
    enable = true;
    settings.user = {
      name = "Matt Labrecque";
    };
    includes = [ { path = config.age.secrets.github-email.path; } ];
  };
}
