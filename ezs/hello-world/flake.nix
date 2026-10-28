{
  description = "Zephyr development environment for the ESP32-C3";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

    # Only used to read scripts/requirements.txt for the Python environment.
    # Keep this in sync with the Zephyr revision in your west manifest.
    zephyr = {
      url = "github:zephyrproject-rtos/zephyr/v4.4.0";
      flake = false;
    };

    zephyr-nix = {
      url = "github:nix-community/zephyr-nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.zephyr.follows = "zephyr";
    };
  };

  outputs = { self, nixpkgs, zephyr-nix, ... }:
    let
      systems = [ "x86_64-linux" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system);
    in
    {
      devShells = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          zephyr = zephyr-nix.packages.${system};
        in
        {
          default = pkgs.mkShell {
            packages = [
              # The ESP32-C3 is a RISC-V core; only fetch that toolchain.
              # The SDK's setup hook exports ZEPHYR_SDK_INSTALL_DIR.
              (zephyr.sdk.override { targets = [ "riscv64-zephyr-elf" ]; })

              # west plus everything in Zephyr's scripts/requirements.txt
              zephyr.pythonEnv

              pkgs.cmake
              pkgs.ninja
              pkgs.dtc
              pkgs.gperf
              pkgs.git
              pkgs.esptool # flashing over the built-in USB-Serial/JTAG
            ];

            env.ZEPHYR_TOOLCHAIN_VARIANT = "zephyr";
          };
        });
    };
}
