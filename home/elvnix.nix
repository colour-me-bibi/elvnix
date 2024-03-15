{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.programs.elvish;
in {
  imports = [
    (mkRenamedOptionModule ["programs" "elvish" "initExtra"] ["programs" "elvish" "initExtraBeforeCompInit"])
    (mkRenamedOptionModule ["programs" "elvish" "rcFiles"] ["programs" "elvish" "initExtra"])
  ];

  options.programs.elvish = {
    enable = mkEnableOption "elvish";
    package = mkOption {
      type = types.package;
      default = pkgs.elvish;
      defaultText = "pkgs.elvish";
      description = "The elvish package to use.";
    };
    initExtraBeforeCompInit = mkOption {
      type = types.str;
      default = "";
      description = "Extra code to add to the elvish rc file before the completion init.";
    };
    initExtra = mkOption {
      type = types.str;
      default = "";
      description = "Extra code to add to the elvish rc file.";
    };
    aliases = mkOption {
      type = types.attrs;
      default = {};
      description = "A set of aliases to add to the elvish rc file.";
    };
    packageSources = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "A list of package sources to add to the elvish rc file.";
    };
    usePath = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to use the builtin path module.";
    };
    useRe = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to use the builtin re module.";
    };
    useReadlineBinding = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to use the readline binding.";
    };
    useStr = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to use the builtin str module.";
    };
    useMath = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to use the builtin math module.";
    };
    extraModules = mkOption {
      type = types.listOf types.attrs;
      default = [];
      description = "A list of extra modules to add to the elvish rc file.";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [cfg.package];

    xdg.configFile."elvish/rc.elv".text = ''
      ${cfg.initExtraBeforeCompInit}

      ${concatStringsSep "\n" (mapAttrsToList (k: v: "alias ${k} = '${v}'") cfg.aliases)}

      paths = [
        ${concatStringsSep "\n" (map (p: "  \"${p}\"") cfg.packageSources)}
      ]

      ${optionalString cfg.usePath "use path"}
      ${optionalString cfg.useRe "use re"}
      ${optionalString cfg.useReadlineBinding "use readline-binding"}
      ${optionalString cfg.useStr "use str"}
      ${optionalString cfg.useMath "use math"}

      ${concatStringsSep "\n" (map (m: ''
          ${
            if m ? "name"
            then "use ${m.module} ${m.name}"
            else "use ${m.module}"
          }
        '')
        cfg.extraModules)}

      ${cfg.initExtra}
    '';
  };
}
