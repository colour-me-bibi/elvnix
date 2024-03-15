{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.programs.elvish;
in {
  options.programs.elvish = {
    enable = mkEnableOption "Elvish shell";

    package = mkOption {
      type = types.package;
      default = pkgs.elvish;
      defaultText = "pkgs.elvish";
      description = "The Elvish package to use.";
    };

    systemPackages = mkOption {
      type = types.listOf types.package;
      default = [];
      example = literalExpression "[ pkgs.elvish-packages.elv-mode ]";
      description = "List of Elvish packages to make available to all users.";
    };

    interactiveShellInit = mkOption {
      type = types.lines;
      default = "";
      description = ''
        Shell code that is run at the start of an interactive Elvish session.
      '';
    };

    loginShellInit = mkOption {
      type = types.lines;
      default = "";
      description = ''
        Shell code that is run at the start of a login Elvish session.
      '';
    };

    promptInit = mkOption {
      type = types.lines;
      default = "";
      description = ''
        Shell code that is used to initialize the Elvish prompt.
      '';
    };

    configFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      example = literalExpression ''"''${config.users.users.alice.home}/.config/elvish/rc.elv"'';
      description = ''
        Path to the Elvish configuration file. If not set, a default configuration file will be generated.
      '';
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [cfg.package] ++ cfg.systemPackages;

    environment.shellInit = ''
      export ELVISH_PACKAGE_PATH=${concatStringsSep ":" (map (p: "${p}/share/elvish/lib") cfg.systemPackages)}
    '';

    environment.interactiveShellInit = mkAfter cfg.interactiveShellInit;

    users.defaultUserShell = mkDefault cfg.package;

    environment.etc."elvish/rc.elv".text = optionalString (cfg.configFile == null) ''
      ${cfg.loginShellInit}
      ${cfg.promptInit}
    '';

    assertions = [
      {
        assertion = cfg.configFile != null -> builtins.pathExists cfg.configFile;
        message = "programs.elvish.configFile points to a file that does not exist.";
      }
    ];
  };
}
