{
  description = "Elvish shell configuration and packages";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ self.overlay ];
        };
      in {
        nixosModule = { config, ... }: {
          nixpkgs.overlays = [ self.overlay ];
          programs.elvish = {
            enable = true;
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
                  apply = pkg:
                    if pkg == pkgs.elvish
                    then pkg
                    else
                      pkgs.callPackage (self: super: {
                        elvish = super.elvish.overrideAttrs (old: {
                          buildInputs = (old.buildInputs or []) ++ [ pkg ];
                        });
                      }) {};
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
                environment.systemPackages = [ cfg.package ] ++ cfg.systemPackages;
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
            };
          };
        };

        homeModule = { config, ... }: {
          nixpkgs.overlays = [ self.overlay ];
          programs.elvish = {
            enable = true;
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
                (mkRenamedOptionModule [ "programs" "elvish" "initExtra" ] [ "programs" "elvish" "initExtraBeforeCompInit" ])
                (mkRenamedOptionModule [ "programs" "elvish" "rcFiles" ] [ "programs" "elvish" "initExtra" ])
              ];
              options.programs.elvish = {
                enable = mkEnableOption "elvish";
                package = mkOption {
                  type = types.package;
                  default = pkgs.elvish;
                  defaultText = "pkgs.elvish";
                  description = "The Elvish package to use.";
                  apply = pkg:
                    if pkg == pkgs.elvish
                    then pkg
                    else
                      pkgs.callPackage (self: super: {
                        elvish = super.elvish.overrideAttrs (old: {
                          buildInputs = (old.buildInputs or []) ++ [ pkg ];
                        });
                      }) {};
                };
                initExtraBeforeCompInit = mkOption {
                  type = types.str;
                  default = "";
                  description = "Extra Elvish code to be added to the rc file before the completion initialization.";
                };
                initExtra = mkOption {
                  type = types.str;
                  default = "";
                  description = "Extra Elvish code to be added to the rc file after the completion initialization and other configurations.";
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
                home.packages = [ cfg.package ];
                xdg.configFile."elvish/rc.elv".text = ''
                  ${cfg.initExtraBeforeCompInit}
                  ${concatStringsSep "\n" (mapAttrsToList (k: v: "alias ${k} = '${v}'") cfg.aliases)}
                  paths = [
                    ${concatStringsSep "\n" (map (p: " \"${p}\"") cfg.packageSources)}
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
            };
          };
        };

        packages = {
          elvfmt = pkgs.elvfmt;
          elvishPlugins = pkgs.elvishPlugins;
          elvish = pkgs.elvish;
        };

        overlay = final: prev: {
          elvfmt = pkgs.stdenv.mkDerivation {
            name = "elvfmt";
            src = pkgs.fetchFromGitHub {
              owner = "elves";
              repo = "elvish";
              rev = "62d69b4fa223e1e38c4fa0b0af60620764410d68";
              sha256 = "sha256-MZ6i6Hp0Zkt1XOFGhjZQuqmCOodzG+9FHJ1ttUNivkU=";
            };
            buildInputs = [ pkgs.elvish ];
            installPhase = ''
              mkdir -p $out/bin
              cp $src/cmd/elvfmt/elvfmt $out/bin
            '';
          };

          elvishPlugins = {
            sample-plugin = pkgs.fetchFromGitHub {
              owner = "elves";
              repo = "sample-plugin";
              rev = "23b880ad19f48ffb821445als03e09035007447338";
              hash = "sha256-IhtVCa+9BIT9IOZY9CX29ecAVZ8lrIetdPNi5XlIwzA=";
            };
          };

          elvish = prev.elvish.overrideAttrs (oldAttrs: rec {
            version = "unstable-${builtins.substring 0 7 rev}";
            rev = "62d69b4fa223e1e38c4fa0b0af60620764410d68";
            src = pkgs.fetchFromGitHub {
              owner = "elves";
              repo = "elvish";
              inherit rev;
              sha256 = "sha256-MZ6i6Hp0Zkt1XOFGhjZQuqmCOodzG+9FHJ1ttUNivkU=";
            };
            vendorHash = "sha256-UjX1P8v97Mi5cLWv3n7pmxgnw+wCr4aRTHDHHd/9+Lo=";
            ldflags = [
              "-s"
              "-w"
              "-X src.elv.sh/pkg/buildinfo.Version=${version}"
              "-X src.elv.sh/pkg/buildinfo.Reproducible=true"
            ];
          });
        };
      }
    );
}