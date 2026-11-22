# The toolchain, the git hooks, the app package, and the checks, per ADR-0100 and ADR-0110. The tabkit module
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
    tabkit = {
      url = "github:tabmadi/tabkit/v0.17.0";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
    };
  };

  outputs =
    inputs@{ flake-parts, tabkit, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      # The template scope adds its own checks and outputs. A copy has no template/ folder, so it adds nothing.
      imports = [
        tabkit.flakeModules.default
        tabkit.flakeModules.go
      ]
      ++ inputs.nixpkgs.lib.optional (builtins.pathExists ./template/scope.nix) ./template/scope.nix;

      perSystem =
        { config, pkgs, ... }:
        let
          # The Go line of the repo. go.mod names the same line.
          go = pkgs.go_1_27;
          golangci = "--config .config/golangci.yml";
          # The wrapper of the tabkit go module, which gives the config the path of the ruleguard rules.
          linter = "${config.tabkit.go.golangci}/bin/golangci-lint";

          # The static, stripped binary. The only dependency is the ruleguard DSL, which the binary does not link.
          app = pkgs.buildGo127Module {
            pname = "app";
            version = "0.0.0";
            src = ./.;
            vendorHash = "sha256-Fps7U7ORVPaOloJCAiz9sxqinZIxQmYxPv7eQoiR4hk=";
            env.CGO_ENABLED = "0";
            ldflags = [
              "-s"
              "-w"
            ];
          };
        in
        {
          tabkit.packages = [
            go
            pkgs.gopls
          ];

          # A fix stops the commit, so the engineer reviews the change and stages it.
          tabkit.hooks.go = {
            name = "golangci-lint";
            # The hook carries the Go of the dev shell. GOTOOLCHAIN=local stops Go from downloading another toolchain
            # when go.mod names a newer one.
            entry = "${pkgs.writeShellScript "golangci-lint-fix" ''
              export PATH=${go}/bin:$PATH GOTOOLCHAIN=local
              exec ${linter} run ${golangci} --fix --allow-parallel-runners
            ''}";
            files = "\\.go$";
            pass_filenames = false;
          };

          packages.default = app;

          # Building the package also runs `go test` on every package of the module.
          checks.build = app;
          checks.lint-go = app.overrideAttrs (old: {
            pname = "lint-go";
            nativeBuildInputs = old.nativeBuildInputs ++ [ config.tabkit.go.golangci ];
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
