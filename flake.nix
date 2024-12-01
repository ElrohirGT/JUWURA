{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = {
    self,
    nixpkgs,
  }: let
    # System types to support.
    supportedSystems = ["x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin"];

    # Helper function to generate an attrset '{ x86_64-linux = f "x86_64-linux"; ... }'.
    forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

    # Nixpkgs instantiated for supported system types.
    nixpkgsFor = forAllSystems (system: import nixpkgs {inherit system;});

    backendPkgs = pkgs: [pkgs.zig pkgs.nodejs pkgs.yarn-berry];
    frontendPkgs = pkgs: [pkgs.nodejs pkgs.yarn-berry pkgs.elmPackages.elm pkgs.elmPackages.elm-format];
    cicdPkgs = pkgs: [pkgs.process-compose pkgs.entr];
  in {
    packages = forAllSystems (system: let
      pkgs = nixpkgsFor.${system};
    in {
      restartServices = pkgs.writeShellApplication {
        name = "JUWURA services starter";
        runtimeInputs = backendPkgs pkgs ++ frontendPkgs pkgs ++ cicdPkgs pkgs;
        text = let
          processYAML = pkgs.lib.generators.toYAML {} {
            version = "0.5"; 
            processes = {
              frontend = {
                working_dir = "./frontend";
                command = "yarn dev";
              };

							backend = {
								working_dir = "./backend";
								command = "zig build run";
							};
            };
          };
          composeFile = pkgs.writeTextFile {
            name = "juwura-process-compose.yaml";
            text = processYAML;
          };
        in ''
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
