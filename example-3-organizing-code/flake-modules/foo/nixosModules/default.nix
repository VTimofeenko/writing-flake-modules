perSystem: # How the per-system part of flake is passed
{ lib, ... }: # Standard module arguments
# TODO: remainafterexit
{
  systemd.services.foo = {
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = lib.getExe perSystem.config.packages.foo;
    };
  };
}
