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

  _04-pleroma = let
    # Fake config, required for compilation
    prodSecret = writeText "prod.secret.exs" ''
      use Mix.Config

      config :pleroma, Pleroma.Repo,
        adapter: Ecto.Adapters.Postgres
    '';
  in (mixToNix {
    src = stdenv.mkDerivation {
      name = "pleroma";
      src = fetchGit {
        url = https://git.pleroma.social/pleroma/pleroma;
        rev = "3879500c87829a5cf1377ca7ccdb7bf92c75367f";
      };

      buildCommand = ''
        cp --no-preserve=mode -r $src $out

        # Suppress runtime git invocation
        substituteInPlace $out/mix.exs \
          --replace 'version: version' 'version: to_string'

        # Fork with v1.4 as HEAD branch, see:
        # https://github.com/NixOS/nix/pull/2409
        substituteInPlace $out/mix.lock \
          --replace phoenixframework/phoenix yegortimoshenko/phoenix

        cp ${prodSecret} $out/config/prod.secret.exs
      '';
    };

    overlay = final: previous: {
      cowlib = previous.cowlib.overrideAttrs (super: {
        postPatch = ''
          substituteInPlace src/cow_multipart.erl \
            --replace crypto:rand_bytes crypto:strong_rand_bytes
        '';
      });
    };
  }).overrideAttrs (super: {
    doCheck = false;
  });
}
