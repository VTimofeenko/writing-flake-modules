perSystem:
{ lib, ... }:
{
  systemd.user.services.foo = {
    Service = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = lib.getExe perSystem.config.packages.foo;
    };
    Install.WantedBy = [ "default.target" ];
  };
}
