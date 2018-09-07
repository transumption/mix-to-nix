with import <nixpkgs> {};

let
  project = callPackage ./project.nix {
    src = lib.cleanSource ./.;
  };
in

project.overrideAttrs (super: {
  buildInputs = super.buildInputs ++ [ erlangR19 ];
  postBuild = "mix escript.build";
  installPhase = "install -Dt $out/bin mix2nix";
})
