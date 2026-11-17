# ADR-0000: Foundations

- **Status:** Accepted
- **Decides:** What this repo is, its layout, its Go conventions, the recipe contract, and how ADRs work.

## Context

A Go project makes the same choices every time: the layout, the linter set, how configuration is read, and how errors and logs look. This repo writes them down once, so each change starts at the feature.

A repo without written decisions loses the reason for each choice. The next engineer removes a check that has a reason, or adds a second tool for a job that one tool already does.

A repo also needs fixed entry points. An engineer or a coding agent that knows the name of the gate runs it without reading every file first.

## Decision

This repo is a Go application. It builds one static binary from `cmd/app`. The layout follows the [Standard Go Project Layout](https://github.com/golang-standards/project-layout).

| Path | Holds |
| --- | --- |
| `cmd/app/` | The entry point. It wires the parts and holds no business logic |
| `internal/` | All other code. No other module can import it |
| `internal/config/` | The configuration: defaults in code, overridden by environment variables |

**Configuration is read in one place.** Only `internal/config` reads the environment.

**The style baseline is published.** [Effective Go](https://go.dev/doc/effective_go) and the [Go Code Review Comments](https://go.dev/wiki/CodeReviewComments) apply, and `golangci-lint` enforces them, per [ADR-0100](0100-toolchain.md).

**The recipe names are a contract.** The recipes `setup`, `format`, `lint`, `test`, `check`, and `ci` always exist, per [ADR-0100](0100-toolchain.md). Their names do not change.

**Every decision is an ADR.** An ADR states a rule as true now. A gap between an ADR and the code is a defect in the code.

**An ADR has a fixed shape.** It has a `Status`, a one-sentence `Decides` line, and the sections `Context`, `Decision`, `Consequences`, and `Rules`. The `Rules` section is a flat list, so a grep over all ADRs finds every convention.

**Inside this repo, an ADR links only to other ADRs.** A README or a guide moves, and the ADR outlives it. A link to a published standard is allowed.

## Consequences

An ADR is for the engineer who maintains the repo. The root `README.md` helps a reader choose the repo and start.

## Rules

- `cmd/` holds entry points only. Business logic lives in `internal/`.
- Only `internal/config` reads environment variables.
- An error is wrapped with context, as `fmt.Errorf("...: %w", err)`, and is never discarded.
- Logs use `log/slog` with a context. No global logger. `(CI: lint-go)`
- Tests are table-driven and live next to the code, as `*_test.go`.
- A `//nolint` names one linter and gives a reason. `(CI: lint-go)`
- Every ADR has a `Status`, a one-sentence `Decides` line, and a flat `Rules` section.
- Inside this repo, an ADR links only to other ADRs.
- The recipes `setup`, `format`, `lint`, `test`, `check`, and `ci` exist, and their names do not change.
