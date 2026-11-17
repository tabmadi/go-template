# Go Template

A template for a Go application. It follows the [Standard Go Project Layout](https://github.com/golang-standards/project-layout), lints with every `golangci-lint` linter enabled, and builds a static binary. It starts from [github-project-template](https://github.com/tabmadi/github-project-template), so it has the same hooks, CI gate, and documentation convention.

## Stack

| Tool | Owns |
| --- | --- |
| [Go](https://go.dev) | Build, run, and test |
| [golangci-lint](https://golangci-lint.run) | Lint and format |
| [Nix](https://nixos.org) with flakes | Tool versions, the dev shell, the app package, and the sandboxed checks |
| [just](https://just.systems) | Tasks |
| [git-hooks.nix](https://github.com/cachix/git-hooks.nix) | Git hooks |
| [cocogitto](https://docs.cocogitto.io) | Conventional Commits checks |
| [rumdl](https://github.com/rvben/rumdl) | Markdown lint |
| [gitleaks](https://github.com/gitleaks/gitleaks) | Secret scan |
| [Renovate](https://docs.renovatebot.com) | Updates to the pinned versions |

## Getting started

1. Install [Nix](https://nixos.org/download) and enable flakes. Optionally, install [direnv](https://direnv.net) with [nix-direnv](https://github.com/nix-community/nix-direnv) to enter the dev shell on `cd`.
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
├── docs/adr/         The decisions: foundations, doc conventions, toolchain
├── .golangci.yml     The linter and formatter set
├── flake.nix         The dev shell, the app package, the git hooks, and the checks
├── flake.lock        The pinned nixpkgs and inputs
├── justfile          Tasks
└── .envrc            Enters the dev shell through direnv
```

## Configuration

| Variable | Description | Default |
| --- | --- | --- |
| `LOG_LEVEL` | One of `DEBUG`, `INFO`, `WARN`, or `ERROR` | `INFO` |

## Using this template

1. Create a repository from this template on GitHub.
2. Change the module path in `go.mod` and in the imports to your own.
3. Replace `internal/foo` with your own packages.
4. Update the contacts in `SECURITY.md` and the copyright line in `LICENSE`.
5. Install the [Renovate app](https://github.com/apps/renovate) on the new repository.

## Decisions

The ADRs in [docs/adr](docs/adr/README.md) record every decision and the reason for it. [ADR-0001](docs/adr/0001-documentation-conventions.md) is the house style for all text.

## Contributing

Follow the [Code of Conduct](CODE_OF_CONDUCT.md). Commit messages follow [Conventional Commits](https://www.conventionalcommits.org), and the `commit-msg` hook checks them. Run `just check` before you open a pull request.

## Security

To report a vulnerability, follow [SECURITY.md](SECURITY.md).

## License

Apache License 2.0. See [LICENSE](LICENSE).
