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
    backendPkgs = pkgs: [pkgs.zig pkgs.nodejs pkgs.pnpm pkgs.websocat];
    dbPkgs = pkgs: [pkgs.sqlfluff];
    frontendPkgs = pkgs: [pkgs.nodejs pkgs.pnpm pkgs.elmPackages.elm pkgs.elmPackages.elm-format pkgs.biome pkgs.elmPackages.elm-review];
    orquestrationPkgs = pkgs: [pkgs.process-compose pkgs.coreutils];

    # Process-compose generator...
    genProcessCompose = pkgs: useTui: let
    in
      pkgs.lib.generators.toYAML {} {
        version = "0.5";
        is_tui_disabled = !useTui;
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
            text = pkgs.lib.debug.traceVal (genProcessCompose pkgs true);
          };
        in ''
          bat ${yamlFile}
        '';
      };

      compileBackend = pkgs.writeShellApplication {
        name = "Backend-Compiler";
        runtimeInputs = [pkgs.zig];
        text = ''
          cd ./backend/ && zig build -Doptimize=ReleaseSafe
        '';
      };

      restartServices = pkgs.writeShellApplication {
        name = "JUWURA-services-starter";
        runtimeInputs = backendPkgs pkgs ++ frontendPkgs pkgs ++ orquestrationPkgs pkgs;
        text = let
          composeFile = pkgs.writeTextFile {
            name = "juwura-process-compose.yaml";
            text = genProcessCompose pkgs true;
          };
        in ''
          echo "Deleting previous DB..."
          rm .pgData || rm -rf .pgData || true
          echo "Starting process compose..."
          process-compose -f ${composeFile}
        '';
      };

      integrationTests = pkgs.writeShellApplication {
        name = "JUWURA-integration-test-runner";
        runtimeInputs = backendPkgs pkgs ++ orquestrationPkgs pkgs;
        text = let
          composeFile = pkgs.writeTextFile {
            name = "juwura-process-compose.yaml";
            text = pkgs.lib.generators.toYAML {} {
              version = "0.5";
              is_tui_disabled = true;
              processes = {
                backend = import ./backend/process.nix;
                database = import ./database/process.nix {
                  inherit pkgs pgConfig;
                  lib = pkgs.lib;
                };

                tests = {
                  working_dir = "backend";
                  command = "pnpm run test:ci";
                  availability = {
                    exit_on_end = true;
                  };
                  depends_on = {
                    database.condition = "process_log_ready";
                    backend.condition = "process_log_ready";
                  };
                };
              };
            };
          };
        in ''
               echo "Deleting previous DB..."
               rm .pgData || rm -rf .pgData || true
               echo "Starting process compose..."
          timeout --kill-after=1m 3m process-compose -f ${composeFile}
        '';
      };
    });

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
