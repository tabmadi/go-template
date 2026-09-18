# Agent guide

Tool-agnostic guide for any coding agent (Codex, Cursor, Claude Code, or another) working in this repo. `AGENTS.md` is the one standard: an agent either reads it or it does not — the repo carries no per-tool shim files (`CLAUDE.md`, `.cursor/rules/`, etc.). A tool that ignores `AGENTS.md` is a limitation of that tool, not something the repo works around.

## The one rule that outranks this file

**Humans are the first developers. [README.md](README.md) outranks this file.** It is the human-facing description of what this template provides and how to use it. This file holds only agent-specific operational hints: how to navigate, build, and run the repo.

## What this repo is

A Go application template following the [Standard Go Project Layout](https://github.com/golang-standards/project-layout). The sample code is a demonstration seam, not a feature set.

- **Everything here is inherited wholesale** by every project generated from it. A dependency added here is a dependency every generated project carries, so add one only when the template itself needs it.
- `cmd/app/` holds the entry point, `internal/` the code no other module may import. Business logic goes in `internal/`, never in `cmd/`.
- `internal/config` is the pattern for configuration: defaults in code, overridden by environment variables. Extend it rather than reading `os.Getenv` from scattered call sites.
- The module path in `go.mod` is a placeholder carrying a `TODO`. A generated project rewrites it; this repo does not.

## Working in the repo

- The task runner is `mise` (root `mise.toml`); commands are `mise run <task>`. `mise run setup` downloads modules and installs the git hooks.
- Tools are pinned and installed by `mise`; a shell with mise inactive resolves a bare tool call (`go`, `golangci-lint`, `cog`, …) from `PATH`, at an unpinned version. `mise run <task>` activates the toolchain for that task's duration, a bare tool call does not.
- `mise run run` runs from source; `mise run build` produces a stripped static binary at `bin/app` and `mise run start` runs it. Build flags live in the `build` task, not in a Makefile or a shell script.
- `mise run act` replays the pull request workflow locally with [act](https://github.com/nektos/act). It reads secrets from `.env` — copy `.env.example` first.
- Before finishing a change, run `mise run check` to format, lint, and test; `mise run format` / `lint` / `test` run each individually.

## Conventions

- **[Effective Go](https://go.dev/doc/effective_go) and the [Go Code Review Comments](https://go.dev/wiki/CodeReviewComments) are the style baseline.** Idiomatic Go beats clever Go.
- **`golangci-lint` is the arbiter**, configured in [.golangci.yml](.golangci.yml). `mise run format` auto-fixes what it can. Never silence a linter with a blanket `//nolint`: fix the code, or annotate the single line with the specific linter and a reason.
- Every exported identifier carries a doc comment starting with its name. Every package has a package comment.
- Errors are wrapped with context (`fmt.Errorf("...: %w", err)`) and never discarded silently.
- Tests are table-driven and live next to the code they test, as `*_test.go`.

## Commits

- **Conventional Commits, enforced.** `cog verify` runs on `commit-msg` and `cog check` on `pre-push`, so a malformed message is rejected locally before CI sees it.
- Commit messages are a title only — no body, no footer.
- Never push unless asked to.
