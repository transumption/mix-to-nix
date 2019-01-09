{ pkgs ? import ../pkgs.nix }: with pkgs;

let
  mixToNix = callPackage ../. {};
in

[
  (mixToNix (_: { src = ../elixir-to-json; })) # 00-bootstrap
  (mixToNix (_: { src = ./01-poison; }))
  (mixToNix (_: {
    src = ./02-fast-yaml;
    buildInputs = [ libyaml ];
  }))
]
