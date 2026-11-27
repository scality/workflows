# Dependency merge

The `dependency-merge.yaml` workflow merges a Renovate PR once the Claude dependency
review approved it and the CI is green. The repository keeps its code owner rule for
everything else.

## How it works

1. Renovate opens the PR. Its preset labels it `automerge` when an update in it may be
   merged without a human, and `no-automerge` when one may not. A PR with both is not
   merged (see `automerge.json5` in `scality/platform-renovate`).
2. `claude-code-dependency-review.yml` reviews the bump. When it is safe, it approves the
   PR as `github-actions[bot]`. Otherwise it comments, and the PR waits for a human. Its
   `approved` output is true only when the execution log of Claude shows the approval.
3. Right after the review, this workflow sets the `dependency-review/approved` commit
   status on the head commit with the App, when `approved` is true. Any workflow of the
   repository can approve as `github-actions[bot]`, but only the App can set this status.
4. It merges the PR with the App when all of these hold:
    - Renovate opened the PR against the default branch, and labelled it `automerge` and
      not `no-automerge` on its last run. The workflow reads these labels from the
      `renovate-debug` block of the PR body: Renovate stops syncing the labels of a PR once
      someone edits them;
    - nobody added `no-automerge` to the PR. This is how to stop a merge by hand;
    - every commit was made by Renovate (author `scality-renovate[bot]`, signed by GitHub
      as `web-flow`);
    - no `go` or `toolchain` line of a `go.mod` changes: `go mod tidy` raises it when a
      new version of a dependency needs a newer Go, and a Go bump stays a human merge;
    - the App set `dependency-review/approved` on the head commit.

    It also adds the `automerged` label, to find these PRs before a product release.

It runs twice: at the end of the review, and at the end of the CI, since either can
finish last. GitHub refuses the merge while a required check runs or an approval is
missing, so the first call usually ends with a notice and the second merges. `Pre Merge`
must therefore depend on every required check. Any other refusal, such as a merge
method the repository does not allow, or a code owner review asked because the App is
not a bypass actor, fails the job.

The App merges with a direct API call, not with auto-merge: GitHub auto-merge does not
apply the bypass of a ruleset.

A PR with any other commit, a human fix or a regeneration pushed by `go-generated.yaml`,
is never merged here: a code owner reviews and merges it.

Known limits:

- Anyone with write access can create a commit through the API with Renovate as
  author. GitHub signs it as `web-flow`, like a Renovate commit. Such a commit still
  needs the approval of the dependency review to be merged.
- Renovate rewrites the `renovate-debug` block only when it updates the PR. If its
  config changes while a PR is open and nothing else in the PR changes, the block can
  keep `automerge` for an update that is no longer eligible. Add `no-automerge` to the
  open PRs after such a change.

## Repository setup

- A GitHub App with `contents`, `pull_requests`, `statuses` and `workflows` write
  permissions, installed on the repository. `workflows` is needed to merge a GitHub
  Actions bump, which changes `.github/workflows/`.
- An environment named `dependency-merge`, restricted to the default branch, with the
  App ID as the `DEPENDENCY_MERGE_APP_ID` variable and the App private key as the
  `MERGE_APP_PRIVATE_KEY` secret. A workflow changed in a PR
  does not run on the default branch, so it cannot read the key.
- Two rulesets on the default branch:

    | Ruleset | Rules | Bypass |
    |---|---|---|
    | Code owners | Pull request, review from code owners required | the App |
    | Approval and CI | Pull request with 1 approval, dismiss stale approvals, approval of the most recent push; required check `Pre Merge` | none |

    A bypass covers its whole ruleset, so the App only skips the code owner rule.

- "Allow GitHub Actions to create and approve pull requests", so the review can approve.

## Usage

In the workflow that already calls the dependency review:

```yaml
name: Code Review

on:
  pull_request_target:
    types: [opened, synchronize]
  workflow_run:
    workflows: [Pre Merge]
    types: [completed]

jobs:
  review-dependency-bump:
    if: >-
      github.event_name == 'pull_request_target'
      && github.event.pull_request.user.login == 'scality-renovate[bot]'
    uses: scality/workflows/.github/workflows/claude-code-dependency-review.yml@v2
    with:
      ACTIONS_APP_ID: ${{ vars.ACTIONS_APP_ID }}
    secrets: inherit

  merge-dependency-bump:
    needs: review-dependency-bump
    # needs is skipped on workflow_run: !cancelled() lets this job run anyway.
    if: >-
      !cancelled() && (
        (github.event_name == 'pull_request_target'
         && github.event.pull_request.base.ref == github.event.repository.default_branch
         && needs.review-dependency-bump.result == 'success')
        || (github.event_name == 'workflow_run'
         && github.event.workflow_run.conclusion == 'success'
         && github.event.workflow_run.event == 'pull_request'
         && startsWith(github.event.workflow_run.head_branch, 'renovate/')
         && github.event.workflow_run.pull_requests[0] != null))
    uses: scality/workflows/.github/workflows/dependency-merge.yaml@v2
    with:
      pr-number: ${{ github.event.pull_request.number || github.event.workflow_run.pull_requests[0].number }}
      review-approved: ${{ needs.review-dependency-bump.outputs.approved == 'true' }}
```

`pull_request_target` and `workflow_run` always run the workflow of the default branch:
a PR cannot change this logic.

## Inputs

| Input | Default | Description |
|---|---|---|
| `pr-number` | | Renovate PR to merge |
| `review-approved` | `false` | The `approved` output of the dependency review, on the call that follows it |
| `merge-app-id` | `DEPENDENCY_MERGE_APP_ID` of the environment | ID of the App that merges |
| `environment` | `dependency-merge` | Environment that holds `MERGE_APP_PRIVATE_KEY` |
| `merge-method` | `merge` | `merge`, `squash` or `rebase` |
