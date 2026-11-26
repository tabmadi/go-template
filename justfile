# Every task, per ADR-0103. A recipe that calls a tool runs only inside the dev shell of flake.nix.

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

# golangci-lint with every linter that .config/golangci.yml enables
lint-go: in-shell
    golangci-lint run --config .config/golangci.yml --allow-parallel-runners

# Prose, comments, and ADRs, per ADR-0001
lint-prose: in-shell
    tabkit check

# Markdown structure and formatting, per ADR-0001
lint-md: in-shell
    rumdl check .

# Scan the working tree for committed secrets
lint-secrets: in-shell
    gitleaks dir . --no-banner

# JSON, JSONC, TOML, and YAML format, per ADR-0104
lint-data: in-shell
    dprint check

# Nix format, per ADR-0104
lint-nix: in-shell
    nixfmt --check $(git ls-files '*.nix')

# justfile format, per ADR-0104
lint-just:
    just --fmt --check

# Run every linter
lint: lint-go lint-prose lint-md lint-secrets lint-data lint-nix lint-just

# Apply every formatter and every safe lint fix
format: in-shell
    golangci-lint run --config .config/golangci.yml --fix --allow-parallel-runners
    rumdl check --fix .
    nixfmt $(git ls-files '*.nix')
    dprint fmt
    just --fmt

# The fast gate: run it before you finish a change
check: lint test

# Run exactly what CI runs: every check of flake.nix, in the Nix sandbox
ci:
    nix flake check --print-build-logs

# Push what CI built to the binary cache, per ADR-0101. Without NIX_CACHE_URL it does nothing
cache-push: in-shell
    nix-cache-push

# Make the labels of the forge match .github/labels.yml, per ADR-0101. It deletes every other label
labels: in-shell
    tabkit-labels --prune

# Run Renovate over this repository, per ADR-0102. The renovate workflow calls it
ci-renovate: in-shell
    nix run --inputs-from . nixpkgs#renovate

# Write the files that follow a dependency change, per ADR-0102. A fake hash makes Nix print the real one
deps-sync: in-shell
    #!/usr/bin/env bash
    set -euo pipefail
    fake="sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
    current="$(sed -nE 's/.*vendorHash = "(sha256-[^"]+)".*/\1/p' flake.nix)"
    sed -i "s|${current}|${fake}|" flake.nix
    log="$(nix build .#default.goModules --no-link 2>&1 || true)"
    got="$(sed -nE 's/.*got: +(sha256-[A-Za-z0-9+/=]+).*/\1/p' <<<"$log" | head -1)"
    sed -i "s|${fake}|${got:-$current}|" flake.nix
    test -n "$got"

[private]
in-shell:
    @test -n "${IN_NIX_SHELL:-}" || { echo "Enter the dev shell first: run nix develop, or allow direnv." >&2; exit 1; }
