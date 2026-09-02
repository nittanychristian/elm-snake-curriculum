{
  perSystem = {
    pkgs,
    lib,
    ...
  }: let
    elmApp = pkgs.stdenv.mkDerivation {
      pname = "elm-snake";
      version = "0.1.0";

      src = lib.fileset.toSource {
        root = ./..;
        fileset = lib.fileset.unions [
          ../elm.json
          ../elm-packages.nix
          ../registry.dat
          ../Game.elm
        ];
      };

      nativeBuildInputs = with pkgs; [
        elmPackages.elm
      ];

      # After updating elm.json, regenerate both files:
      #   elm2nix convert > elm-packages.nix
      #   elm2nix snapshot
      configurePhase = pkgs.elmPackages.fetchElmDeps {
        elmPackages = import ../elm-packages.nix;
        elmVersion = "0.19.1";
        registryDat = ../registry.dat;
      };

      buildPhase = ''
        export HOME=$TMPDIR
        rm -rf elm-stuff
        elm make Game.elm --optimize --output=$out/index.html
      '';

      installPhase = ''
        mkdir -p $out
      '';

      meta = {
        license = with lib.licenses; [
          asl20
        ];
      };
    };
  in {
    checks = {
      inherit elmApp;
    };

    packages = {
      default = elmApp;
      elm-snake = elmApp;
    };
  };
}
