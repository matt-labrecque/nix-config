{
  pkgs,
  inputs,
  configDir,
  ...
}:
let
  # `nix-init rust` scaffolds a project from templates/ and locks its
  # nixpkgs to the same revision as this system, so project shells reuse
  # what is already in the store instead of pulling a newer nixpkgs.
  nix-init = pkgs.writeShellApplication {
    name = "nix-init";
    text = ''
      if [[ $# -ne 1 ]]; then
        echo "usage: nix-init <go|julia|node|python|rust>" >&2
        exit 1
      fi
      nix flake init -t "${configDir}#$1"
      nix flake lock --override-input nixpkgs "github:NixOS/nixpkgs/${inputs.nixpkgs.rev}"
      ${pkgs.direnv}/bin/direnv allow
    '';
  };
in
{
  home.packages = [ nix-init ];
}
