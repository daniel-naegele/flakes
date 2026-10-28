{
  description = "LFCPS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    dagger = {
      url = "github:dagger/nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, dagger, ... }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system);

      mkPkgs =
        system:
        import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
            android_sdk.accept_license = true;
          };
        };

      # The installer has to be downloaded from the Wolfram user portal and added to the store:
      #   nix-store --add-fixed sha256 Wolfram_15.0.1_LIN.sh
      # webdoc = true selects the installer without local documentation.
      mkMathematica = pkgs: pkgs.mathematica.override { webdoc = true; };
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = mkPkgs system;
        in
        {
          keymaerax = pkgs.callPackage ./keymaera.nix { };
        }
        // nixpkgs.lib.optionalAttrs (system == "x86_64-linux") {
          mathematica = mkMathematica pkgs;
        }
      );

      devShells = forAllSystems (
        system:
        let
          pkgs = mkPkgs system;

          jdk = pkgs.jdk21;
        in
        {
          default = pkgs.mkShell {
            packages = [
              jdk
              (pkgs.callPackage ./keymaera.nix { inherit jdk; })
            ]
            # Mathematica is only packaged for x86_64-linux in nixpkgs.
            ++ pkgs.lib.optionals (system == "x86_64-linux") [ (mkMathematica pkgs) ];
          };
        }
      );
    };
}
