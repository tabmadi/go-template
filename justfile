# Every task, per ADR-0100. A recipe that calls a tool runs only inside the dev shell of flake.nix.

set shell := ["bash", "-euo", "pipefail", "-c"]

import? 'template/justfile'

# List the recipes
default:
    @just --list

# Build the dev shell, download the modules, and install the git hooks
setup:
    nix develop --command go mod download

# Run the app from source
run: in-shell
    go run ./cmd/app

# Build a static, stripped binary at bin/app
build: in-shell
    CGO_ENABLED=0 go build -ldflags="-s -w" -trimpath -o bin/app ./cmd/app

# Build and run the binary
start: build
    ./bin/app

# Delete the build output
clean:
    rm -rf bin result

# Run the tests
test: in-shell
    go test ./...

# golangci-lint with every linter that .golangci.yml enables
lint-go: in-shell
    golangci-lint run --allow-parallel-runners

# Markdown structure and formatting, per ADR-0001
lint-md: in-shell
    rumdl check .

# Scan the working tree for committed secrets
lint-secrets: in-shell
    gitleaks dir . --no-banner

# Run every linter
lint: lint-go lint-md lint-secrets

# Apply every formatter and every safe lint fix
format: in-shell
    golangci-lint run --fix --allow-parallel-runners
    rumdl check --fix .
    nix fmt flake.nix

# The fast gate: run it before you finish a change
check: lint test

# Run exactly what CI runs: every check of flake.nix, in the Nix sandbox
ci:
    nix flake check --print-build-logs

[private]
in-shell:
    @test -n "${IN_NIX_SHELL:-}" || { echo "Enter the dev shell first: run nix develop, or allow direnv." >&2; exit 1; }
