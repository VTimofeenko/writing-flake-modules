# The importApply argument. Use this to reference things defined locally,
# as opposed to the flake where this is imported.
localFlake:

# Regular module arguments; self, inputs, etc all reference the final user flake,
# where this module was imported.
{ lib, config, self, inputs, ... }:
{
  perSystem =
    { system, ... }:
    {
      packages.foo = localFlake.withSystem system (
        { config, pkgs, ... }: pkgs.callPackage ./pkgs/foo.nix { }
      );

      checks.foo-nixos-module = localFlake.withSystem system (
        { config, pkgs, ... }:
        pkgs.testers.runNixOSTest {
          name = "foo-nixos-module";
          nodes.machine1 =
            _: # { config, pkgs, ... }:
            { imports = [ self.nixosModules.foo ]; };
          testScript = ''
            _, output = machine.systemctl("status foo")

            assert "Hello, world" in output
          '';
        }
      );

      checks.foo-hm-module = localFlake.withSystem system (
        { config, pkgs, ... }:
        pkgs.testers.runNixOSTest {
          name = "foo-hm-module";
          nodes.machine1 =
            _: # { config, pkgs, ... }:
            {
              imports = [ inputs.home-manager.nixosModules.home-manager ];
              users.users.alice = {
                isNormalUser = true;
                password = "hunter2";
              };

              home-manager.users.alice =
                _: # { config, ... }: # config is home-manager's config, not the OS one
                {
                  imports = [ self.homeManagerModules.foo ];
                  home.stateVersion = "23.11";
                };
            };
          testScript = ''
            machine.wait_until_tty_matches("1", "login: ")
            machine.send_chars("alice\n")
            machine.wait_until_tty_matches("1", "Password: ")
            machine.send_chars("hunter2\n")
            machine.wait_until_tty_matches("1", "alice\@machine")

            machine.wait_for_unit("home-manager-alice.service")
            _, output = machine.systemctl("status foo", user="alice")

            assert "Hello, world" in output
          '';
        }
      );
    };

  flake.nixosModules.foo = localFlake.moduleWithSystem (
    perSystem@{ config }: localFlake.importApply ./nixosModules perSystem
  );

  flake.homeManagerModules.foo = localFlake.moduleWithSystem (
    perSystem@{ config }: localFlake.importApply ./homeManagerModules perSystem
  );
}
