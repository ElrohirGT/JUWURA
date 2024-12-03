{
  description = "A very basic flake";

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
    backendPkgs = pkgs: [pkgs.zig pkgs.nodejs pkgs.yarn-berry];
    frontendPkgs = pkgs: [pkgs.nodejs pkgs.yarn-berry pkgs.elmPackages.elm pkgs.elmPackages.elm-format];
    cicdPkgs = pkgs: [pkgs.process-compose pkgs.entr];

    # Process-compose generator...
    genProcessCompose = pkgs: let
    in
      pkgs.lib.generators.toYAML {} {
        version = "0.5";
        processes = {
          frontend = import ./frontend/process.nix;
          backend = import ./backend/process.nix;
          database = import ./database/process.nix {
            inherit pkgs pgConfig;
            lib = pkgs.lib;
          };
        };
      };
  in {
    packages = forAllSystems (system: let
      pkgs = nixpkgsFor.${system};
    in {
      printDevPC = pkgs.writeShellApplication {
        name = "Dev-Process-Compose";
        runtimeInputs = [pkgs.bat];
        text = let
          yamlFile = pkgs.writeTextFile {
            name = "juwura-process-compose.yaml";
            text = pkgs.lib.debug.traceVal (genProcessCompose pkgs);
          };
        in ''
          bat ${yamlFile}
        '';
      };

      restartServices = pkgs.writeShellApplication {
        name = "JUWURA-services-starter";
        runtimeInputs = backendPkgs pkgs ++ frontendPkgs pkgs ++ cicdPkgs pkgs;
        text = let
          composeFile = pkgs.writeTextFile {
            name = "juwura-process-compose.yaml";
            text = genProcessCompose pkgs;
          };
        in ''
					echo "Deleting previous DB..."
					rm .pgData || rm -rf .pgData || true
					echo "Starting process compose..."
          process-compose -f ${composeFile}
        '';
      };
    });

    devShells = forAllSystems (system: let
      pkgs = nixpkgsFor.${system};
    in {
      default = pkgs.mkShell {
        packages = backendPkgs pkgs ++ frontendPkgs pkgs ++ cicdPkgs pkgs;
      };
    });
  };
}
