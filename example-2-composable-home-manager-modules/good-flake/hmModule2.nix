_:
{
  flake.homeManagerModules.foo-2 =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.hello ];
    }
  ;
}
