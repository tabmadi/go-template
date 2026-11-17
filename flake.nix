# The toolchain, the git hooks, the app package, and the checks, per ADR-0100.
{
  description = "A Go application with the Standard Go Project Layout";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      git-hooks,
    }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forEachSystem = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});

      # The template scope adds its own checks and outputs. A copy has no template/ folder, so it adds nothing.
      templateScope =
        if builtins.pathExists ./template/scope.nix then
          import ./template/scope.nix { inherit self nixpkgs; }
        else
          {
            checks = _: { };
            outputs = { };
          };

      # The Go line of the repo. go.mod names the same line.
      go = pkgs: pkgs.go_1_27;
      buildGoModule = pkgs: pkgs.buildGo127Module;

      # The static, stripped binary. The module has no dependencies, so it has no vendor hash.
      app =
        pkgs:
        (buildGoModule pkgs) {
          pname = "app";
          version = "0.0.0";
          src = self;
          vendorHash = null;
          env.CGO_ENABLED = "0";
          ldflags = [
            "-s"
            "-w"
          ];
        };

      # A check runs a command on a writable copy of the tracked files, so a tool can write its cache.
      check =
        pkgs: name: tools: command:
        pkgs.runCommand name { nativeBuildInputs = tools; } ''
          cp -r ${self} source
          chmod -R u+w source
          cd source
          ${command}
          touch $out
        '';

      hooks =
        pkgs:
        git-hooks.lib.${pkgs.stdenv.hostPlatform.system}.run {
          src = ./.;
          package = pkgs.prek;
          hooks = {
            # A fix stops the commit, so the engineer reviews the change and stages it.
            go = {
              enable = true;
              name = "golangci-lint";
              entry = "${pkgs.writeShellScript "golangci-lint-fix" ''
                export PATH=${go pkgs}/bin:$PATH
                exec ${pkgs.golangci-lint}/bin/golangci-lint run --fix --allow-parallel-runners
              ''}";
              files = "\\.go$";
              pass_filenames = false;
            };
            markdown = {
              enable = true;
              name = "rumdl";
              entry = "${pkgs.rumdl}/bin/rumdl check";
              files = "\\.md$";
            };
            secrets = {
              enable = true;
              name = "gitleaks";
              entry = "${pkgs.gitleaks}/bin/gitleaks git --pre-commit --staged --no-banner";
              pass_filenames = false;
            };
            commit-message = {
              enable = true;
              name = "cog verify";
              entry = "${pkgs.cocogitto}/bin/cog verify --file";
              stages = [ "commit-msg" ];
            };
            # Only the commits that this push adds. Older history, such as the first commit
            # that GitHub writes for a repo made from a template, can predate the convention.
            commit-range = {
              enable = true;
              name = "cog check";
              entry = "${pkgs.cocogitto}/bin/cog check origin/master..HEAD";
              stages = [ "pre-push" ];
              pass_filenames = false;
              always_run = true;
            };
            ci = {
              enable = true;
              name = "just ci";
              entry = "${pkgs.just}/bin/just ci";
              stages = [ "pre-push" ];
              pass_filenames = false;
              always_run = true;
            };
          };
        };
    in
    {
      packages = forEachSystem (pkgs: {
        default = app pkgs;
      });

      devShells = forEachSystem (pkgs: {
        default = pkgs.mkShellNoCC {
          packages = with pkgs; [
            (go pkgs)
            golangci-lint
            just
            cocogitto
            rumdl
            gitleaks
          ];
          shellHook = (hooks pkgs).shellHook;
        };
      });

      checks = forEachSystem (pkgs: {
        # Building the package also runs `go test` on every package of the module.
        build = app pkgs;
        lint-go = (app pkgs).overrideAttrs (old: {
          pname = "lint-go";
          nativeBuildInputs = old.nativeBuildInputs ++ [ pkgs.golangci-lint ];
          buildPhase = ''
            export HOME=$TMPDIR GOLANGCI_LINT_CACHE=$TMPDIR/golangci-lint
            golangci-lint run --allow-parallel-runners
          '';
          doCheck = false;
          installPhase = "touch $out";
        });
        lint-md = check pkgs "lint-md" [ pkgs.rumdl ] "rumdl check .";
        lint-secrets = check pkgs "lint-secrets" [ pkgs.gitleaks ] "gitleaks dir . --no-banner";
      }
      // templateScope.checks pkgs);

      formatter = forEachSystem (pkgs: pkgs.nixfmt);
    }
    // templateScope.outputs;
}
