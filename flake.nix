{
  description = "Elvish shell configuration and packages";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = {
    self,
    nixpkgs,
    flake-utils,
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [self.overlay];
        };
      in {
        nixosModule = {config, ...}: {
          nixpkgs.overlays = [self.overlay];
          programs.elvish = {
            enable = true;
            config = {
              interactiveShellInit = ''
                # Your interactive shell initialization code here
              '';
              loginShellInit = ''
                # Your login shell initialization code here
              '';
              promptInit = ''
                # Your prompt initialization code here
              '';
            };
          };
        };

        homeModule = {config, ...}: {
          nixpkgs.overlays = [self.overlay];
          programs.elvish = {
            enable = true;
            package = pkgs.elvish;
            initExtra = ''
              # Your extra initialization code here
            '';
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
            buildInputs = [pkgs.elvish];
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
