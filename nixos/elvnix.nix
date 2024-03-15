{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.elvish;
in {
  options.programs.elvish = {
    enable = lib.mkEnableOption "Elvish shell";

    extraDomainConfigs = mkOption {
      type = lib.types.attrsOf lib.types.attrsOf lib.types.str;
      default = {};
      example = {
        "example.com" = {
          "username" = "user";
          "password" = "pass";
        };
      };
      description = "Domain-specific configurations for Elvish.";
    };

    packageSources = mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      example = ["github.com/elves/elvish"];
      description = "Package sources to use in the Elvish shell.";
    };

    plugins = mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      example = ["github.com/elves/elvish/edit"];
      description = "Plugins to enable in the Elvish shell.";
    };

    completions = mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      example = ["github.com/elves/elvish/edit"];
      description = "Completions to enable in the Elvish shell.";
    };

    useModules = mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      example = ["edit" "file" "net" "os" "path" "str" "sys" "ui" "url"];
      description = "Modules to import in the Elvish shell.";
    };

    environment = mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = {};
      example = {EDITOR = "nano";};
      description = "Environment variables to set in the Elvish shell.";
    };

    functions = mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = {};
      example = {"ll" = "ls -l";};
      description = "Functions to add to the Elvish shell.";
    };

    aliases = mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = {};
      example = {ll = "ls -l";};
      description = "Aliases to add to the Elvish shell.";
    };

    keybindings = mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = {};
      example = {"C-l" = "clear";};
      description = "Keybindings to configure in the Elvish shell.";
    };

    sessionVariables = mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = {};
      example = {"EDITOR" = "nano";};
      description = "Variables to add to the Elvish shell.";
    };

    settings = mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = {};
      example = {"notify-unsupported-features" = "true";};
      description = "Settings to configure in the Elvish shell.";
    };

    extraConfig = mkOption {
      type = lib.types.str;
      default = "";
      example = "use github.com/elves/elvish/edit";
      description = "Extra configuration to add to the Elvish shell.";
    };

    prompt = mkOption {
      type = lib.types.str;
      default = "> ";
      description = "The prompt for the Elvish shell.";
    };

    interactiveShellInit = mkOption {
      type = lib.types.str;
      default = "";
      example = "use github.com/elves/elvish/edit";
      description = "Initialization code for the interactive Elvish shell.";
    };

    initExtra = mkOption {
      type = lib.types.str;
      default = "";
      example = "use github.com/elves/elvish/edit";
      description = "Extra initialization code for the Elvish shell.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [pkgs.elvish];
    xdg.configFile."elvish/rc.elv".text = lib.concatStringsSep "\n" [
      "# Set the prompt"
      "edit:prompt = '${cfg.prompt}'"
      "# Configure aliases"
      (lib.concatStringsSep "\n" (lib.mapAttrsToList (name: value: "alias[${name}] = { ${value} }") cfg.aliases))
    ];
  };
}
