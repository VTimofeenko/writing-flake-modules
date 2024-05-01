{ flake-parts-lib, nixpkgs-lib, ... }: # This is the producer flake, the source for the module
let
  inherit (flake-parts-lib) mkPerSystemOption;
  inherit (nixpkgs-lib.lib)
    mkOption
    types
    mkEnableOption
    optional
    assertMsg
    ;
in
{
  config,
  self,
  inputs,
  ...
}: # This would be the consumer flake
{
  options.perSystem = mkPerSystemOption (
    { config, pkgs, ... }:
    let
      # Standard approach -- refer to this module's options' values as `cfg`
      cfg = config.bumper;
    in
    {
      options.bumper.changingInputs = mkOption {
        description = ''
          List of names of quickly changing inputs.

          This list will be turned into shell commands through devshell.
        '';
        type = types.listOf types.str;
        default = [ ];
      };

      # Option declaration
      options.bumper.bumpAllInputs = mkEnableOption "command to bump all inputs and commit";

      # Option implementation on top of devshell module
      config.devshells.default =
        let
          bumpScript = pkgs.writeShellApplication {
            name = "bump-input";
            runtimeInputs = [ ];
            text = builtins.readFile ./bump-input;
          };
        in
        {
          commands =
            (map (inputName: {
              help =
                # Double-check that the input actually exists
                # This is not strictly necessary as the wrapped nix flake does the same thing, but it's an illustration of referring to the consumer flake (self.inputs)
                assert assertMsg (builtins.elem inputName (
                  builtins.attrNames self.inputs
                )) "Input '${inputName}' does not exist in current flake. Check bumper settings.";
                "Bump input ${inputName}";
              name = "flake-bump-${inputName}"; # The name of the resulting script
              command = # bash
                "${pkgs.lib.getExe bumpScript} ${inputName}";
              category = "flake management";
            }) cfg.changingInputs)

            # Add a special case for bumping all inputs by handling the value of bumpAllInputs option
            ++ optional cfg.bumpAllInputs {
              help = "Bump all inputs";
              name = "flake-bump-all-inputs";
              command = # bash
                "${pkgs.lib.getExe bumpScript} \"*\"";
              category = "flake management";
            };
        };
    }
  );
}
