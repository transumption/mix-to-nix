{ pkgs ? import ../pkgs.nix {} }: with pkgs;

let
  inherit (callPackage ../. {}) mixToNix;
in

# TODO: removing underscore in attr names below causes `nix-build` to stop
# enumerating the attrset. This is an upstream bug in Nix.

{
  _00-bootstrap = mixToNix {
    src = ../elixir-to-json;
  };

  _01-poison = mixToNix {
    src = ./01-poison;
  };

  _02-fast-yaml = mixToNix {
     src = ./02-fast-yaml;

     overlay = final: previous: with final; {
       fast_yaml = previous.fast_yaml.override {
         buildPlugins = [ pc rebar3_hex ];
       };

       p1_utils = previous.p1_utils.override {
         buildPlugins = [ rebar3_hex ];
       };
     };
  };

  _03-cowboy = mixToNix { src = ./03-cowboy; };
}
