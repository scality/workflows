# Go generated files

The `go-generated.yaml` workflow runs the commands that regenerate the code of a Go
repository, and fails when the result differs from what is committed. It catches a
stale `go.sum`, mocks or CRDs that were not regenerated, and new generated files
that were not committed.

## Usage

```yaml
# my-workflow.yaml
on: pull_request

jobs:
  go-generated:
    uses: scality/workflows/.github/workflows/go-generated.yaml@v2
    secrets: inherit
```

By default it runs `go mod tidy` then `go generate ./...`. A Kubebuilder project
also regenerates its manifests:

```yaml
jobs:
  go-generated:
    uses: scality/workflows/.github/workflows/go-generated.yaml@v2
    secrets: inherit
    with:
      commands: |
        go mod tidy
        go generate ./...
        make manifests generate
```

Code generators run through `go generate` are best declared as `tool` in `go.mod`
(`go get -tool github.com/vektra/mockery/v3`): their version is then pinned and
updated like any other dependency.

## Inputs

| Name                | Description                          | Default                              |
| ------------------- | ------------------------------------ | ------------------------------------ |
| `commands`          | Commands that regenerate the code    | `go mod tidy` and `go generate ./...` |
| `working-directory` | Directory that holds the `go.mod`    | `.`                                  |
| `runs-on`           | Runner label                         | `ubuntu-24.04`                       |

## Secrets

| Name               | Description                                                        |
| ------------------ | ------------------------------------------------------------------ |
| `GIT_ACCESS_TOKEN` | Optional, to fetch private `github.com/scality` modules            |
