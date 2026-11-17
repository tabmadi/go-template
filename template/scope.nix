# The template scope, per TPL-0000: the checks and outputs that only the template has.
{ self, nixpkgs }:
let
  # Every file except this folder. `nix flake new -t` copies the result into a new project.
  projectScope = builtins.path {
    name = "project";
    path = self;
    filter = path: _type: !(nixpkgs.lib.hasPrefix "${toString self}/template" path);
  };
in
{
  checks = pkgs: {
    # The copied files stay true in every copy, per TPL-0000.
    lint-scope = pkgs.runCommand "lint-scope" { } ''
      cd ${self}
      voice='github\.com/tabmadi|blueprints|this template|the template|made from this|generated (repo|project)|TPL-[0-9]'
      if grep -rniE "$voice" docs AGENTS.md; then
        echo "A project doc speaks as the template or names another repo." >&2
        exit 1
      fi
      if grep -rnE --include='*.md' --exclude-dir=template '\]\((\./|\.\./)*template/' .; then
        echo "A copied file links into template/, and the link breaks in every copy." >&2
        exit 1
      fi
      touch $out
    '';
  };

  outputs = {
    templates.default = {
      path = projectScope;
      description = "A Go application with the Standard Go Project Layout, every golangci-lint linter, and a static binary";
      welcomeText = ''
        # A new project

        1. In a new folder, run `git init` and `git add -A`. A flake sees only the files that git tracks.
        2. Change the module path in `go.mod` and in the imports to your own.
        3. Run `nix develop`. It downloads the tools and installs the git hooks.
        4. Replace `internal/foo` with your own packages.
        5. Rewrite `README.md` for this project.
        6. Update the contacts in `.github/SECURITY.md` and the copyright line in `LICENSE`.
        7. Install the Renovate app on the new repository.
      '';
    };
  };
}
