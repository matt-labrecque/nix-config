{
  description = "Python dev shell";

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
            python3
            ruff
            uv
            pyright
          ];

          # uv manages packages (uv.lock) but uses the pinned interpreter
          # instead of downloading its own
          env = {
            UV_PYTHON = "${pkgs.python3}/bin/python3";
            UV_PYTHON_DOWNLOADS = "never";
          };

          shellHook = ''
            [ -d .venv ] || uv venv --quiet
            source .venv/bin/activate
          '';
        };
      });
    };
}
