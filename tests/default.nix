{ pkgs ? import ../pkgs.nix }: with pkgs;

let
  mixToNix = callPackage ../. {};
in

[
  (mixToNix { src = ../elixir-to-json; }) # 00-bootstrap
]
