{
  description = "Matt Labrecque's Monorepo for Nix Configurations'";

  inputs = {
    # Macs: unstable
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    omp = {
      url = "github:can1357/oh-my-pi";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Homelab: stable
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-26.05";

    home-manager-stable = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      nix-darwin,
      nixpkgs-stable,
      ...
    }:
    {
      darwinConfigurations = {
        macbook-air = nix-darwin.lib.darwinSystem {
          specialArgs = {
            inherit self inputs;
            # Flake output name; the `rebuild` alias needs it because the
            # hostname (MattBook) differs.
            machine = "macbook-air";
            # macOS account name (short name) and its home folder differ, so
            # the home folder is set explicitly rather than derived.
            username = "mlabrecqu";
            homeDirectory = "/Users/mlabrecque";
            # Absolute path to this checkout. Used for out-of-store symlinks
            # (e.g. nvim, so vim.pack can write its lockfile back into the repo).
            configDir = "/Users/mlabrecque/Development/nix-config";
          };
          modules = [
            ./modules/shared
            ./modules/darwin
            ./machines/macbook-air.nix
          ];
        };
      };

      nixosConfigurations = {
        homelab = nixpkgs-stable.lib.nixosSystem {
          specialArgs = {
            inherit self inputs;
            machine = "homelab";
            username = "mlabrecque";
            homeDirectory = "/home/mlabrecque";
          };
          modules = [
            ./modules/shared
            ./modules/linux
            ./machines/homelab.nix
          ];
        };
      };

      formatter = {
        aarch64-darwin = nixpkgs.legacyPackages.aarch64-darwin.nixfmt-tree;
        x86_64-linux = nixpkgs-stable.legacyPackages.x86_64-linux.nixfmt-tree;
      };

      checks = {
        aarch64-darwin = {
          macbook-air = self.darwinConfigurations.macbook-air.config.system.build.toplevel;
        };
        x86_64-linux.homelab = self.nixosConfigurations.homelab.config.system.build.toplevel;
      };

      # Per-project dev shells; scaffold with `nix-init <lang>` (home/darwin/nix-init.nix)
      templates = {
        rust = {
          path = ./templates/rust;
          description = "Rust toolchain from rust-toolchain.toml via rust-overlay";
        };
        python = {
          path = ./templates/python;
          description = "Python with uv managing dependencies, Ruff is also installed for LSP";
        };
        node = {
          path = ./templates/node;
          description = "Node.js with bun";
        };
        go = {
          path = ./templates/go;
          description = "Go with gopls, gotools and delve";
        };
        julia = {
          path = ./templates/julia;
          description = "Julia from the official binary (julia-bin)";
        };
        c = {
          path = ./templates/c;
          description = "GCC for compiling and running C/C++ programs";
        };

        zig = {
          path = ./templates/zig;
          description = "Zig from Nix unstable";
        };
      };
    };
}
