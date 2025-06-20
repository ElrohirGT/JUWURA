{
  description = "JUWURA Nix Flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = {
    self,
    nixpkgs,
  }: let
    pgConfig = {
      port = "6969";
      host = "127.0.0.1";
    };
    # System types to support.
    supportedSystems = ["x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin"];

    # Helper function to generate an attrset '{ x86_64-linux = f "x86_64-linux"; ... }'.
    forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

    # Nixpkgs instantiated for supported system types.
    nixpkgsFor = forAllSystems (system: import nixpkgs {inherit system;});

    # System packages...
    # backendPkgs = pkgs: [pkgs.zig pkgs.nodejs pkgs.pnpm pkgs.websocat];
    backendPkgs = pkgs: [pkgs.gleam pkgs.websocat pkgs.nodejs pkgs.pnpm];
    dbPkgs = pkgs: [pkgs.sqlfluff];
    # frontendPkgs = pkgs: [pkgs.nodejs pkgs.pnpm pkgs.elmPackages.elm pkgs.elmPackages.elm-format pkgs.biome pkgs.elmPackages.elm-review];
    frontendPkgs = pkgs: [pkgs.gleam pkgs.biome];
    orquestrationPkgs = pkgs: [pkgs.process-compose pkgs.coreutils];
  in {
    devShells = forAllSystems (system: let
      pkgs = nixpkgsFor.${system};
    in {
      default = pkgs.mkShell {
        packages = backendPkgs pkgs ++ frontendPkgs pkgs ++ orquestrationPkgs pkgs ++ dbPkgs pkgs;
      };

      cicdFrontend = pkgs.mkShell {
        packages = frontendPkgs pkgs;
      };

      cicdBackend = pkgs.mkShell {
        packages = backendPkgs pkgs ++ orquestrationPkgs pkgs;
      };

      cicdDB = pkgs.mkShell {
        packages = dbPkgs pkgs;
      };
    });
  };
}
