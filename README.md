# Go Template

A template for a Go application. It follows the [Standard Go Project Layout](https://github.com/golang-standards/project-layout), lints with every `golangci-lint` linter enabled, and builds a static binary. It starts from [github-project-template](https://github.com/tabmadi/github-project-template), so it has the same hooks, CI gate, and documentation convention.

## Stack

| Tool | Owns |
| --- | --- |
| [Go](https://go.dev) | Build, run, and test |
| [golangci-lint](https://golangci-lint.run) | Lint and format |
| [mise](https://mise.jdx.dev) | Tool versions and tasks |
| [lefthook](https://github.com/evilmartians/lefthook) | Git hooks |
| [cocogitto](https://docs.cocogitto.io) | Conventional Commits checks |
| [rumdl](https://github.com/rvben/rumdl) | Markdown lint |
| [gitleaks](https://github.com/gitleaks/gitleaks) | Secret scan |
| [Renovate](https://docs.renovatebot.com) | Updates to the pinned versions |

## Getting started

1. Install [mise](https://mise.jdx.dev/getting-started.html).
2. Clone the repo and install the tools, modules, and hooks:

   ```bash
   git clone git@github.com:tabmadi/go-template.git
   cd go-template
   mise install
   mise run setup
   ```

3. Run the app:

   ```bash
   mise run run
   ```

## Tasks

| Task | Does |
| --- | --- |
| `mise run setup` | Downloads the modules and installs the git hooks |
| `mise run run` | Runs the app from source |
| `mise run build` | Builds a static, stripped binary at `bin/app` |
| `mise run start` | Builds and runs the binary |
| `mise run format` | Applies every formatter and every safe lint fix |
| `mise run lint` | Runs `lint:go`, `lint:md`, and `lint:secrets` |
| `mise run test` | Runs the tests |
| `mise run check` | Runs `lint` and `test`. Run it before you finish a change |
| `mise run ci` | Runs `check` and `build`, exactly as CI does. The `pre-push` hook runs it too |

## Layout

```text
.
├── cmd/app/          The entry point. It wires the parts together
├── internal/
│   ├── config/       Configuration from defaults and environment variables
│   └── foo/          Sample package with structured logging
├── docs/adr/         The decisions: foundations, doc conventions, toolchain
├── .golangci.yml     The linter and formatter set
├── .mise.toml        Tool pins and tasks
└── .lefthook.yml     Git hooks
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

Follow the [Code of Conduct](CODE_OF_CONDUCT.md). Commit messages follow [Conventional Commits](https://www.conventionalcommits.org), and the `commit-msg` hook checks them. Run `mise run check` before you open a pull request.

## Security

To report a vulnerability, follow [SECURITY.md](SECURITY.md).

## License

Apache License 2.0. See [LICENSE](LICENSE).
