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

    zk = {
      url = "path:/Users/mlabrecque/Development/zk";
      flake = false;
    };

    # VPS and homelab: stable
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-26.05";

    home-manager-stable = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };

    disko = {
      url = "github:nix-community/disko";
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
      home-manager,
      nixpkgs-stable,
      home-manager-stable,
      agenix,
      ...
    }:
    let
      # Home Manager runs as a system module on every machine. Both layers
      # receive the same specialArgs.
      homeManagerConfig = specialArgs: homeModule: {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          # Existing files like ~/.zshrc are moved aside instead of failing activation
          backupFileExtension = "before-nix";
          extraSpecialArgs = specialArgs;
          # age.* options for user-level secrets on every machine
          sharedModules = [ agenix.homeManagerModules.default ];
          users.${specialArgs.username} = import homeModule;
        };
      };

      # machine: flake output name; also selects machines/<machine>.nix
      mkDarwin =
        machine:
        let
          # macOS account name (short name) and its home folder differ, so
          # the home folder is set explicitly rather than derived.
          username = "mlabrecqu";
          homeDirectory = "/Users/mlabrecque";
          specialArgs = {
            inherit
              self
              inputs
              machine
              username
              homeDirectory
              ;
            # Absolute path to this checkout. Used for out-of-store symlinks
            # (e.g. nvim, so vim.pack can write its lockfile back into the repo).
            configDir = "${homeDirectory}/Development/nix-config";
          };
        in
        nix-darwin.lib.darwinSystem {
          inherit specialArgs;
          modules = [
            ./modules/shared
            ./modules/darwin
            ./machines/${machine}.nix
            agenix.darwinModules.default
            home-manager.darwinModules.home-manager
            (homeManagerConfig specialArgs ./home/darwin)
          ];
        };

      mkNixos =
        machine:
        let
          username = "mlabrecque";
          specialArgs = {
            inherit
              self
              inputs
              machine
              username
              ;
            homeDirectory = "/home/${username}";
          };
        in
        nixpkgs-stable.lib.nixosSystem {
          inherit specialArgs;
          modules = [
            ./modules/shared
            ./modules/linux
            ./machines/${machine}.nix
            agenix.nixosModules.default
            home-manager-stable.nixosModules.home-manager
            (homeManagerConfig specialArgs ./home/shared)
          ];
        };
    in
    {
      darwinConfigurations = {
        macbook-air = mkDarwin "macbook-air";
      };

      nixosConfigurations = {
        homelab = mkNixos "homelab";
      };

      formatter = {
        aarch64-darwin = nixpkgs.legacyPackages.aarch64-darwin.nixfmt-tree;
        x86_64-linux = nixpkgs-stable.legacyPackages.x86_64-linux.nixfmt-tree;
      };

      checks = {
        aarch64-darwin = {
          macbook-air = self.darwinConfigurations.macbook-air.config.system.build.toplevel;
        };
        x86_64-linux.ovh-vps = self.nixosConfigurations.ovh-vps.config.system.build.toplevel;
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
