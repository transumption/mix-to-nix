{ stdenv, elixir, erlang, runCommand }: root:

let
  mix2nix = stdenv.mkDerivation {
    name = "mix2nix";
    src = ./.;

    buildInputs = [ elixir erlang ];
    buildPhase = "mix escript.build";

    installPhase = "install -Dt $out/bin mix2nix";
  };

  mixToNix = src: runCommand "mix.nix" {} ''
    ${mix2nix}/bin/mix2nix ${src}/mix.lock > $out
  '';
in

(import (mixToNix root)) root
