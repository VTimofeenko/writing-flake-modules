_:
{
  flake.homeManagerModules.foo-1 =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.cowsay ];
    }
  ;
}
