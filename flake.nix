{
  description = "NixOS WSL";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    flake-utils.url = "github:numtide/flake-utils";

    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
  };

  outputs = inputs@{ self, nixpkgs, flake-utils, ... }:
    with nixpkgs.lib;
    {

      nixosModules.wsl = {
        imports = [
          ./modules

          (_: {
            wsl.version.rev = mkIf (self ? rev) self.rev;
          })
        ];
      };
      nixosModules.default = self.nixosModules.wsl;

      nixosConfigurations =
        let
          config = { legacy ? false }: { config, lib, pkgs, ... }: {
            wsl = {
              enable = true;
              nativeSystemd = lib.mkIf legacy false;
              startMenuLaunchers = true;
              tarball.configPath = ./config;
            };
            networking.hostName = "wsl";
            programs.bash.loginShellInit = "nixos-wsl-welcome";
            systemd.tmpfiles.rules =
              let
                channels = pkgs.runCommand "default-channels" { } ''
                  mkdir -p $out
                  ln -s ${pkgs.path} $out/nixos
                  ln -s ${./.} $out/nixos-wsl
                '';
              in
              [
                "L /nix/var/nix/profiles/per-user/root/channels-1-link - - - - ${channels}"
                "L /nix/var/nix/profiles/per-user/root/channels - - - - channels-1-link"
              ];
            system.stateVersion = config.system.nixos.release;
          };
        in
        rec {
          default = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [
              self.nixosModules.default
              (config { })
            ];
          };

          modern = nixpkgs.lib.warn "nixosConfigurations.modern has been renamed to nixosConfigurations.default" default;

          legacy = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            modules = [
              self.nixosModules.default
              (config { legacy = true; })
            ];
          };
        };

    } //
    flake-utils.lib.eachSystem
      [ "x86_64-linux" "aarch64-linux" ]
      (system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          checks =
            let
              args = { inherit inputs; };
            in
            {
              dotnet-format = pkgs.callPackage ./checks/dotnet-format.nix args;
              nixpkgs-fmt = pkgs.callPackage ./checks/nixpkgs-fmt.nix args;
              shfmt = pkgs.callPackage ./checks/shfmt.nix args;
              rustfmt = pkgs.callPackage ./checks/rustfmt.nix args;
              side-effects = pkgs.callPackage ./checks/side-effects.nix args;
              username = pkgs.callPackage ./checks/username.nix args;
              test-native-utils = self.packages.${system}.utils;
            };

          packages = {
            utils = pkgs.callPackage ./utils { };
            staticUtils = pkgs.pkgsStatic.callPackage ./utils { };
            docs = pkgs.callPackage ./docs { };
          };

          devShells.default = pkgs.mkShell {
            RUST_SRC_PATH = "${pkgs.rust.packages.stable.rustPlatform.rustLibSrc}";

            nativeBuildInputs = with pkgs; [
              cargo
              clippy
              mdbook
              nixpkgs-fmt
              rustc
              rustfmt
              shfmt
            ];
          };
        }
      );
}
