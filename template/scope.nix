# The template scope, per TPL-0000. The template module of tabnix adds the lint-scope check and the templates output.
{ inputs, ... }:
{
  imports = [ inputs.tabnix.flakeModules.template ];

  tabnix.template = {
    description = "A Go application with the Standard Go Project Layout, every golangci-lint linter, and a static binary";
    welcomeText = ''
      # A new project

      1. In a new folder, run `git init` and `git add -A`. A flake sees only the files that git tracks.
      2. Change the module path in `go.mod` and in the imports to your own.
      3. Run `nix develop`. It downloads the tools and installs the git hooks.
      4. Replace the sample service in `cmd/app` and `internal/` with your own packages.
      5. Rewrite `README.md` for this project.
      6. Update the contacts in `.github/SECURITY.md` and the copyright line in `LICENSE`.
      7. Install the Renovate app on the new repository.
    '';
  };
}
