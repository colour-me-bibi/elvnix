{
  description = "A flake-managed source for configuring an Elvish shell";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };
  outputs = inputs @ {self, ...}:
    inputs.flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [
        inputs.flake-parts.flakeModules.easyOverlay
      ];
      systems = inputs.nixpkgs.lib.systems.flakeExposed;
      perSystem = {
        config,
        pkgs,
        final,
        self',
        inputs',
        system,
        ...
      }: {
        overlayAttrs = {
          inherit
            (self'.packages)
            elvfmt
            elvish
            elvishPlugins
            ;
        };
        formatter = pkgs.alejandra;
        packages = rec {
          elvish = pkgs.elvish.overrideAttrs (oldAttrs: rec {
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
          elvishPlugins = {
            sample-plugin = pkgs.fetchFromGitHub {
              owner = "elves";
              repo = "sample-plugin";
              rev = "23b880ad19f48ffb821445als03e09035007447338";
              hash = "sha256-IhtVCa+9BIT9IOZY9CX29ecAVZ8lrIetdPNi5XlIwzA=";
            };
          };
          elvfmt = pkgs.stdenv.mkDerivation {
            name = "elvfmt";
            src = pkgs.fetchFromGitHub {
              owner = "elves";
              repo = "elvish";
              rev = "62d69b4fa223e1e38c4fa0b0af60620764410d68";
              sha256 = "sha256-MZ6i6Hp0Zkt1XOFGhjZQuqmCOodzG+9FHJ1ttUNivkU=";
            };
            buildInputs = [pkgs.elvish];
            installPhase = ''
              mkdir -p $out/bin
              cp $src/cmd/elvfmt/elvfmt $out/bin
            '';
          };
          default = elvish;
        };
      };
      flake = {
        homeModules = rec {
          elvnix = ./home-modules/elvnix;
          default = elvnix;
        };
        nixosModules = rec {
          elvnix = ./nixos-modules/elvnix;
          default = elvnix;
        };
      };
    };
}
