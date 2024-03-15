{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
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

        packages.elvish = pkgs.symlinkJoin {
          name = "elvish";
          paths = [self'.packages.elvish];
          buildInputs = [pkgs.makeWrapper];
          postBuild = ''
            wrapProgram $out/bin/elvish --set CGO_ENABLED : 1
          '';
        };

        packages.default = self'.packages.elvish;

        devShells.default = pkgs.mkShell {
          inputsFrom = [self'.packages.default];
        };
      };
    };
}
