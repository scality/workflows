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

## Renovate branches

When Renovate bumps a code generator (oapi-codegen, mockery, controller-tools), its PR
changes `go.mod` but not the generated code, so this check fails until someone runs the
commands and pushes on the Renovate branch. Renovate then stops updating that branch.

With `push-to-renovate-branches`, the workflow pushes the regenerated code itself on a
`renovate/*` branch of the repository. The check still fails on the Renovate commit, and
the pushed commit starts a new run that passes.

```yaml
jobs:
  go-generated:
    uses: scality/workflows/.github/workflows/go-generated.yaml@v2
    secrets:
      ACTIONS_APP_PRIVATE_KEY: ${{ secrets.ACTIONS_APP_PRIVATE_KEY }}
    with:
      push-to-renovate-branches: true
      actions-app-id: ${{ vars.ACTIONS_APP_ID }}
```

Pass the secrets one by one, not with `secrets: inherit`: the commands can read
`GIT_ACCESS_TOKEN`, so only pass it when the repository needs private modules, and only
with a read-only token.

How it stays safe:

- The commands run with a read-only token. A second job, which never runs the code of
  the repository (git hooks are disabled), applies the result and pushes it.
- The push uses a GitHub App token limited to the repository, because a push made with
  `GITHUB_TOKEN` starts no workflow, so the required checks would never run.
- It only runs on a `renovate/*` branch of the repository, never on a fork.
- The pushed commit only holds changes under `working-directory`, never under `.github/`.
  When the commands change files outside `working-directory`, nothing is pushed. The push
  job checks this again, since the first job ran the generators.
  With one call per module, each run pushes one module: the first push moves the branch,
  the other calls push nothing, and the next run regenerates the remaining modules.
- It does not loop: when files the App already regenerated on the branch still differ,
  the job fails instead of pushing again.
- The push job runs on a fresh GitHub-hosted runner, whatever `runs-on` says: it holds a
  write token, and must not share a machine with the job that ran the generators.
- It does not force-push. If Renovate moved the branch meanwhile, it pushes nothing: the
  new commit starts its own run, which regenerates again.

Limits:

- On a Renovate branch, the commands run on the branch head, not on its merge with the
  base branch. A base change that needs regeneration is caught on the next PR.
- The pushed code is what the generators wrote. A compromised generator could add code
  there, so keep these PRs under human review: do not automerge a PR that holds a
  regeneration commit.

The inputs are checked on every PR: a missing App ID or key fails the run when a push
is due, and only warns otherwise, so PRs that get no Actions secrets (Dependabot, forks)
stay green.

The commit author is the GitHub App. Add its email, printed in the run summary, to
`gitIgnoredAuthors` in the Renovate config: otherwise Renovate sees a foreign commit and
stops updating the branch.

Code generators run through `go generate` are best declared as `tool` in `go.mod`
(`go get -tool github.com/vektra/mockery/v3`): their version is then pinned and
updated like any other dependency.

## Inputs

| Name                | Description                          | Default                              |
| ------------------- | ------------------------------------ | ------------------------------------ |
| `commands`          | Commands that regenerate the code    | `go mod tidy` and `go generate ./...` |
| `working-directory` | Directory that holds the `go.mod`    | `.`                                  |
| `runs-on`           | Runner label                         | `ubuntu-24.04`                       |
| `push-to-renovate-branches` | Push the regenerated code on a `renovate/*` branch | `false` |
| `actions-app-id`    | GitHub App ID used for that push (usually `vars.ACTIONS_APP_ID`) | `''` |

## Secrets

| Name               | Description                                                        |
| ------------------ | ------------------------------------------------------------------ |
| `GIT_ACCESS_TOKEN` | Optional, to fetch private `github.com/scality` modules. The commands can read it: use a read-only token |
| `ACTIONS_APP_PRIVATE_KEY` | Private key of the GitHub App, required with `push-to-renovate-branches` |
