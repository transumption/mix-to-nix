## Overview

Nix function that reads `mix.lock` file and builds a Mix project.
Works inside the Nix sandbox.

To try it out, create the following `default.nix` in your Mix project:

```nix
with import <nixpkgs> {};

let
  mixToNix = callPackage (fetchGit {
    url = https://gitlab.com/transumption/mix-to-nix;
    rev = "46eb30c8d371cad74e551fd05583674de79ad471";
  }) {};
in

mixToNix { src = lib.cleanSource ./.; }
```

Run `nix-build`.

### OTP apps

To start an OTP app, run:

```
$ cd result
$ MIX_ARCHIVES=$PWD/.mix/archives \
  MIX_ENV=prod \
  mix run -c /path/to/config.exs --no-halt
```

### Escripts

To build an escript, override `postBuild` and `installPhase`:

```nix
(mixToNix { src = lib.cleanSource ./.; }).overrideAttrs (super: {
  postBuild = ''
    mix escript.build --no-deps-check
  '';

  installPhase = "install -Dt $out/bin <name-here>";
});
```

### Distillery

```nix
(mixToNix { src = lib.cleanSource ./.; }).overrideAttrs (super: {
  buildPhase = ''
    mix release --env=prod
  '';
  
  installPhase = ''
    mkdir $out

    find _build -name \*.tar.gz | xargs cat | tar zxf - -C $out
  '';
})
```

## Implementation

First, [`elixir-to-json`](elixir-to-json) evaluates Elixir term in `mix.lock`
and marshals it to JSON. Tuples are represented as lists.

Then, Nix imports that JSON via `lib.importJSON`. Each `mix.lock` key
corresponds to a `deps/` path. Two types of deps are supported, `:git` and
`:hexpm`.

`:git` fetches given rev from `HEAD`. It doesn't support other branches just
yet, see [NixOS/nix#2409](https://github.com/NixOS/nix/pull/2409).

`:hexpm` fetches package from [Hex.pm](https://hex.pm). It comes with a SHA-256
hash of catenation of Mix archive version, package metadata, and `.tar.gz`
source code archive. Nix can only carry that catenation into the sandbox, so
[`binwalk`](https://github.com/ReFirmLabs/binwalk) finds where the source code
archive starts and extracts that part, ignoring archive version and metadata.
