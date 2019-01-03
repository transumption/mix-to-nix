{ stdenv, elixir, erlang, runCommand
, fetchurl, fetchzip, glibcLocales, python3Packages, rebar, rebar3 }: { src }:

let
  mix-to-nix = stdenv.mkDerivation {
    name = "mix-to-nix";
    src = stdenv.lib.cleanSource ./.;

    buildInputs = [ elixir erlang ];
    buildPhase = "mix escript.build";

    installPhase = "install -Dt $out/bin mix_to_nix";
  };

  mixToNix = src: runCommand "mix.nix" {} ''
    ${mix-to-nix}/bin/mix_to_nix ${src}/mix.lock > $out
  '';
in

(import (mixToNix src)) src {
  inherit stdenv elixir fetchurl fetchzip glibcLocales python3Packages rebar rebar3;
}
