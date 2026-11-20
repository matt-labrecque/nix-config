{
  description = "Julia dev shell";

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
          packages = with pkgs; [
            # Official Julia binary: building from source fails the bundled OpenBLAS
            # self-test on aarch64-darwin, and julia-bin's own test suite is too slow.
            (pkgs.julia-bin.overrideAttrs (_: {
              doInstallCheck = false;
            }))
          ];

          shellHook = ''
            echo "Julia $(julia --version)"
          '';
        };
      });
    };
}
