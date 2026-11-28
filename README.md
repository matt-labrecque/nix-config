# Nix Configurations

This monorepo serves as the single point of entry for my Nix configurations for
both my homelab and laptop. The homelab is pinned to Nix26.05-stable while the
laptop is pinned to nixpkgs-unstable.

## Templates

`nix-init <lang>` scaffolds a dev shell from `templates/` and locks its nixpkgs
to the running system's revision.

| Template | Contents |
| --- | --- |
| `astro` | Astro site with the Node.js toolchain and bun |
| `c` | GCC/C++ with clangd |
| `go` | Go, gopls, gotools, and delve |
| `julia` | Julia from the official binary |
| `node` | Node.js and bun |
| `python` | Python with uv, Ruff, and pyright |
| `rust` | Rust toolchain from `rust-toolchain.toml` |
| `zig` | Zig |
