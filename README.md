# Go Template

A template for a Go application. It follows the [Standard Go Project Layout](https://github.com/golang-standards/project-layout), lints with every `golangci-lint` linter enabled, and builds a static binary. It starts from [github-project-template](https://github.com/tabmadi/github-project-template), so it has the same hooks, CI gate, and documentation convention.

## Stack

| Tool | Owns |
| --- | --- |
| [Go](https://go.dev) | Build, run, and test |
| [golangci-lint](https://golangci-lint.run) | Lint and format |
| [Nix](https://nixos.org) with flakes | Tool versions, the dev shell, the app package, and the sandboxed checks |
| [just](https://just.systems) | Tasks |
| [Zed](https://zed.dev) | The supported editor, with project settings in `.zed/` |
| [git-hooks.nix](https://github.com/cachix/git-hooks.nix) | Git hooks |
| [cocogitto](https://docs.cocogitto.io) | Conventional Commits checks |
| [rumdl](https://github.com/rvben/rumdl) | Markdown lint |
| [gitleaks](https://github.com/gitleaks/gitleaks) | Secret scan |
| [Renovate](https://docs.renovatebot.com) | Updates to the pinned versions |

## Getting started

1. Install [Nix](https://nixos.org/download) and enable flakes. For the editor, also install [Zed](https://zed.dev), and [direnv](https://direnv.net) with [nix-direnv](https://github.com/nix-community/nix-direnv). direnv enters the dev shell on `cd`, and Zed loads it through direnv.
2. Clone the repo and enter the dev shell. The first entry downloads every tool and installs the git hooks:

   ```bash
   git clone git@github.com:tabmadi/go-template.git
   cd go-template
   nix develop
   ```

3. Run the app:

   ```bash
   just run
   ```

To build the release binary without entering the shell, run `nix build`. It writes `result/bin/app`.

## Editor

Open the folder in Zed, and run `direnv allow` once. Zed suggests its Nix extension when you open `flake.nix`, so install it once on each machine. Zed then uses the language servers and formatters of the dev shell, formats on save, and lists every recipe under `task: spawn`. Zed loads the dev shell when it opens the folder. After a change to `flake.nix`, open the folder again, so Zed loads the new tools. Any other editor works through the same dev shell.

## Tasks

| Recipe | Does |
| --- | --- |
| `just setup` | Builds the dev shell, downloads the modules, and installs the git hooks |
| `just run` | Runs the app from source |
| `just build` | Builds a static, stripped binary at `bin/app` |
| `just start` | Builds and runs the binary |
| `just clean` | Deletes the build output |
| `just format` | Applies every formatter and every safe lint fix |
| `just lint` | Runs `lint-go`, `lint-md`, and `lint-secrets` |
| `just test` | Runs the tests |
| `just check` | Runs `lint` and `test`. Run it before you finish a change |
| `just ci` | Runs `nix flake check`, exactly what CI runs: the package with its tests and every linter. The `pre-push` hook runs it too |

## Layout

```text
.
├── cmd/app/          The entry point. It wires the parts together
├── internal/
│   ├── config/       Configuration from defaults and environment variables
│   └── foo/          Sample package with structured logging
├── docs/adr/         The decisions of the project: foundations, doc conventions, toolchain
├── template/         What only the template needs: its contract, checks, and outputs
├── .golangci.yml     The linter and formatter set
├── flake.nix         The dev shell, the app package, the git hooks, and the checks
├── flake.lock        The pinned nixpkgs and inputs
├── .zed/             Zed project settings and tasks
├── justfile          Tasks
└── .envrc            Enters the dev shell through direnv
```

## Configuration

| Variable | Description | Default |
| --- | --- | --- |
| `LOG_LEVEL` | One of `DEBUG`, `INFO`, `WARN`, or `ERROR` | `INFO` |

## Using this template

Make a new project with Nix. It copies every file except the `template/` folder, which holds what only the template needs. This is the preferred way:

```bash
nix flake new -t github:tabmadi/go-template my-project
```

Then follow the steps that it prints:

1. In the new folder, run `git init` and `git add -A`. A flake sees only the files that git tracks.
2. Change the module path in `go.mod` and in the imports to your own.
3. Run `nix develop`. It downloads the tools and installs the git hooks.
4. Replace `internal/foo` with your own packages.
5. Rewrite this README with the template skeleton from [readme-template](https://github.com/tabmadi/readme-template).
6. Update the contacts in `SECURITY.md` and the copyright line in `LICENSE`.
7. Install the [Renovate app](https://github.com/apps/renovate) on the new repository.

### With the GitHub template button

The button copies every file, the `template/` folder included. Remove it in the first commit:

1. Clone the new repository, and run `nix develop` in it.
2. Run `just init`. It prints the first steps, and it removes the `template/` folder with git.
3. Commit the removal.
4. Follow the printed steps from step 2. Your repository already has git.

## Decisions

The ADRs in [docs/adr](docs/adr/README.md) record every decision and the reason for it. `template/adr/0000-template-contract.md` records what makes this repo a template. [ADR-0001](docs/adr/0001-documentation-conventions.md) is the house style for all text.

## Contributing

Follow the [Code of Conduct](CODE_OF_CONDUCT.md). Commit messages follow [Conventional Commits](https://www.conventionalcommits.org), and the `commit-msg` hook checks them. Run `just check` before you open a pull request.

## Security

To report a vulnerability, follow [SECURITY.md](SECURITY.md).

## License

Apache License 2.0. See [LICENSE](LICENSE).
