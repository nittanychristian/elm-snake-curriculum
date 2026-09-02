{
  perSystem = {
    config,
    pkgs,
    ...
  }: {
    devShells.default = with pkgs;
      mkShell {
        packages = [
          elmPackages.elm
          elmPackages.elm-format
          elmPackages.elm-language-server
          elmPackages.elm-test
          elmPackages.elm-review
          elm2nix
          elmPackages.elm-live
          just
          config.treefmt.build.wrapper
        ];
      };
  };
}
