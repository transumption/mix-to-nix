{ stdenv, fetchurl, fetchzip, runCommand, beam, elixir, erlang, glibcLocales
, python3Packages, rebar, rebar3 }: { src }:

with stdenv.lib;

let
  inherit (beam.packages.erlang) hex hexRegistrySnapshot;

  linkDep = name: src: ''
    cp -rs --no-preserve=mode ${src} deps/${name}

    mkdir -p deps/${name}/.git
    touch deps/${name}/.git/HEAD

    mkdir -p deps/${name}/_build/default
    ln -s ../../.. deps/${name}/_build/default/plugins
  '';

  buildMixProject = src: deps: stdenv.mkDerivation {
    name = "mix-project";
    inherit src;

    nativeBuildInputs = [
      elixir
      erlang
      hex
      rebar
      rebar3
    ];

    configurePhase = ''
      runHook preConfigure
      export HOME=$PWD

      mkdir -p .cache/rebar3/hex/default deps

      ln -s \
        ${hexRegistrySnapshot}/var/hex/registry.ets \
        .cache/rebar3/hex/default/registry

      ${concatStrings (mapAttrsToList linkDep deps)}

      runHook postConfigure
    '';

    LANG = "en_US.UTF-8";
    LOCALE_ARCHIVE = optionalString stdenv.isLinux
      "${glibcLocales}/lib/locale/locale-archive";

    MIX_ENV = "prod";
    MIX_REBAR = "${rebar}/bin/rebar";
    MIX_REBAR3 = "${rebar3}/bin/rebar3";

    buildPhase = ''
      runHook preBuild

      mix deps.compile --force
      mix compile --no-deps-check

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      mkdir $out
      mv .mix * $out || true

      runHook postInstall
    '';

    doCheck = true;

    checkPhase = ''
      runHook preCheck

      mix test --no-deps-check

      runHook postCheck
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
    inherit pname version;
    name = "${pname}-${version}";

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
