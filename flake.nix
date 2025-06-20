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

    # Project packages...
    backendPkgs = forAllSystems (
      system: let
        pkgs = nixpkgsFor.${system};
      in
        [pkgs.gleam pkgs.erlang pkgs.rebar3]
        ++ (
          if system != "aarch64-darwin"
          then [pkgs.inotify-tools]
          else []
        )
    );
    dbPkgs = forAllSystems (system: let
      pkgs = nixpkgsFor.${system};
    in [pkgs.sqlfluff pkgs.podman pkgs.podman-compose]);

    frontendPkgs = forAllSystems (system: let
      pkgs = nixpkgsFor.${system};
    in [pkgs.gleam pkgs.biome pkgs.tailwindcss_4]);
    orquestrationPkgs = forAllSystems (system: let
      pkgs = nixpkgsFor.${system};
    in [pkgs.process-compose pkgs.coreutils pkgs.xc]);
  in {
    devShells = forAllSystems (system: let
      pkgs = nixpkgsFor.${system};
    in {
      default = pkgs.mkShell {
        packages = backendPkgs.${system} ++ frontendPkgs.${system} ++ orquestrationPkgs.${system} ++ dbPkgs.${system};
      };

      cicdFrontend = pkgs.mkShell {
        packages = frontendPkgs.${system};
      };

      cicdBackend = pkgs.mkShell {
        packages = backendPkgs.${system} ++ orquestrationPkgs.${system};
      };

      cicdDB = pkgs.mkShell {
        packages = dbPkgs.${system};
      };
    });
  };
}
