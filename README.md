# Nix Configurations Monorepo

This monorepo serves as a single point of entry for my Nix configurations across
multiple systems:

| Machine | Flake output | OS | nixpkgs |
| --- | --- | --- | --- |
| MacBook Air (hostname `MattBook`) | `darwinConfigurations.macbook-air` | nix-darwin | `nixpkgs-unstable` |
| Homelab | `nixosConfigurations.homelab` | NixOS | `nixos-26.05` |

While some people like using NixOS on a virtual machine on their Mac, I prefer
taking advantage of flakes and development shells to have project dependencies
be local to each project directory.
