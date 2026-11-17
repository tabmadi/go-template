# ADR-0000: Foundations

**Status:** Accepted
**Decides:** What this repo is, its layout, its Go conventions, and the ADR process itself.

## Context

A Go project starts with the same choices every time: the layout, the linter set, how configuration is read, and how errors and logs look. A template makes these choices once, so a new project starts at its first feature.

## Decision

This repo is a Go application template. It starts from [github-project-template](https://github.com/tabmadi/github-project-template) and adds the Go toolchain. The sample code shows the structure. It is not a feature set.

The layout follows the [Standard Go Project Layout](https://github.com/golang-standards/project-layout):

| Path | Holds |
| --- | --- |
| `cmd/app/` | The entry point. It wires the parts and holds no business logic |
| `internal/` | All other code. No other module can import it |
| `internal/config/` | The configuration: defaults in code, overridden by environment variables |

**Configuration is read in one place.** `internal/config` reads the environment. No other package calls `os.Getenv`.

**The style baseline is published.** [Effective Go](https://go.dev/doc/effective_go) and the [Go Code Review Comments](https://go.dev/wiki/CodeReviewComments) apply. `golangci-lint` enforces them, per [ADR-0100](0100-toolchain.md).

**Every decision is an ADR.** An ADR states what is true of the repo. It is law, not a plan. Planned work lives in an untracked `*.local.md` file.

## Consequences

A dependency added here is a dependency of every generated project. So the template adds one only when the template itself needs it.

A generated project inherits these ADRs. So an ADR is written for the engineer who maintains the project. Selection guidance belongs in the root `README.md`.

## Rules

- `cmd/` holds entry points only. Business logic lives in `internal/`.
- Only `internal/config` reads environment variables.
- An error is wrapped with context, as `fmt.Errorf("...: %w", err)`, and is never discarded.
- Logs use `log/slog` with a context. No global logger. `(CI: lint-go)`
- Tests are table-driven and live next to the code, as `*_test.go`.
- A `//nolint` names one linter and gives a reason. `(CI: lint-go)`
- Every ADR carries a `Status`, a one-sentence `Decides` line, and a flat `Rules` section.
- Planned work lives in an untracked `*.local.md` file. No committed file links to one.
