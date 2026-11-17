# TPL-0000: Template contract

- **Status:** Accepted
- **Decides:** Which files are the template and which are the project, how a project is made, and what this template may hold.

## Context

This repo is a template for a Go application. A project made from it copies its files, and the copies do not link back. So every sentence in a copied file must stay true in the project. A sentence that names the template, its siblings, or the repo it came from turns false the moment it is copied.

This repo starts from [github-project-template](https://github.com/tabmadi/github-project-template) and adds the Go toolchain. The [blueprints](https://github.com/tabmadi/blueprints) repo keeps the templates of the same size in step.

## Decision

### Two scopes

| Scope | Holds | In a project made from this repo |
| --- | --- | --- |
| Project | Every file outside `template/`. The ADRs in `docs/adr/` are written in the voice of the project | Copied |
| Template | The `template/` folder: this ADR, the template's agent hints, and its own checks and outputs | Not copied |

A template file may name a project file. A project file never links into `template/`, because the link breaks in every copy. Only a template file names another repo.

`flake.nix` loads `template/scope.nix` when the file exists. It adds the template checks and the `templates` output. In a project, the folder is absent, so the template scope adds nothing.

### Making a project

`nix flake new -t github:tabmadi/go-template <dir>` copies the project scope. The `templates` output filters out `template/`, and its welcome text lists the first steps of the new project. The first step renames the module path in `go.mod` and in the imports.

GitHub's template button copies every file, `template/` included. In that copy, `just init` prints the same first steps and removes `template/` with git. The first commit of the project then holds no template scope.

### What this template holds

The sample code shows the structure. It is not a feature set, and a project replaces `internal/foo` with its own packages.

A dependency added here is a dependency of every project made from it. So the template adds one only when the template itself needs it.

A template of this size has three project ADRs: [ADR-0000](../../docs/adr/0000-foundations.md), [ADR-0001](../../docs/adr/0001-documentation-conventions.md), and [ADR-0100](../../docs/adr/0100-toolchain.md). A change to a shared one starts in github-project-template and goes to every template of the same size in one pass.

## Consequences

The root `README.md` describes the template, not a project. A new project rewrites it, and the welcome text says so.

The project ADRs avoid the words of this ADR. The `lint-scope` check fails when a project doc names another repo, speaks as the template, or links into `template/`.

## Rules

- Every file that a project must not inherit lives in `template/`.
- A file outside `template/` never links into it. `(CI: lint-scope)`
- A project doc never names another repo or speaks as the template. `(CI: lint-scope)`
- Only a file in `template/` names another repo.
- The template adds a module dependency only when the template itself needs it.
- A change to a shared project ADR goes to every template of the same size in one pass.
