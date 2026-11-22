# agenix recipients. Not imported by the flake; read by the `agenix` CLI.
# Add a secret:  cd secrets && agenix -e <name>.age
# Then declare it on a machine with `age.secrets.<name>.file = ../secrets/<name>.age;`.
# Machines decrypt with their SSH host key, so add each host's
# /etc/ssh/ssh_host_ed25519_key.pub below and to the secret's publicKeys.

# TODO: Write secrets for github, ssh into vps, etc.
let
  mlabrecque = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIeEZKXAJ0We9NYwQmC4fENGXcwio4B++M7iWWwkn2qD mheenan@Matts-MacBook-Air.local";
  users = [ mlabrecque ];
in
{
  "github-email.age".publicKeys = [ mlabrecque ];
}
