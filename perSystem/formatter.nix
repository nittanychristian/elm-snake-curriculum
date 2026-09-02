{
  perSystem = {
    config,
    pkgs,
    ...
  }: {
    treefmt = {
      projectRootFile = "flake.nix";

      programs.alejandra.enable = true;
      programs.elm-format.enable = true;

      settings.global.excludes = [
        "*.lock"
        ".gitattributes"
        ".gitignore"
        ".gitmodules"
        "LICENSE"
        "elm-stuff"
      ];
    };

    formatter = config.treefmt.build.wrapper;
  };
}
