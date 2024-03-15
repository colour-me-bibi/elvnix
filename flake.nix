{
  description = "A flake-managed source for configuring an Elvish shell";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    ez-configs.url = "github:ehllie/ez-configs";
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [inputs.ez-configs.flakeModule];

      ezConfigs.root = ./.;

      systems = inputs.nixpkgs.lib.systems.flakeExposed;

      perSystem = {
        lib,
        pkgs,
        self',
        ...
      }: {
        packages.elvish = pkgs.elvish.overrideAttrs (oldAttrs: rec {
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

        packages.elvishPlugins = {
          plugin1 =
            pkgs.fetchFromGitHub {
            };
          plugin2 =
            pkgs.fetchFromGitHub {
            };
        };

        lib.elvishWithPlugins = plugins:
          pkgs.symlinkJoin {
            name = "elvish-with-plugins";
            paths = [self'.packages.elvish] ++ plugins;
            buildInputs = [pkgs.makeWrapper];
            postBuild = ''
              wrapProgram $out/bin/elvish --set CGO_ENABLED 1
            '';
          };

        packages.elvishWithPlugins = self'.lib.elvishWithPlugins (
          with self'.packages.elvishPlugins; [
            plugin1
            plugin2
            # ...
          ]
        );

        packages.default = self'.packages.elvishWithPlugins;

        devShells.default = pkgs.mkShell {
          inputsFrom = [self'.packages.default];
        };

        nixosModules = {
          elvish = import ./modules/elvish.nix;
        };

        homeManagerModules = {
          elvish = import ./modules/elvish.nix;
        };
      };
    };
}
