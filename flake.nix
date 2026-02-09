{
  description = "dobles — test doubles for Python";

  inputs = {
    nixpkgs.url = "git+file:///stash/home/kal/cu/src/nix/nixpkgs/nixos-unstable-lo-patches?ref=nixos-unstable-lo-patches&shallow=1";

    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      perSystem =
        { pkgs, ... }:
        let
          dobles = pkgs.python3Packages.buildPythonPackage {
            pname = "dobles";
            version = "4.0.2";
            src = ./.;
            pyproject = true;

            build-system = [ pkgs.python3Packages.poetry-core ];

            nativeCheckInputs = with pkgs.python3Packages; [
              coverage
              pytestCheckHook
              pytest-asyncio
            ];

            # The pytest11 entry point registers dobles.pytest_plugin as "dobles".
            # test/conftest.py also registers it via pytest_plugins — remove the
            # duplicate to avoid "Plugin already registered under a different name".
            preCheck = ''
              substituteInPlace test/conftest.py \
                --replace-fail 'pytest_plugins = ["dobles.pytest_plugin"]' ""
            '';

            pythonImportsCheck = [ "dobles" ];
          };
        in
        {
          packages.default = dobles;

          devShells.default = pkgs.mkShell {
            inputsFrom = [ dobles ];
            packages = [
              # Install the built package so the pytest11 entry point is
              # registered.  PYTHONPATH prepends $PWD, so imports still
              # resolve to the live source tree.
              dobles
            ] ++ (with pkgs.python3Packages; [
              coverage
              ipython
              pytest
              pytest-asyncio
            ]);

            shellHook = ''
              export PYTHONPATH="$PWD''${PYTHONPATH:+:$PYTHONPATH}"
            '';
          };
        };
    };
}
