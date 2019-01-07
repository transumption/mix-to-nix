{ pkgs ? import ../pkgs.nix }: with pkgs;

let
  mixToNix = callPackage ../. {};
in

[
  (mixToNix { src = ../elixir-to-json; }) # 00-bootstrap
  (mixToNix { src = ./01-poison; })
  ((mixToNix { src = ./02-fast-yaml; }).overrideAttrs (super: {
    buildInputs = [ libyaml ];
  }))
]
