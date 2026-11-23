# Nix Configurations Monorepo

This monorepo serves as a single point of entry for my Nix configurations across
multiple systems:

| Machine | Flake output | OS | nixpkgs |
| --- | --- | --- | --- |
| MacBook Air (hostname `MattBook`) | `darwinConfigurations.macbook-air` | nix-darwin | `nixpkgs-unstable` |
| Mac mini | `darwinConfigurations.mac-mini` | nix-darwin | `nixpkgs-unstable` |
| VPS hosting Matrix through Tuwunel | `nixosConfigurations.ovh-vps` | NixOS | `nixos-26.05` |
| Homelab | `nixosConfigurations.homelab` | NixOS | `nixos-26.05` |


Home Manager runs as a nix-darwin/NixOS module on every machine, for user
`mlabrecqu` (home `/Users/mlabrecque`) on the Macs and `mlabrecque` on NixOS.
