{
  description = "Deltarune fangame engine for Love2D";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
        stdenv = pkgs.stdenv;
        lib = pkgs.lib;
        kristalPackage = stdenv.mkDerivation {
          pname = "kristal";
          version = builtins.readFile ./VERSION;
          src = ./.;
          buildInputs = with pkgs; [
            love
            discord-rpc
          ];
          installPhase = ''
            mkdir -p $out
            cp -r $src/* $out/
            substituteInPlace $out/bin/kristal --replace "love" "${pkgs.love}/bin/love"
            substituteInPlace $out/bin/kristal --replace "dirname" "${pkgs.coreutils}/bin/dirname"
            substituteInPlace $out/src/lib/discordrpc.lua --replace \"discord-rpc\" \"${pkgs.discord-rpc}/lib/libdiscord-rpc.so\"
          '';
          meta = {
            description = "Deltarune fangame engine for Love2D";
            license = lib.licenses.bsd3;
            maintainers = [  ];
            mainProgram = "kristal";
          };
        };
      in {
        packages = {
          default = kristalPackage;
          kristal = kristalPackage;
        };
      }
    );
}
