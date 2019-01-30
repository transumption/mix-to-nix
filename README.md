## Overview

Nix function that reads `mix.lock` file and builds a Mix project.
Works inside the Nix sandbox.

To try it out, create the following `default.nix` in your Mix project:

```nix
with import <nixpkgs> {};

let
  inherit (callPackage (fetchGit {
    url = https://gitlab.com/transumption/mix-to-nix;
    rev = "69b74f9e18582595284dd8f13aaaaafa68eb97c0";
  }) {}) mixToNix;
in

mixToNix { src = ./.; }
```

Run `nix-build`.

### OTP apps

To start an OTP app, run:

```
$ cd result
$ MIX_ENV=prod \
  mix run -c /path/to/config.exs --no-deps-check --no-halt
```

### Escripts

To build an escript, override `postBuild` and `installPhase`:

```nix
(mixToNix { src = ./.; }).overrideAttrs (super: {
  postBuild = ''
    mix escript.build --no-deps-check
  '';

  installPhase = "install -Dt $out/bin ${super.pname}";
})
```

### Distillery

```nix
(mixToNix { src = ./.; }).overrideAttrs (super: {
  buildPhase = ''
    mix do deps.loadpaths --no-deps-check, release --env=prod
  '';
  
  installPhase = ''
    mkdir $out
    find _build -name \*.tar.gz | xargs cat | tar zxf - -C $out
  '';
})
```

## Details

If `src` is a path, it is filtered against `lib.cleanSource`, `_build/`, and
`deps/`.

[`elixir-to-json`](elixir-to-json) evaluates Elixir term in `mix.lock` and
marshals it to JSON. Tuples are represented as lists.

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

Mix, Rebar3 and ErlangMk deps are supported.

[`fake-hex-registry`](fake-hex-registry) creates a fake [Hex v1
registry](https://git.io/fhZuz) with dependencies for Rebar3 projects. [Rebar3
needs registry to function](https://github.com/erlang/rebar3/issues/1267).

Every dependency is built and cached individually via Nixpkgs `buildMix`
and `buildRebar3`.

## Quirks

`:git` dependencies are flat, so they are assumed to depend on every non-Git
entry in `mix.lock`. If this is undesirable, or if you want to make Git deps
depend on each other, you can override `beamDeps` via `overlay`.

If you have dependencies that require Rebar3 plugins (such as `pc` or
`rebar3_hex`), add them to `mix.exs` deps. These are normally unpinned and
non-sandboxable. You will also need to set `buildPlugins` via `overlay`. See
[`tests/02-fast-yaml`](tests/default.nix#L19) for example.
