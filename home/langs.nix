{ pkgs, ... }:

{
  home.packages = with pkgs; [
    go
    rustup
    llvm
    nodejs_22
    typst
    zig
    python313

    # Build and language-specific tooling.
    cmake
    gnumake
    just
    uv
    platformio-core
  ];
}
