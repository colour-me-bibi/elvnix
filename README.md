# ElvNix

A flake-managed source for configuring an Elvish shell via Home Manager or NixOS.

## Features

- Modular configuration for the Elvish shell
- Integration with Home Manager and NixOS
- Custom packages and derivations for Elvish extensions and plugins
- Example configurations for quick setup

## Usage

### Home Manager

To use this flake with Home Manager, add the following to your `home.nix`:

```nix
{
  inputs.elvish-flake.url = "github:yourusername/elvish-flake";

  outputs = { self, nixpkgs, elvish-flake, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [ elvish-flake.overlay ];
      };
    in {
      homeConfigurations.yourusername = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          elvish-flake.homeManagerModules.elvish
          ./home.nix
        ];
      };
    };
}
```

Then, in your `home.nix`, you can configure the Elvish shell:

```nix
{
  programs.elvish = {
    enable = true;
    extraConfig = ''
      # Your Elvish configuration here
    '';
    plugins = with pkgs; [
      # List of Elvish plugins
    ];
  };
}
```

### NixOS

To integrate this flake with a NixOS configuration, add the following to your `flake.nix`:

```nix
{
  inputs.elvish-flake.url = "github:yourusername/elvish-flake";

  outputs = { self, nixpkgs, elvish-flake, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [ elvish-flake.overlay ];
      };
    in {
      nixosConfigurations.hostname = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          elvish-flake.nixosModules.elvish
          ./configuration.nix
        ];
      };
    };
}
```

In your `configuration.nix`, you can enable and configure the Elvish shell:

```nix
{
  programs.elvish.enable = true;
  programs.elvish.extraConfig = ''
    # Your Elvish configuration here
  '';
  environment.systemPackages = with pkgs; [
    # List of packages, including Elvish plugins
  ];
}
```

## Available Modules

- `modules/elvish.nix`: The main module for configuring the Elvish shell.
- `modules/plugins/`: Additional modules for Elvish plugins and extensions.

## Custom Packages

This flake provides the following custom packages:

- `pkgs.elvish-plugin1`: Description of the package.
- `pkgs.elvish-plugin2`: Description of the package.

## Contributing

Contributions are welcome! If you have any suggestions, bug reports, or feature requests, please open an issue or submit a pull request.

## License

This project is licensed under the [MIT License](LICENSE).