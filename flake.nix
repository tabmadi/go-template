# The toolchain, the git hooks, the app package, and the checks, per ADR-0100 and ADR-0110. The tabnix module
# holds every shared part, and this file adds the Go parts.
{
  description = "A Go application with the Standard Go Project Layout";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    # A new version is a new tag here.
    tabnix = {
      url = "github:tabmadi/tabnix/v0.6.0";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
    };
  };

  outputs =
    inputs@{ flake-parts, tabnix, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      # The template scope adds its own checks and outputs. A copy has no template/ folder, so it adds nothing.
      imports = [
        tabnix.flakeModules.default
      ]
      ++ inputs.nixpkgs.lib.optional (builtins.pathExists ./template/scope.nix) ./template/scope.nix;

      perSystem =
        { pkgs, ... }:
        let
          # The Go line of the repo. go.mod names the same line.
          go = pkgs.go_1_27;
          golangci = "--config .config/golangci.yml";

          # The static, stripped binary. The module has no dependencies, so it has no vendor hash.
          app = pkgs.buildGo127Module {
            pname = "app";
            version = "0.0.0";
            src = ./.;
            vendorHash = null;
            env.CGO_ENABLED = "0";
            ldflags = [
              "-s"
              "-w"
            ];
          };
        in
        {
          tabnix.packages = [
            go
            pkgs.golangci-lint
            pkgs.gopls
          ];

          # A fix stops the commit, so the engineer reviews the change and stages it.
          tabnix.hooks.go = {
            name = "golangci-lint";
            entry = "${pkgs.writeShellScript "golangci-lint-fix" ''
              export PATH=${go}/bin:$PATH
              exec ${pkgs.golangci-lint}/bin/golangci-lint run ${golangci} --fix --allow-parallel-runners
            ''}";
            files = "\\.go$";
            pass_filenames = false;
          };

          packages.default = app;

          # Building the package also runs `go test` on every package of the module.
          checks.build = app;
          checks.lint-go = app.overrideAttrs (old: {
            pname = "lint-go";
            nativeBuildInputs = old.nativeBuildInputs ++ [ pkgs.golangci-lint ];
            buildPhase = ''
              export HOME=$TMPDIR GOLANGCI_LINT_CACHE=$TMPDIR/golangci-lint
              golangci-lint run ${golangci} --allow-parallel-runners
            '';
            doCheck = false;
            installPhase = "touch $out";
          });
        };
    };
}
