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

      # The configs in .config/ that a tool does not find by itself. The paths are relative to the repo root.
      configEnv = {
        TAPLO_CONFIG = ".config/taplo.toml";
        GITLEAKS_CONFIG = ".config/gitleaks.toml";
      };

      # The configs in .config/ that a tool finds only through a flag. Every call of the tool passes it.
      configFlags = {
        golangci = "--config .config/golangci.yml";
        yamlfmt = "-conf .config/yamlfmt.yaml";
        cog = "--config .config/cog.toml";
      };

      # A check runs a command on a writable copy of the tracked files, so a tool can write its cache.
      check =
        pkgs: name: tools: command:
        pkgs.runCommand name ({ nativeBuildInputs = tools; } // configEnv) ''
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
                exec ${pkgs.golangci-lint}/bin/golangci-lint run ${configFlags.golangci} --fix --allow-parallel-runners
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
            json = {
              enable = true;
              name = "biome";
              entry = "${pkgs.biome}/bin/biome format --no-errors-on-unmatched";
              files = "\\.jsonc?$";
            };
            toml = {
              enable = true;
              name = "taplo";
              entry = "${pkgs.taplo}/bin/taplo fmt --config ${configEnv.TAPLO_CONFIG} --check";
              files = "\\.toml$";
            };
            yaml = {
              enable = true;
              name = "yamlfmt";
              entry = "${pkgs.yamlfmt}/bin/yamlfmt ${configFlags.yamlfmt} -lint";
              files = "\\.ya?ml$";
            };
            justfile = {
              enable = true;
              name = "just --fmt";
              entry = "${pkgs.just}/bin/just --fmt --check";
              files = "(^|/)\\.?justfile$";
              pass_filenames = false;
            };
            secrets = {
              enable = true;
              name = "gitleaks";
              entry = "${pkgs.gitleaks}/bin/gitleaks git --config ${configEnv.GITLEAKS_CONFIG} --pre-commit --staged --no-banner";
              pass_filenames = false;
            };
            commit-message = {
              enable = true;
              name = "cog verify";
              entry = "${pkgs.cocogitto}/bin/cog ${configFlags.cog} verify --file";
              stages = [ "commit-msg" ];
            };
            # Only the commits that this push adds. Older history, such as the first commit
            # that GitHub writes for a repo made from a template, can predate the convention.
            commit-range = {
              enable = true;
              name = "cog check";
              entry = "${pkgs.cocogitto}/bin/cog ${configFlags.cog} check origin/master..HEAD";
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
            # The formatters of JSON, TOML, and YAML, per ADR-0100.
            biome
            taplo
            yamlfmt
            # The language servers and the Nix formatter, for the editor.
            gopls
            nixd
            nixfmt
          ];
          env = configEnv;
          shellHook = (hooks pkgs).shellHook;
        };
      });

      checks = forEachSystem (
        pkgs:
        {
          # Building the package also runs `go test` on every package of the module.
          build = app pkgs;
          lint-go = (app pkgs).overrideAttrs (old: {
            pname = "lint-go";
            nativeBuildInputs = old.nativeBuildInputs ++ [ pkgs.golangci-lint ];
            buildPhase = ''
              export HOME=$TMPDIR GOLANGCI_LINT_CACHE=$TMPDIR/golangci-lint
              golangci-lint run ${configFlags.golangci} --allow-parallel-runners
            '';
            doCheck = false;
            installPhase = "touch $out";
          });
          lint-md = check pkgs "lint-md" [ pkgs.rumdl ] "rumdl check .";
          lint-secrets = check pkgs "lint-secrets" [ pkgs.gitleaks ] "gitleaks dir . --no-banner";
          lint-json = check pkgs "lint-json" [ pkgs.biome ] "biome format --vcs-enabled=false .";
          lint-toml = check pkgs "lint-toml" [ pkgs.taplo ] "taplo fmt --check";
          lint-yaml = check pkgs "lint-yaml" [ pkgs.yamlfmt ] "yamlfmt ${configFlags.yamlfmt} -lint .";
          lint-just = check pkgs "lint-just" [ pkgs.just ] "just --fmt --check";
        }
        // templateScope.checks pkgs
      );

      formatter = forEachSystem (pkgs: pkgs.nixfmt);
    }
    // templateScope.outputs;
}
