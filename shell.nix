with import <nixpkgs> {};

stdenvNoCC.mkDerivation {
  name = "mix2nix";
  buildInputs = [ elixir erlang ];
}
