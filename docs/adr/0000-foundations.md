# ADR-0000: Foundations

- **Status:** Accepted
- **Decides:** What this repo is, its layout, its Go conventions, the recipe contract, and the ADR process itself.

## Context

A Go project makes the same choices every time: the layout, the linter set, how configuration is read, and how errors and logs look. A repo that writes them down once lets each change start at the feature, not at the choice.

A repo without written decisions loses the reason for each choice. The next engineer then removes a check that exists for a reason, or adds a second tool for a job that one tool already does.

## Decision

This repo is a Go application. It builds one static binary from `cmd/app`.

The layout follows the [Standard Go Project Layout](https://github.com/golang-standards/project-layout):

| Path | Holds |
| --- | --- |
| `cmd/app/` | The entry point. It wires the parts and holds no business logic |
| `internal/` | All other code. No other module can import it |
| `internal/config/` | The configuration: defaults in code, overridden by environment variables |

**Configuration is read in one place.** `internal/config` reads the environment. No other package calls `os.Getenv`.

**The style baseline is published.** [Effective Go](https://go.dev/doc/effective_go) and the [Go Code Review Comments](https://go.dev/wiki/CodeReviewComments) apply. `golangci-lint` enforces them, per [ADR-0100](0100-toolchain.md).

**The recipe names are a contract.** `setup`, `format`, `lint`, `test`, `check`, and `ci` exist in this repo, per [ADR-0100](0100-toolchain.md). Their names do not change.

**Every decision is an ADR.** An ADR states what is true of the repo. It is law, not a plan. Planned work lives in an untracked `*.local.md` file.

## Consequences

An ADR is written for the engineer who maintains the repo. Selection guidance belongs in the root `README.md`.

An ADR names other ADRs only. A link to a README, a guide, or another repo breaks when that file moves, and the ADR outlives it.

## Rules

- `cmd/` holds entry points only. Business logic lives in `internal/`.
- Only `internal/config` reads environment variables.
- An error is wrapped with context, as `fmt.Errorf("...: %w", err)`, and is never discarded.
- Logs use `log/slog` with a context. No global logger. `(CI: lint-go)`
- Tests are table-driven and live next to the code, as `*_test.go`.
- A `//nolint` names one linter and gives a reason. `(CI: lint-go)`
- The recipes `setup`, `format`, `lint`, `test`, `check`, and `ci` exist in this repo.
- Every ADR carries a `Status`, a one-sentence `Decides` line, and a flat `Rules` section.
- An ADR links to other ADRs only.
- Planned work lives in an untracked `*.local.md` file. No committed file links to one.
