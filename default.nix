{ stdenv, fetchurl, fetchzip, runCommand, beamPackages, glibcLocales
, python3Packages, writeShellScriptBin, writeText }:

with stdenv.lib;

let
  mixSourceFilter = name: type:
    let
      baseName = baseNameOf name;
    in
    !(type == "directory" && (baseName == "_build" || baseName == "deps"));

  inherit (builtins) path pathExists readFile toJSON typeOf;

  cleanSrc = src:
    if typeOf src == "path" then
      path {
        name = "source";
        path = src;
        filter = name: type:
          cleanSourceFilter name type &&
          mixSourceFilter name type;
      }
    else src;

  LANG = "en_US.UTF-8";
  LOCALE_ARCHIVE = optionalString stdenv.isLinux
    "${glibcLocales}/lib/locale/locale-archive";

  buildErlangMk = drv: makeOverridable beamPackages.buildErlangMk ({
    nativeBuildInputs = [ fakeGit ];
    prePatch = ''
      substituteInPlace Makefile \
        --replace /bin/bash ${stdenv.shell}
    '';

    buildTools = [ "make" ];
  } // drv);

  buildMix = drv: makeOverridable beamPackages.buildMix ({
    nativeBuildInputs = [ fakeGit ];
    buildTools = [ "mix" ];

    checkPhase = ''
      runHook preCheck

      mix do deps.loadpaths --no-deps-check, test

      runHook postCheck
    '';

    inherit LANG LOCALE_ARCHIVE;
  } // drv);

  buildRebar3 = drv: makeOverridable beamPackages.buildRebar3 ({
    nativeBuildInputs = [ fakeGit ];
    buildTools = [ "rebar3" ];
  } // drv);

  jason = buildMix rec {
    name = "jason";
    version = "1.1.2";

    src = fetchzip {
      url = "https://github.com/michalmuskala/jason/archive/v${version}.tar.gz";
      sha256 = "0fh87vrfqsyiaazsangsg992i1azad8cmzyzvg7fdm9z6b3v7lm0";
    };
  };

  inherit (beamPackages) elixir erlang hex;

  elixir-to-json = buildMix rec {
    name = "elixir_to_json";
    version = "0.0.0";

    src = ./elixir-to-json;
    beamDeps = [ jason ];
    buildInputs = [ erlang ];

    postBuild = ''
      mix escript.build --no-deps-check
    '';

    installPhase = "install -Dt $out/bin ${name}";
  };

  fake-hex-registry = buildMix rec {
    name = "fake_hex_registry";
    version = "0.0.0";

    src = ./fake-hex-registry;
    beamDeps = [ jason ];
    buildInputs = [ erlang ];

    postBuild = ''
      mix escript.build --no-deps-check
    '';

    installPhase = "install -Dt $out/bin ${name}";
  };

  fakeHexRegistry = args:
    let
      json = writeText "registry.json" (toJSON args);
    in
    runCommand "registry" { inherit LANG LOCALE_ARCHIVE; } ''
      ${fake-hex-registry}/bin/fake_hex_registry $out < ${json}
    '';

  beamDeps = drv: (drv.beamDeps or []) ++ (drv.buildPlugins or []);

  fakeHexPackage = drv: [{
    name = drv.pname;
    inherit (drv) version;

    sha256 = "0000000000000000000000000000000000000000000000000000000000000000";

    deps = map (dep: { name = dep.pname; inherit (dep) version; }) (beamDeps drv);
    tools = drv.buildTools;
  }] ++ concatMap fakeHexPackage (beamDeps drv);

  isRebar3 = drv: drv.buildTools == [ "rebar3" ];

  fakeGit = writeShellScriptBin "git" ''
    echo 0000000000000000000000000000000000000000
  '';

  fakeHexOverrideImpl = prev: next:
    if isRebar3 prev then
      let
        registry = fakeHexRegistry (unique (concatMap fakeHexPackage (beamDeps next)));
      in
      prev.override {
        nativeBuildInputs = (prev.nativeBuildInputs or []) ++ [ fakeGit ];

        preConfigure = (prev.preConfigure or "") + ''
          export HEX_REGISTRY_SNAPSHOT=${registry}
        '';
      }
    else prev;

  fakeHexOverride = final: name: prev:
    fakeHexOverrideImpl prev (getAttr name final);

  binwalk = python3Packages.binwalk.override {
    pyqtgraph = null;
  };

  fetchHex = { pname, version, sha256 }: stdenv.mkDerivation {
    inherit pname version;
    name = "hex-${pname}-${version}";

    src = fetchurl {
      name = "${pname}-${version}.mix";
      url = "https://repo.hex.pm/tarballs/${pname}-${version}.tar";
      inherit sha256;

      postFetch = ''
        tar -xf $downloadedFile
        cat VERSION metadata.config contents.tar.gz > $out
      '';
    };

    HOME = ".";

    nativeBuildInputs = [ binwalk ];

    unpackPhase = ''
      binwalk --include compress --extract $src
    '';

    installPhase = ''
      mkdir $out
      echo ${pname},${version},${sha256},hexpm > $out/.hex
      tar xf *.extracted/* -C $out
    '';
  };

  lockSubDeps = self: subdeps:
    remove null (map (subdep: self."${head subdep}" or null) subdeps);

  lockDep = self: pname: dep:
    let
      scm = head dep;
    in
    if scm == "hex" then
      let
        buildTools = elemAt dep 4;
        buildPackage =
          if elem "rebar3" buildTools then buildRebar3
          else if elem "rebar" buildTools then buildRebar3
          else if elem "mix" buildTools then buildMix
          else if elem "make" buildTools then buildErlangMk
          else throw "unsupported build tools: ${concatStringsSep ", " buildTools}";
      in
      buildPackage rec {
        inherit (src) pname version;
        name = src.pname;
        inherit scm;

        src = fetchHex {
          pname = elemAt dep 1;
          version = elemAt dep 2;
          sha256 = elemAt dep 3;
        };

        beamDeps = lockSubDeps self (elemAt dep 5);
      }
    else if scm == "git" then
      let
        src = fetchGit {
          url = elemAt dep 1;
          rev = elemAt dep 2;
        };

        stripContext = text: readFile (runCommand "string-without-context" {} ''
          echo -n "${text}" > $out
        '');

        buildPackage =
          if pathExists "${stripContext src}/mix.lock" then buildMix
          else if pathExists "${stripContext src}/rebar.lock" then buildRebar3
          else if pathExists "${stripContext src}/erlang.mk" then buildErlangMk
          else throw "can't identify git dep build system: ${src}";
      in
      buildPackage {
        name = pname;
        version = src.rev;
        inherit scm src;

        beamDeps = filter (drv: drv.scm != "git") (attrValues self);
      }
    else throw "unsupported SCM: ${scm}";

  elixirToJSON = path:
    runCommand "elixir-term.json" { inherit LANG LOCALE_ARCHIVE; } ''
      ${elixir-to-json}/bin/elixir_to_json < ${path} > $out
    '';

  importElixir = path: importJSON (elixirToJSON path);

  evalMixConfig = src: runCommand "mix-config.exs" {
    nativeBuildInputs = [ elixir fakeGit hex ];

    inherit LANG LOCALE_ARCHIVE;
    MIX_EXS = "${src}/mix.exs";
  } ''
    mix run --no-compile --no-deps-check --no-start \
      --eval 'IO.puts inspect(Map.new(Mix.Project.config))' > $out
  '';
in

{
  inherit mixSourceFilter;

  mixToNix = { overlay ? _: _: {}, src }:
    let
      cleanedSrc = cleanSrc src;
      mixConfig = importElixir (evalMixConfig src);

      registryOverlay = final: previous: mapAttrs (fakeHexOverride final) previous;

      superClosure = mapAttrs
        (lockDep finalClosure)
        (importElixir "${cleanedSrc}/mix.lock");

      finalClosure = superClosure
        // (composeExtensions overlay registryOverlay) finalClosure superClosure;
    in
    buildMix {
      name = mixConfig.app;
      version = mixConfig.version;

      src = cleanedSrc;
      beamDeps = attrValues finalClosure;
      doCheck = true;

      installPhase = ''
        runHook preInstall

        cp -r $PWD $out
        cd $out
        ln -s _build/prod/lib deps

        runHook postInstall
      '';
    };
}
