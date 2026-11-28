{
  description = "Astro site dev shell";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs =
    { nixpkgs, ... }:
    let
      systems = [
        "aarch64-darwin"
        "x86_64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          # Astro ships as a project dependency, not a nixpkgs package, so the
          # shell only provides the Node toolchain and bun to run it.
          packages = with pkgs; [
            nodejs_24
            bun
          ];

          shellHook = ''
            echo "Astro: scaffold with 'bun create astro .', then run 'bunx astro dev'"
          '';
        };
      });
    };
}
