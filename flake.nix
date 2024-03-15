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
        formatter = pkgs.alejandra;

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
          sample-plugin = pkgs.fetchFromGitHub {
            owner = "elves";
            repo = "sample-plugin";
            rev = "23b880ad19f48ffb821445a03e09035007447338";
            hash = "sha256-IhtVCa+9BIT9IOZY9CX29ecAVZ8lrIetdPNi5XlIwzA=";
          };
        };
      };
      flake = {
        nixosModules = {
          elvish = import ./modules/elvish.nix;
        };

        homeManagerModules = {
          elvish = import ./modules/elvish.nix;
        };
      };
    };
}
