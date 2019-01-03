{ stdenv, fetchurl, fetchzip, runCommand, elixir, erlang, glibcLocales
, python3Packages, rebar, rebar3 }: { src }:

with stdenv.lib;

let
  hex = fetchurl {
    url = "https://repo.hex.pm/installs/1.6.0/hex-0.18.1.ez";
    sha512 = "9c806664a3341930df4528be38b0da216a31994830c4437246555fe3027c047e073415bcb1b6557a28549e12b0c986142f5e3485825a66033f67302e87520119";
  };

  linkDep = name: src: ''
    cp -rs --no-preserve=mode ${src} deps/${name}

    mkdir deps/${name}/.git
    touch deps/${name}/.git/HEAD

  '';

  buildMixProject = src: deps: stdenv.mkDerivation {
    name = "mix-project";
    inherit src;

    nativeBuildInputs = [ elixir erlang rebar rebar3 ];

    configurePhase = ''
      runHook preConfigure

      mkdir deps
      ${concatStrings (mapAttrsToList linkDep deps)}

      runHook postConfigure
    '';

    HOME = ".";
    LANG = "en_US.UTF-8";

    LOCALE_ARCHIVE = optionalString stdenv.isLinux
      "${glibcLocales}/lib/locale/locale-archive";

    MIX_ENV = "prod";
    MIX_REBAR = "${rebar}/bin/rebar";
    MIX_REBAR3 = "${rebar3}/bin/rebar3";

    buildPhase = ''
      runHook preBuild

      mix archive.install --force ${hex}
      mix deps.compile --force
      mix compile --no-deps-check

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      mkdir $out
      mv .mix * $out

      runHook postInstall
    '';
  };

  elixir-to-json = (buildMixProject ./elixir-to-json {
    jason = fetchzip {
      url = https://github.com/michalmuskala/jason/archive/v1.1.2.tar.gz;
      sha256 = "0fh87vrfqsyiaazsangsg992i1azad8cmzyzvg7fdm9z6b3v7lm0";
    };
  }).overrideAttrs (super: {
    postBuild = ''
      mix escript.build --no-deps-check
    '';

    installPhase = "install -Dt $out/bin elixir_to_json";
  });

  elixirToJSON = path: runCommand "elixir.json" {} ''
    ${elixir-to-json}/bin/elixir_to_json < ${path} > $out
  '';

  importElixir = path: importJSON (elixirToJSON path);

  binwalk = python3Packages.binwalk.override {
    pyqtgraph = null;
  };

  fetchHex = { pname, version, sha256 }: stdenv.mkDerivation {
    name = "${pname}-${version}-hexpm";

    src = fetchurl {
      name = "${pname}-${version}.mix";
      url = "https://repo.hex.pm/tarballs/${pname}-${version}.tar";
      inherit sha256;

      postFetch = ''
        tar -xf $downloadedFile
        cat VERSION metadata.config contents.tar.gz > $out
      '';
    };

    nativeBuildInputs = [ binwalk ];

    unpackPhase = ''
      HOME=. binwalk --extract $src
    '';

    installPhase = ''
      mkdir $out
      echo ${pname},${version},${sha256},hexpm > $out/.hex
      tar xf *.extracted/* -C $out
    '';
  };

  lockDep = dep:
    let
      kind = head dep;
    in
    if kind == "hex" then
      fetchHex {
        pname = elemAt dep 1;
        version = elemAt dep 2;
        sha256 = elemAt dep 3;
      }
    else if kind == "git" then
      fetchGit {
        url = elemAt dep 1;
        rev = elemAt dep 2;
      }
    else nil;

  lockDeps = mapAttrs (const lockDep);
in

buildMixProject src (lockDeps (importElixir "${src}/mix.lock"))
