{
  description = "ESAS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs =
    { nixpkgs, ... }:
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
          };
        };

      # pysas ships as a prebuilt wheel with exact version pins. Instead of
      # `pip install`-ing it at runtime, package it with the nixpkgs versions
      # of its dependencies (pins are relaxed).
      mkPysas =
        python:
        python.pkgs.buildPythonPackage {
          pname = "pysas";
          version = "0.0.1";
          format = "wheel";
          src = ./pysas-0.0.1-py3-none-any.whl;

          pythonRelaxDeps = true;
          # Not packaged in nixpkgs and not imported anywhere in pysas.
          pythonRemoveDeps = [ "sb3_contrib" ];

          dependencies = with python.pkgs; [
            build
            joblib
            pyyaml
            numpy
            scipy
            jupyterlab
            matplotlib
            pandas
            seaborn
            plotly
            scikit-learn
            ipykernel
            notebook
            torch
            torch-geometric
            gymnasium
            stable-baselines3
            tqdm
            # imported by pysas.backend but missing from the wheel metadata
            flask
          ];

          pythonImportsCheck = [
            "pysas.system"
            "pysas.log"
            "pysas.schedule"
          ];
        };

      mkPython =
        pkgs:
        pkgs.python3.withPackages (ps: [
          (mkPysas pkgs.python3)
          ps.jupyterlab
          ps.notebook
          ps.ipykernel
          ps.pandas
          ps.matplotlib
          ps.seaborn
        ]);
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = mkPkgs system;
        in
        {
          pysas = mkPysas pkgs.python3;
        }
      );

      devShells = forAllSystems (
        system:
        let
          pkgs = mkPkgs system;
        in
        {
          default = pkgs.mkShell {
            # Jupyter and the notebook kernel run from the same Python
            # environment, so `pysas` is importable in managed_systems.ipynb.
            packages = [
              (mkPython pkgs)
              # git filter that strips notebook outputs on commit (see .gitattributes)
              pkgs.nbstripout
            ];
          };
        }
      );
    };
}
