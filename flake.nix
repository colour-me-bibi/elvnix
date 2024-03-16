{
  description = "Elvish shell configuration and packages";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    flake-parts,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];

      perSystem = {
        config,
        self',
        inputs',
        pkgs,
        system,
        ...
      }: {
        formatter = pkgs.nixpkgs-fmt;

        packages = rec {
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

          default = elvish;
        };

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [elvish elvfmt];
        };
      };

      flake = {
        nixosModules = rec {
          elvnix = {config, ...}: {
            nixpkgs.overlays = [self.overlays.default];
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
          default = elvnix;
        };

        homeModules = rec {
          elvnix = {config, ...}: {
            nixpkgs.overlays = [self.overlays.default];
            programs.elvish = {
              enable = true;
              package = config.packages.elvish;
              initExtra = ''
                # Your extra initialization code here
              '';
            };
          };
          default = elvnix;
        };

        overlays = {
          default = final: prev: {
            elvfmt = self.packages.${prev.system}.elvfmt;
            elvishPlugins = self.packages.${prev.system}.elvishPlugins;
            elvish = self.packages.${prev.system}.elvish;
          };
        };
      };
    };
}
