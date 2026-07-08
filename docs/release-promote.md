# Release & Promote

`release.yaml` and `promote.yaml` are a pair of workflows automating the
release flow of a repository:

1. **Release**: triggered manually (`workflow_dispatch` in the caller).
   Computes the next semantic version off the last GA tag reachable from the
   current branch, then creates and pushes an annotated `v*` tag using the
   GitHub App token.
2. **Promote**: triggered by the `v*` tag push in the caller. Creates a
   GitHub Release with generated notes, marked as pre-release when the tag
   contains a hyphen (e.g. `v1.2.3-alpha.1`). The release title is the tag
   itself (e.g. `v1.2.3`): the repository already provides context in the
   GitHub UI; set `product-name` to prefix it (e.g. `MetalK8s v1.2.3`).

Flow: click *Release* → tag is pushed → *Promote* fires → GitHub Release
published.

!!! note
    The tag must be pushed with a GitHub App token: tags pushed with the
    default `GITHUB_TOKEN` do not trigger `on: push: tags` workflows, so
    Promote would never fire. This is why `release.yaml` requires
    `actions-app-id` and the `ACTIONS_APP_PRIVATE_KEY` secret.

## Usage

### Release

```yaml
# release.yaml (caller)
name: Release
run-name: Release new ${{ inputs.version-type }} from ${{ github.ref_name }}

on:
  workflow_dispatch:
    inputs:
      version-type:
        description: "Version type"
        required: true
        type: choice
        default: "alpha"
        options: ["alpha", "beta", "GA"]
      version-scope:
        description: "Version scope"
        required: true
        type: choice
        default: "patch"
        options: ["patch", "minor", "major"]

jobs:
  # Optional but recommended for libraries: releases are cut from `main`
  # without re-running pre-merge, and for a Go library the tag *is* the
  # artifact: this is the only verification point.
  quality-gate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7
      - uses: actions/setup-go@v6
        with:
          go-version-file: go.mod
      - run: go test -v ./...

  release:
    needs: quality-gate
    uses: scality/workflows/.github/workflows/release.yaml@v2
    with:
      version-type: ${{ inputs.version-type }}
      version-scope: ${{ inputs.version-scope }}
      actions-app-id: ${{ vars.ACTIONS_APP_ID }}
    secrets: inherit
```

`workflow_call` does not support `type: choice`, so the choice inputs live in
the caller's `workflow_dispatch` and are relayed as strings; the reusable
workflow validates them.

### Promote

```yaml
# promote.yaml (caller)
name: Promote
run-name: "Promote ${{ github.ref_name }}"

on:
  push:
    tags:
      - "v*"

jobs:
  create-release:
    uses: scality/workflows/.github/workflows/promote.yaml@v2
    permissions:
      contents: write
```

For a **deployable service**, chain the image build before the release
creation so a broken build blocks the GitHub Release:

```yaml
jobs:
  build:
    uses: ./.github/workflows/build.yaml
    secrets: inherit
    with:
      is-development: false
      is-latest: true
      is-stable: ${{ ! contains(github.ref_name, '-') }}

  create-release:
    needs: build
    uses: scality/workflows/.github/workflows/promote.yaml@v2
    permissions:
      contents: write
```

For a **pure library** (consumed via `go get ...@vX.Y.Z`), the tag is the
artifact: no build job is needed.

## Release inputs

| Input | Required | Default | Description |
|---|---|---|---|
| `version-type` | yes | n/a | `alpha`, `beta` or `GA` |
| `version-scope` | yes | n/a | `patch`, `minor` or `major` |
| `product-name` | no | _(empty)_ | Optional; prefixed to the tag annotation message when set |
| `allowed-branch` | no | `main` | Only ref allowed to cut releases |
| `actions-app-id` | unless `dry-run` | n/a | GitHub App ID used to push the tag |
| `dry-run` | no | `false` | Compute and validate the tag without pushing |

Secrets: `ACTIONS_APP_PRIVATE_KEY` (required unless `dry-run`).

Outputs: `tag`, the computed release tag (e.g. `v1.2.3-alpha.1`).

## Promote inputs

| Input | Required | Default | Description |
|---|---|---|---|
| `product-name` | no | _(empty)_ | Optional; prefixes the release title (e.g. `MetalK8s v1.2.3`) when set. Empty ⇒ the title is the tag alone (`v1.2.3`). Use it for monorepos or when the product name differs from the repo name. |

The calling job must grant `permissions: contents: write`: a called workflow
can only downgrade the caller's token permissions, never elevate them.

To prefix the title, pass `product-name` from the caller:

```yaml
  create-release:
    uses: scality/workflows/.github/workflows/promote.yaml@v2
    permissions:
      contents: write
    with:
      product-name: MetalK8s   # ⇒ "MetalK8s v1.2.3" (omit for "v1.2.3")
```

## Version computation

- The base version is the highest GA tag (`v*` without hyphen) **reachable
  from the current branch** (`git tag --merged HEAD --sort=version:refname`),
  so a hotfix tagged out of order on another release line is never picked as
  the base, and the computation stays correct if per-minor release branches
  (e.g. `dev/1.0`) are introduced later.
- `alpha`/`beta` types append or increment a pre-release suffix
  (`v1.2.3-alpha.1`, `v1.2.3-alpha.2`, ...); `GA` produces a bare `vX.Y.Z`.
- With no GA tag in history (first release), the base falls back to `0.0.0`.
