{
  flake = {config, ...}: {
    nixosModules = let
      name = "yourapp";
    in {
      default = {
        imports = [config.nixosModules.${name}];
      };

      ${name} = {
        config,
        lib,
        pkgs,
        ...
      }: let
        cfg = config.services.${name};
      in {
        options.services.${name} = {
          enable = lib.mkEnableOption "yourapp web frontend";
          package = lib.mkPackageOption pkgs name {};
          listenPort = lib.mkOption {
            type = lib.types.port;
            default = 8080;
            description = "Port for nginx to listen on.";
          };
        };

        config = lib.mkIf cfg.enable {
          services.nginx = {
            enable = true;
            virtualHosts.${name} = {
              listen = [{port = cfg.listenPort;}];
              root = "${cfg.package}";
              locations."/" = {
                index = "index.html";
                tryFiles = "$uri $uri/ /index.html";
              };
            };
          };
        };
      };
    };
  };
}
